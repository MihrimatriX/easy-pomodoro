import { useEffect, useMemo, useState, type ReactNode } from "react";
import {
  Alert,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  useColorScheme,
  View,
} from "react-native";
import { NavigationContainer, DarkTheme, DefaultTheme } from "@react-navigation/native";
import { createBottomTabNavigator } from "@react-navigation/bottom-tabs";
import { SafeAreaProvider } from "react-native-safe-area-context";
import { StatusBar } from "expo-status-bar";
import { activateKeepAwakeAsync, deactivateKeepAwake } from "expo-keep-awake";
import { formatTime } from "@shared/pomodoro";
import { getTodayHabitProgress, isHabitDoneToday } from "@shared/habits";
import { getThemePalette } from "@shared/themes";
import { phaseLabel, translate } from "@shared/i18n/messages";
import { getUiSurface, resolveMode } from "@shared/ui-surfaces";
import type { LocaleId, Settings } from "@shared/types";
import { useHabits, usePomodoro, useSettings, useStats, useTasks } from "./src/hooks";

const Tab = createBottomTabNavigator();

function useColors(settings: Settings) {
  const scheme = useColorScheme();
  const palette = getThemePalette(settings);
  const mode = resolveMode(settings.theme, scheme === "dark");
  const surface = getUiSurface(settings.uiStyle, mode, palette.accent);
  return {
    bg: surface.background,
    fg: surface.foreground,
    muted: surface.muted,
    accent: palette.accent,
    card: surface.surface,
    dark: mode === "dark",
  };
}

export default function App() {
  const { settings, setSettings } = useSettings();
  const tasks = useTasks();
  const habits = useHabits();
  const { stats, logSession } = useStats();
  const pomodoro = usePomodoro(settings, (phase, sec) =>
    logSession(phase, sec, tasks.activeTaskId ?? undefined),
  );
  const colors = useColors(settings);
  const t = (key: Parameters<typeof translate>[1], params?: Record<string, string | number>) =>
    translate(settings.locale, key, params);

  useEffect(() => {
    if (pomodoro.status !== "running") {
      void deactivateKeepAwake();
      return;
    }
    void activateKeepAwakeAsync();
    return () => {
      void deactivateKeepAwake();
    };
  }, [pomodoro.status]);

  const navTheme = useMemo(
    () => ({
      ...(colors.dark ? DarkTheme : DefaultTheme),
      colors: {
        ...(colors.dark ? DarkTheme.colors : DefaultTheme.colors),
        background: colors.bg,
        card: colors.card,
        text: colors.fg,
        border: colors.bg,
        primary: colors.accent,
      },
    }),
    [colors],
  );

  return (
    <SafeAreaProvider>
      <NavigationContainer theme={navTheme}>
        <StatusBar style={colors.dark ? "light" : "dark"} />
        <Tab.Navigator
          screenOptions={{
            headerStyle: { backgroundColor: colors.card },
            headerTintColor: colors.fg,
            tabBarActiveTintColor: colors.accent,
            tabBarStyle: { backgroundColor: colors.card },
          }}
        >
          <Tab.Screen name="home" options={{ title: t("navHome") }}>
            {() => (
              <HomeScreen
                colors={colors}
                t={t}
                sessionsToday={stats.sessionsToday}
                totalFocusMinutes={stats.totalFocusMinutes}
                habitDone={getTodayHabitProgress(habits.habits).completed}
                habitTotal={getTodayHabitProgress(habits.habits).total}
              />
            )}
          </Tab.Screen>
          <Tab.Screen name="pomodoro" options={{ title: t("navPomodoro") }}>
            {() => (
              <PomodoroScreen
                colors={colors}
                t={t}
                locale={settings.locale}
                pomodoro={pomodoro}
                tasks={tasks}
              />
            )}
          </Tab.Screen>
          <Tab.Screen name="habits" options={{ title: t("navHabits") }}>
            {() => <HabitsScreen colors={colors} t={t} habits={habits} />}
          </Tab.Screen>
          <Tab.Screen name="stats" options={{ title: t("navStats") }}>
            {() => <StatsScreen colors={colors} t={t} stats={stats} />}
          </Tab.Screen>
          <Tab.Screen name="settings" options={{ title: t("navSettings") }}>
            {() => (
              <SettingsScreen
                colors={colors}
                t={t}
                settings={settings}
                setSettings={setSettings}
              />
            )}
          </Tab.Screen>
        </Tab.Navigator>
      </NavigationContainer>
    </SafeAreaProvider>
  );
}

type Colors = ReturnType<typeof useColors>;
type TFn = (key: Parameters<typeof translate>[1], params?: Record<string, string | number>) => string;

function Card({
  colors,
  children,
}: {
  colors: Colors;
  children: ReactNode;
}) {
  return (
    <View style={[styles.card, { backgroundColor: colors.card }]}>{children}</View>
  );
}

function HomeScreen({
  colors,
  t,
  sessionsToday,
  totalFocusMinutes,
  habitDone,
  habitTotal,
}: {
  colors: Colors;
  t: TFn;
  sessionsToday: number;
  totalFocusMinutes: number;
  habitDone: number;
  habitTotal: number;
}) {
  return (
    <ScrollView contentContainerStyle={[styles.page, { backgroundColor: colors.bg }]}>
      <Text style={[styles.title, { color: colors.fg }]}>{t("appName")}</Text>
      <Text style={{ color: colors.muted, marginBottom: 16 }}>{t("tagline")}</Text>
      <Card colors={colors}>
        <Text style={{ color: colors.muted }}>{t("today")}</Text>
        <Text style={[styles.stat, { color: colors.accent }]}>{sessionsToday}</Text>
        <Text style={{ color: colors.muted }}>{t("completedPomodoros")}</Text>
      </Card>
      <Card colors={colors}>
        <Text style={{ color: colors.muted }}>{t("focus")}</Text>
        <Text style={[styles.stat, { color: colors.accent }]}>
          {totalFocusMinutes} {t("minutesShort")}
        </Text>
      </Card>
      <Card colors={colors}>
        <Text style={{ color: colors.muted }}>{t("habit")}</Text>
        <Text style={[styles.stat, { color: colors.accent }]}>
          {habitDone}/{habitTotal}
        </Text>
      </Card>
    </ScrollView>
  );
}

function PomodoroScreen({
  colors,
  t,
  locale,
  pomodoro,
  tasks,
}: {
  colors: Colors;
  t: TFn;
  locale: LocaleId;
  pomodoro: ReturnType<typeof usePomodoro>;
  tasks: ReturnType<typeof useTasks>;
}) {
  const [draft, setDraft] = useState("");
  const primary =
    pomodoro.status === "idle"
      ? { label: t("start"), onPress: pomodoro.start }
      : pomodoro.status === "running"
        ? { label: t("pause"), onPress: pomodoro.pause }
        : { label: t("resume"), onPress: pomodoro.resume };

  return (
    <ScrollView contentContainerStyle={[styles.page, { backgroundColor: colors.bg }]}>
      <Text style={[styles.phase, { color: colors.accent }]}>
        {phaseLabel(locale, pomodoro.phase)}
      </Text>
      <Text style={[styles.timer, { color: colors.fg }]}>
        {formatTime(pomodoro.remainingSec)}
      </Text>
      <Pressable
        style={[styles.primary, { backgroundColor: colors.accent }]}
        onPress={primary.onPress}
      >
        <Text style={styles.primaryText}>{primary.label}</Text>
      </Pressable>
      <View style={styles.row}>
        <Pressable style={[styles.ghost, { borderColor: colors.accent }]} onPress={pomodoro.reset}>
          <Text style={{ color: colors.accent }}>{t("reset")}</Text>
        </Pressable>
        <Pressable style={[styles.ghost, { borderColor: colors.accent }]} onPress={pomodoro.skip}>
          <Text style={{ color: colors.accent }}>{t("skip")}</Text>
        </Pressable>
      </View>
      <Text style={[styles.section, { color: colors.fg }]}>{t("tasks")}</Text>
      <View style={styles.row}>
        <TextInput
          value={draft}
          onChangeText={setDraft}
          placeholder={t("newTask")}
          placeholderTextColor={colors.muted}
          style={[styles.input, { color: colors.fg, borderColor: colors.muted }]}
        />
        <Pressable
          style={[styles.ghost, { borderColor: colors.accent }]}
          onPress={() => {
            tasks.addTask(draft);
            setDraft("");
          }}
        >
          <Text style={{ color: colors.accent }}>{t("add")}</Text>
        </Pressable>
      </View>
      {tasks.tasks.length === 0 ? (
        <Text style={{ color: colors.muted }}>{t("noTasks")}</Text>
      ) : (
        tasks.tasks.map((task) => (
          <Pressable
            key={task.id}
            onPress={() =>
              tasks.setActiveTaskId(tasks.activeTaskId === task.id ? null : task.id)
            }
            onLongPress={() =>
              Alert.alert(task.title, undefined, [
                { text: t("cancel"), style: "cancel" },
                {
                  text: t("delete"),
                  style: "destructive",
                  onPress: () => tasks.deleteTask(task.id),
                },
              ])
            }
            style={[
              styles.task,
              {
                borderColor:
                  tasks.activeTaskId === task.id ? colors.accent : colors.muted,
              },
            ]}
          >
            <Text
              style={{
                color: colors.fg,
                textDecorationLine: task.completed ? "line-through" : "none",
              }}
            >
              {task.title}
            </Text>
          </Pressable>
        ))
      )}
    </ScrollView>
  );
}

function HabitsScreen({
  colors,
  t,
  habits,
}: {
  colors: Colors;
  t: TFn;
  habits: ReturnType<typeof useHabits>;
}) {
  const [draft, setDraft] = useState("");
  const progress = getTodayHabitProgress(habits.habits);
  return (
    <ScrollView contentContainerStyle={[styles.page, { backgroundColor: colors.bg }]}>
      <Text style={[styles.stat, { color: colors.accent }]}>
        {progress.completed}/{progress.total}
      </Text>
      <View style={styles.row}>
        <TextInput
          value={draft}
          onChangeText={setDraft}
          placeholder={t("habitPlaceholder")}
          placeholderTextColor={colors.muted}
          style={[styles.input, { color: colors.fg, borderColor: colors.muted }]}
        />
        <Pressable
          style={[styles.ghost, { borderColor: colors.accent }]}
          onPress={() => {
            habits.addHabit(draft);
            setDraft("");
          }}
        >
          <Text style={{ color: colors.accent }}>{t("add")}</Text>
        </Pressable>
      </View>
      {habits.habits.map((habit) => {
        const done = isHabitDoneToday(habit);
        return (
          <Pressable
            key={habit.id}
            onPress={() => habits.toggleDate(habit.id)}
            onLongPress={() => habits.deleteHabit(habit.id)}
            style={[styles.task, { borderColor: done ? colors.accent : colors.muted }]}
          >
            <Text style={{ color: colors.fg }}>
              {habit.emoji} {habit.title}
            </Text>
          </Pressable>
        );
      })}
    </ScrollView>
  );
}

function StatsScreen({
  colors,
  t,
  stats,
}: {
  colors: Colors;
  t: TFn;
  stats: ReturnType<typeof useStats>["stats"];
}) {
  return (
    <ScrollView contentContainerStyle={[styles.page, { backgroundColor: colors.bg }]}>
      <Card colors={colors}>
        <Text style={{ color: colors.muted }}>{t("statsCompleted")}</Text>
        <Text style={[styles.stat, { color: colors.accent }]}>{stats.sessionsToday}</Text>
      </Card>
      <Card colors={colors}>
        <Text style={{ color: colors.muted }}>{t("statsTotalTime")}</Text>
        <Text style={[styles.stat, { color: colors.accent }]}>
          {stats.totalFocusMinutes} {t("minutesShort")}
        </Text>
      </Card>
      <Text style={[styles.section, { color: colors.fg }]}>{t("statsWeekChart")}</Text>
      {stats.last7Days.map((d) => (
        <Text key={d.day} style={{ color: colors.muted }}>
          {d.day.slice(8)} — {t("sessionsCount", { n: d.count })}
        </Text>
      ))}
    </ScrollView>
  );
}

function SettingsScreen({
  colors,
  t,
  settings,
  setSettings,
}: {
  colors: Colors;
  t: TFn;
  settings: ReturnType<typeof useSettings>["settings"];
  setSettings: ReturnType<typeof useSettings>["setSettings"];
}) {
  return (
    <ScrollView contentContainerStyle={[styles.page, { backgroundColor: colors.bg }]}>
      <Text style={[styles.section, { color: colors.fg }]}>{t("settingsLanguage")}</Text>
      <View style={styles.row}>
        <Pressable
          style={[styles.ghost, { borderColor: settings.locale === "tr" ? colors.accent : colors.muted }]}
          onPress={() => setSettings({ locale: "tr" })}
        >
          <Text style={{ color: colors.fg }}>Türkçe</Text>
        </Pressable>
        <Pressable
          style={[styles.ghost, { borderColor: settings.locale === "en" ? colors.accent : colors.muted }]}
          onPress={() => setSettings({ locale: "en" })}
        >
          <Text style={{ color: colors.fg }}>English</Text>
        </Pressable>
      </View>
      <Text style={[styles.section, { color: colors.fg }]}>{t("durations")}</Text>
      {(["focusMin", "shortBreakMin", "longBreakMin"] as const).map((key) => (
        <View key={key} style={styles.row}>
          <Text style={{ color: colors.fg, flex: 1 }}>{t(key === "focusMin" ? "focusDuration" : key === "shortBreakMin" ? "shortBreak" : "longBreak")}</Text>
          <Pressable onPress={() => setSettings({ [key]: Math.max(1, settings[key] - 1) })}>
            <Text style={{ color: colors.accent, fontSize: 24 }}>−</Text>
          </Pressable>
          <Text style={{ color: colors.fg, width: 40, textAlign: "center" }}>{settings[key]}</Text>
          <Pressable onPress={() => setSettings({ [key]: Math.min(120, settings[key] + 1) })}>
            <Text style={{ color: colors.accent, fontSize: 24 }}>+</Text>
          </Pressable>
        </View>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  page: { padding: 20, gap: 12, paddingBottom: 40 },
  title: { fontSize: 28, fontWeight: "700" },
  phase: { fontSize: 18, fontWeight: "600", textAlign: "center" },
  timer: { fontSize: 64, fontWeight: "700", textAlign: "center", fontVariant: ["tabular-nums"] },
  stat: { fontSize: 32, fontWeight: "700", marginVertical: 4 },
  section: { fontSize: 16, fontWeight: "600", marginTop: 8 },
  card: { borderRadius: 16, padding: 16 },
  primary: { borderRadius: 999, paddingVertical: 14, alignItems: "center" },
  primaryText: { color: "#fff", fontSize: 18, fontWeight: "700" },
  ghost: { borderWidth: 1, borderRadius: 999, paddingVertical: 10, paddingHorizontal: 16 },
  row: { flexDirection: "row", alignItems: "center", gap: 8 },
  input: { flex: 1, borderWidth: 1, borderRadius: 12, paddingHorizontal: 12, paddingVertical: 10 },
  task: { borderWidth: 1, borderRadius: 12, padding: 12 },
});
