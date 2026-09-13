"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { PageHeader } from "@/components/PageHeader";
import { EmptyState, ProgressBar, Surface } from "@/components/ui";
import { apiGet, ApiRequestError } from "@/lib/api";
import { formatINR } from "@/lib/money";
import type { SavingsGoal } from "@/lib/types";

export default function GoalsPage() {
  const [goals, setGoals] = useState<SavingsGoal[]>([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    apiGet<SavingsGoal[]>("/api/v1/savings_goals")
      .then((res) => setGoals(res.data || []))
      .catch((err) =>
        setError(
          err instanceof ApiRequestError ? err.message : "Could not load goals.",
        ),
      )
      .finally(() => setLoading(false));
  }, []);

  return (
    <div>
      <PageHeader
        title="Savings goals"
        subtitle="Purpose for every rupee you protect"
        action={
          <Link
            href="/goals/new"
            className="rounded-xl bg-[var(--bb-forest)] px-3 py-2 text-sm font-semibold text-white"
          >
            New
          </Link>
        }
      />
      {loading ? (
        <div className="flex justify-center py-16">
          <div className="h-8 w-8 animate-spin rounded-full border-2 border-[var(--bb-forest)] border-t-transparent" />
        </div>
      ) : error ? (
        <EmptyState title="Unable to load" body={error} />
      ) : goals.length === 0 ? (
        <EmptyState
          title="No goals yet"
          body="Create a goal — emergency fund, trip, or wedding."
          action={
            <Link href="/goals/new" className="text-sm font-semibold text-[var(--bb-forest)]">
              Create goal
            </Link>
          }
        />
      ) : (
        <div className="space-y-3">
          {goals.map((goal) => {
            const pct =
              goal.target_paise > 0
                ? (goal.current_paise / goal.target_paise) * 100
                : 0;
            return (
              <Link key={goal.id} href={`/goals/${goal.id}`}>
                <Surface className="mb-3 space-y-2">
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <p className="font-semibold">{goal.name}</p>
                      {goal.target_date ? (
                        <p className="text-xs text-[var(--bb-muted)]">
                          Target {goal.target_date}
                        </p>
                      ) : null}
                    </div>
                    <p className="text-sm tabular-nums font-medium">
                      {Math.round(pct)}%
                    </p>
                  </div>
                  <ProgressBar value={pct} />
                  <p className="text-xs text-[var(--bb-muted)] tabular-nums">
                    {formatINR(goal.current_paise)} of{" "}
                    {formatINR(goal.target_paise)}
                  </p>
                </Surface>
              </Link>
            );
          })}
        </div>
      )}
    </div>
  );
}
