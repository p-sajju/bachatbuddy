"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { PageHeader } from "@/components/PageHeader";
import { Button, Disclaimer, EmptyState, Surface } from "@/components/ui";
import { apiGet, ApiRequestError } from "@/lib/api";
import { formatINR } from "@/lib/money";
import type { MoneyLock } from "@/lib/types";

export default function LockDetailPage() {
  const { id } = useParams<{ id: string }>();
  const [lock, setLock] = useState<MoneyLock | null>(null);
  const [history, setHistory] = useState<
    { id: string; kind?: string; note?: string; created_at?: string }[]
  >([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      apiGet<MoneyLock>(`/api/v1/money_locks/${id}`),
      apiGet<{ id: string; kind?: string; note?: string; created_at?: string }[]>(
        `/api/v1/money_locks/${id}/history`,
      ).catch(() => ({ data: [] })),
    ])
      .then(([lockRes, histRes]) => {
        setLock(lockRes.data);
        setHistory(histRes.data || []);
      })
      .catch((err) =>
        setError(
          err instanceof ApiRequestError ? err.message : "Could not load lock.",
        ),
      )
      .finally(() => setLoading(false));
  }, [id]);

  const canUnlock =
    lock && (lock.status === "active" || lock.status === "unlock_requested");

  return (
    <div>
      <PageHeader title={lock?.name || "Money Lock"} backHref="/locks" />
      {loading ? (
        <div className="flex justify-center py-16">
          <div className="h-8 w-8 animate-spin rounded-full border-2 border-[var(--bb-forest)] border-t-transparent" />
        </div>
      ) : error || !lock ? (
        <EmptyState title="Not found" body={error} />
      ) : (
        <div className="space-y-4">
          <Surface>
            <p className="text-sm text-[var(--bb-muted)]">Protected amount</p>
            <p className="mt-1 font-[family-name:var(--font-display)] text-3xl font-semibold tabular-nums text-[var(--bb-forest)]">
              {formatINR(lock.amount_paise)}
            </p>
            <p className="mt-2 text-sm capitalize text-[var(--bb-muted)]">
              Status: {lock.status.replace(/_/g, " ")}
            </p>
            {lock.purpose ? (
              <p className="mt-2 text-sm text-[var(--bb-ink)]">{lock.purpose}</p>
            ) : null}
            {lock.unlock_available_at ? (
              <p className="mt-2 text-xs text-amber-800">
                Cooling off until {new Date(lock.unlock_available_at).toLocaleString("en-IN")}
              </p>
            ) : null}
          </Surface>

          <Disclaimer>
            Unlocking reduces your protected balance in BachatBuddy only — it
            does not move money in your bank.
          </Disclaimer>

          {canUnlock ? (
            <Link href={`/locks/${lock.id}/unlock`}>
              <Button className="w-full" variant="secondary">
                Start unlock
              </Button>
            </Link>
          ) : null}

          {history.length > 0 ? (
            <Surface>
              <h2 className="mb-3 font-semibold">History</h2>
              <ul className="space-y-2 text-sm">
                {history.map((h) => (
                  <li key={h.id} className="flex justify-between gap-3">
                    <span>{h.kind || h.note || "Event"}</span>
                    <span className="text-[var(--bb-muted)]">
                      {h.created_at
                        ? new Date(h.created_at).toLocaleDateString("en-IN")
                        : ""}
                    </span>
                  </li>
                ))}
              </ul>
            </Surface>
          ) : null}
        </div>
      )}
    </div>
  );
}
