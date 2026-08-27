"use client";

import { Check, Plus, Trash2, Edit2, Save, X } from "lucide-react";
import { useState } from "react";
import { NeoStepper } from "@/components/NeoStepper";
import { useT } from "@/context/LocaleContext";
import type { Task, SessionLog } from "@shared/types";

type TaskListProps = {
  tasks: Task[];
  activeTaskId: string | null;
  onAdd: (title: string, estimatedPomodoros?: number) => void;
  onToggle: (id: string) => void;
  onUpdate: (
    id: string,
    patch: Partial<Pick<Task, "title" | "estimatedPomodoros">>,
  ) => void;
  onDelete: (id: string) => void;
  onSelectActive: (id: string | null) => void;
  sessions?: SessionLog[];
  showTitle?: boolean;
  compact?: boolean;
};

export function TaskList({
  tasks,
  activeTaskId,
  onAdd,
  onToggle,
  onUpdate,
  onDelete,
  onSelectActive,
  sessions = [],
  showTitle = false,
  compact = false,
}: TaskListProps) {
  const t = useT();
  const [input, setInput] = useState("");
  const [estimated, setEstimated] = useState(0);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editTitle, setEditTitle] = useState("");
  const [editEst, setEditEst] = useState(0);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim()) return;
    onAdd(input, estimated);
    setInput("");
    setEstimated(0);
  };

  const startEdit = (task: Task) => {
    setEditingId(task.id);
    setEditTitle(task.title);
    setEditEst(task.estimatedPomodoros || 0);
  };

  const handleSave = (id: string) => {
    if (!editTitle.trim()) return;
    onUpdate(id, {
      title: editTitle.trim(),
      estimatedPomodoros: editEst > 0 ? editEst : undefined,
    });
    setEditingId(null);
  };

  const getCompletedCount = (taskId: string) => {
    return sessions.filter((s) => s.phase === "focus" && s.taskId === taskId)
      .length;
  };

  const renderTomatoes = (completed: number, estimatedCount?: number) => {
    if (!estimatedCount || estimatedCount <= 0) {
      if (completed === 0) return null;
      return <span className="task-pomo-badge">🍅 {completed}</span>;
    }

    const limit = Math.max(completed, estimatedCount);
    const displayLimit = Math.min(limit, 5);

    return (
      <span className="task-pomo-badge">
        {Array.from({ length: displayLimit }).map((_, i) => (
          <span key={i} className={i < completed ? "" : "opacity-35 grayscale"}>
            🍅
          </span>
        ))}
        {limit > 5 && <span className="text-accent">+{limit - 5}</span>}
        <span className="font-mono text-xs font-bold text-accent">
          ({completed}/{estimatedCount})
        </span>
      </span>
    );
  };

  return (
    <div
      className={`task-list-panel ${compact ? "task-list-panel-compact" : ""}`}
    >
      {showTitle && <p className="section-label">{t("tasks")}</p>}

      <form onSubmit={handleSubmit} className="task-add-form">
        <input
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder={t("newTask")}
          className="neo-input task-add-input text-foreground"
        />
        <div className="task-add-actions">
          <div className="task-add-pomo">
            <span className="task-add-pomo-label" title={t("targetPomos")}>
              🍅 {t("targetPomos")}
            </span>
            <NeoStepper
              variant="pill"
              compact
              value={estimated}
              onChange={setEstimated}
              min={0}
              max={20}
              ariaLabel={t("targetPomos")}
            />
          </div>
          <button
            type="submit"
            className="neo-btn-primary task-add-btn"
            aria-label={t("add")}
          >
            <Plus size={16} strokeWidth={2.5} />
            <span>{t("add")}</span>
          </button>
        </div>
      </form>

      <div className="task-list-scroll">
        {tasks.length === 0 ? (
          <div className="task-empty neo-inset-sm">{t("noTasks")}</div>
        ) : (
          <ul className="task-list">
            {tasks.map((task) => {
              const completedCount = getCompletedCount(task.id);
              const isEditing = editingId === task.id;

              return (
                <li
                  key={task.id}
                  className={`task-row ${activeTaskId === task.id ? "task-active" : ""}`}
                >
                  {isEditing ? (
                    <div className="task-edit-row">
                      <input
                        type="text"
                        value={editTitle}
                        onChange={(e) => setEditTitle(e.target.value)}
                        className="neo-input flex-1 px-3 py-2 text-base text-foreground"
                        autoFocus
                      />
                      <div className="task-pomo-stepper">
                        <span className="task-add-pomo-label">🍅</span>
                        <NeoStepper
                          variant="pill"
                          compact
                          value={editEst}
                          onChange={setEditEst}
                          min={0}
                          max={20}
                          ariaLabel={t("estimatedPomos")}
                        />
                      </div>
                      <div className="flex gap-1">
                        <button
                          type="button"
                          onClick={() => handleSave(task.id)}
                          className="neo-icon-btn text-accent"
                          title={t("save")}
                        >
                          <Save size={16} />
                        </button>
                        <button
                          type="button"
                          onClick={() => setEditingId(null)}
                          className="neo-icon-btn text-muted"
                          title={t("cancel")}
                        >
                          <X size={16} />
                        </button>
                      </div>
                    </div>
                  ) : (
                    <>
                      <button
                        type="button"
                        onClick={() => onToggle(task.id)}
                        className={`task-check-btn ${
                          task.completed
                            ? "task-check-btn-done neo-btn-primary"
                            : "neo-inset-sm"
                        }`}
                      >
                        {task.completed && (
                          <Check
                            size={14}
                            className="stroke-[3px] text-white"
                          />
                        )}
                      </button>
                      <div className="task-main">
                        <div className="task-body">
                          <button
                            type="button"
                            onClick={() =>
                              onSelectActive(
                                activeTaskId === task.id ? null : task.id,
                              )
                            }
                            className={`task-title-btn ${
                              task.completed ? "task-title done" : ""
                            }`}
                          >
                            {task.title}
                          </button>
                          {renderTomatoes(
                            completedCount,
                            task.estimatedPomodoros,
                          )}
                        </div>
                        <div className="task-spacer" aria-hidden />
                        <div className="task-actions">
                          <button
                            type="button"
                            onClick={() => startEdit(task)}
                            className="neo-icon-btn text-muted"
                            title={t("edit")}
                          >
                            <Edit2 size={15} />
                          </button>
                          <button
                            type="button"
                            onClick={() => {
                              if (
                                window.confirm(
                                  t("confirmDeleteTask", { title: task.title }),
                                )
                              ) {
                                onDelete(task.id);
                              }
                            }}
                            className="neo-icon-btn text-muted"
                            title={t("delete")}
                          >
                            <Trash2 size={15} />
                          </button>
                        </div>
                      </div>
                    </>
                  )}
                </li>
              );
            })}
          </ul>
        )}
      </div>
    </div>
  );
}
