"use client";

import { useEffect, useState } from "react";
import { PageHeader } from "@/components/PageHeader";
import { EmptyState, Surface } from "@/components/ui";
import { apiGet, apiPatch, ApiRequestError } from "@/lib/api";
import type { NotificationItem } from "@/lib/types";

export default function NotificationsPage() {
  const [items, setItems] = useState<NotificationItem[]>([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  function load() {
    return apiGet<NotificationItem[]>("/api/v1/notifications")
      .then((res) => setItems(res.data || []))
      .catch((err) =>
        setError(
          err instanceof ApiRequestError
            ? err.message
            : "Could not load notifications.",
        ),
      );
  }

  useEffect(() => {
    load().finally(() => setLoading(false));
  }, []);

  async function markRead(id: string) {
    try {
      await apiPatch(`/api/v1/notifications/${id}`, { read: true });
      setItems((prev) =>
        prev.map((n) =>
          n.id === id ? { ...n, read_at: new Date().toISOString() } : n,
        ),
      );
    } catch {
      // ignore
    }
  }

  return (
    <div>
      <PageHeader
        title="Notifications"
        subtitle="Gentle nudges, not noise"
        backHref="/more"
      />
      {loading ? (
        <div className="flex justify-center py-16">
          <div className="h-8 w-8 animate-spin rounded-full border-2 border-[var(--bb-forest)] border-t-transparent" />
        </div>
      ) : error ? (
        <EmptyState title="Unable to load" body={error} />
      ) : items.length === 0 ? (
        <EmptyState
          title="You're all caught up"
          body="Insights and reminders will show up here."
        />
      ) : (
        <div className="space-y-3">
          {items.map((n) => (
            <button
              key={n.id}
              type="button"
              onClick={() => !n.read_at && markRead(n.id)}
              className="w-full text-left"
            >
              <Surface
                className={`${n.read_at ? "opacity-70" : "border-[var(--bb-leaf)]/30"}`}
              >
                <div className="flex items-start justify-between gap-3">
                  <p className="font-semibold text-[var(--bb-ink)]">{n.title}</p>
                  {!n.read_at ? (
                    <span className="mt-1 h-2 w-2 shrink-0 rounded-full bg-[var(--bb-leaf)]" />
                  ) : null}
                </div>
                <p className="mt-1 text-sm text-[var(--bb-muted)]">{n.body}</p>
                <p className="mt-2 text-xs text-[var(--bb-muted)]">
                  {new Date(n.created_at).toLocaleString("en-IN")}
                </p>
              </Surface>
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
