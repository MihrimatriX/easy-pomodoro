"use client";

import { useCallback, useEffect, useState } from "react";
import { createId } from "@shared/pomodoro";
import type { Task } from "@shared/types";
import { loadTasks, saveTasks, loadActiveTaskId, saveActiveTaskId } from "@/lib/storage";

export function useTasks() {
  const [tasks, setTasks] = useState<Task[]>([]);
  const [activeTaskId, setActiveTaskIdState] = useState<string | null>(null);
  const [hydrated, setHydrated] = useState(false);

  useEffect(() => {
    const loaded = loadTasks();
    setTasks(loaded);
    const savedId = loadActiveTaskId();
    setActiveTaskIdState(
      savedId && loaded.some((task) => task.id === savedId) ? savedId : null,
    );
    setHydrated(true);
  }, []);

  useEffect(() => {
    if (!hydrated) return;
    saveTasks(tasks);
  }, [tasks, hydrated]);

  useEffect(() => {
    if (!hydrated) return;
    saveActiveTaskId(activeTaskId);
  }, [activeTaskId, hydrated]);

  const addTask = useCallback((title: string, estimatedPomodoros = 0) => {
    const trimmed = title.trim();
    if (!trimmed) return;
    const task: Task = {
      id: createId(),
      title: trimmed,
      completed: false,
      createdAt: new Date().toISOString(),
      estimatedPomodoros:
        estimatedPomodoros > 0 ? estimatedPomodoros : undefined,
    };
    setTasks((prev) => [task, ...prev]);
  }, []);

  const toggleTask = useCallback((id: string) => {
    setTasks((prev) =>
      prev.map((t) => (t.id === id ? { ...t, completed: !t.completed } : t)),
    );
  }, []);

  const updateTask = useCallback(
    (
      id: string,
      patch: Partial<Pick<Task, "title" | "estimatedPomodoros">>,
    ) => {
      setTasks((prev) =>
        prev.map((t) => (t.id === id ? { ...t, ...patch } : t)),
      );
    },
    [],
  );

  const deleteTask = useCallback((id: string) => {
    setTasks((prev) => prev.filter((t) => t.id !== id));
    setActiveTaskIdState((current) => (current === id ? null : current));
  }, []);

  const setActiveTaskId = useCallback((id: string | null) => {
    setActiveTaskIdState(id);
  }, []);

  return {
    tasks,
    activeTaskId,
    setActiveTaskId,
    addTask,
    toggleTask,
    updateTask,
    deleteTask,
    hydrated,
  };
}
