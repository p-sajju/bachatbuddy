"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import { ProfileAvatar } from "@/components/ProfileAvatar";
import {
  Disclaimer,
  EmptyState,
  ProgressBar,
  StatTile,
  Surface,
} from "@/components/ui";
import { apiGet, ApiRequestError } from "@/lib/api";
import { formatINR } from "@/lib/money";
import type { DashboardSummary, User } from "@/lib/types";

const STS_DISCLAIMER =
  "Safe to Spend is a planning figure based on income, expenses, locks, and goals — not your live bank balance.";

function greetingForHour(hour: number): string {
  if (hour < 12) return "Good morning";
  if (hour < 17) return "Good afternoon";
  return "Good evening";
}

export default function HomePage() {
  const [data, setData] = useState<DashboardSummary | null>(null);
  const [user, setUser] = useState<User | null>(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  const greetWord = useMemo(
    () => greetingForHour(new Date().getHours()),
    [],
  );

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const [dash, me] = await Promise.all([
          apiGet<DashboardSummary>("/api/v1/dashboard"),
          apiGet<User>("/api/v1/me"),
        ]);
        if (!cancelled) {
          setData(dash.data);
          setUser(me.data);
        }
      } catch (err) {
        if (!cancelled) {
          setError(
            err instanceof ApiRequestError
              ? err.message
              : "Could not load dashboard.",
          );
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  const displayName =
    user?.first_name?.trim() ||
    user?.name?.trim()?.split(/\s+/)[0] ||
    "there";

  return (
    <div>
      <header className="mb-5 flex items-start justify-between gap-3 pt-2">
        <div className="min-w-0">
          <p className="font-[family-name:var(--font-display)] text-3xl font-semibold tracking-tight text-[var(--bb-forest)] sm:text-4xl">
            Hi {displayName}
          </p>
          <p className="mt-1 text-sm leading-relaxed text-[var(--bb-muted)]">
            {greetWord} — welcome back. Here&apos;s your money at a glance.
          </p>
        </div>
        <ProfileAvatar
          firstName={user?.first_name}
          lastName={user?.last_name}
          name={user?.name}
          avatarUrl={user?.avatar_url}
          initials={user?.initials}
          size="md"
        />
      </header>

      {loading ? (
        <div className="flex justify-center py-16">
          <div className="h-8 w-8 animate-spin rounded-full border-2 border-[var(--bb-forest)] border-t-transparent" />
        </div>
      ) : error ? (
        <EmptyState title="Dashboard unavailable" body={error} />
      ) : data ? (
        <div className="space-y-4">
          <Surface className="bb-fade-up overflow-hidden relative">
            <div
              className="pointer-events-none absolute -right-8 -top-8 h-32 w-32 rounded-full bg-[var(--bb-mint)] opacity-70 animate-[softPulse_4s_ease_infinite]"
              aria-hidden
            />
            <p className="text-sm font-medium text-[var(--bb-muted)]">
              Safe to Spend
            </p>
            <p className="mt-1 font-[family-name:var(--font-display)] text-4xl font-semibold tracking-tight text-[var(--bb-forest)] tabular-nums">
              {formatINR(data.safe_to_spend_paise)}
            </p>
            <p className="mt-2 text-xs text-[var(--bb-muted)]">
              Plan your discretionary spend with confidence.
            </p>
          </Surface>

          <div className="grid grid-cols-2 gap-3 bb-fade-up-delay">
            <StatTile label="Income" value={formatINR(data.income_paise)} tone="good" />
            <StatTile
              label="Expenses"
              value={formatINR(data.expenses_paise)}
              tone="warn"
            />
            <StatTile
              label="Locked"
              value={formatINR(data.locked_paise)}
              tone="locked"
            />
            <StatTile label="Saved" value={formatINR(data.saved_paise)} tone="good" />
          </div>

          <Surface>
            <div className="mb-3 flex items-center justify-between">
              <h2 className="font-semibold text-[var(--bb-ink)]">Top spending</h2>
              <Link href="/reports" className="text-xs font-medium text-[var(--bb-forest)]">
                Reports
              </Link>
            </div>
            {data.top_spending && data.top_spending.length > 0 ? (
              <ul className="space-y-3">
                {data.top_spending.slice(0, 5).map((row) => (
                  <li key={row.name} className="flex items-center justify-between gap-3 text-sm">
                    <span className="text-[var(--bb-ink)]">{row.name}</span>
                    <span className="tabular-nums font-medium">
                      {formatINR(row.amount_paise)}
                    </span>
                  </li>
                ))}
              </ul>
            ) : (
              <p className="text-sm text-[var(--bb-muted)]">
                No expenses yet this month.
              </p>
            )}
          </Surface>

          <Surface>
            <div className="mb-3 flex items-center justify-between">
              <h2 className="font-semibold">Protected (Money Locks)</h2>
              <Link href="/locks" className="text-xs font-medium text-[var(--bb-forest)]">
                View all
              </Link>
            </div>
            {data.protected_locks && data.protected_locks.length > 0 ? (
              <ul className="space-y-3">
                {data.protected_locks.slice(0, 3).map((lock) => (
                  <li key={lock.id}>
                    <Link
                      href={`/locks/${lock.id}`}
                      className="flex items-center justify-between gap-3 text-sm"
                    >
                      <span>{lock.name}</span>
                      <span className="tabular-nums font-medium text-[var(--bb-forest)]">
                        {formatINR(lock.amount_paise)}
                      </span>
                    </Link>
                  </li>
                ))}
              </ul>
            ) : (
              <p className="text-sm text-[var(--bb-muted)]">
                No active locks. Protect savings from impulse spends.
              </p>
            )}
          </Surface>

          <Surface>
            <div className="mb-3 flex items-center justify-between">
              <h2 className="font-semibold">Goals</h2>
              <Link href="/goals" className="text-xs font-medium text-[var(--bb-forest)]">
                All goals
              </Link>
            </div>
            {data.goals && data.goals.length > 0 ? (
              <ul className="space-y-4">
                {data.goals.slice(0, 3).map((goal) => {
                  const pct =
                    goal.target_paise > 0
                      ? (goal.current_paise / goal.target_paise) * 100
                      : 0;
                  return (
                    <li key={goal.id}>
                      <Link href={`/goals/${goal.id}`} className="block space-y-1.5">
                        <div className="flex justify-between text-sm">
                          <span className="font-medium">{goal.name}</span>
                          <span className="tabular-nums text-[var(--bb-muted)]">
                            {formatINR(goal.current_paise, { showPaise: false })} /{" "}
                            {formatINR(goal.target_paise, { showPaise: false })}
                          </span>
                        </div>
                        <ProgressBar value={pct} />
                      </Link>
                    </li>
                  );
                })}
              </ul>
            ) : (
              <p className="text-sm text-[var(--bb-muted)]">
                Set a savings goal to start building purpose.
              </p>
            )}
          </Surface>

          {data.insights && data.insights.length > 0 ? (
            <Surface>
              <h2 className="mb-3 font-semibold text-[var(--bb-ink)]">Insights</h2>
              <ul className="space-y-3">
                {data.insights.map((insight, idx) => (
                  <li key={insight.kind || insight.title || idx} className="text-sm">
                    <p className="font-medium text-[var(--bb-ink)]">{insight.title}</p>
                    <p className="mt-0.5 text-[var(--bb-muted)]">{insight.body}</p>
                  </li>
                ))}
              </ul>
            </Surface>
          ) : null}

          <Disclaimer>{data.disclaimer || STS_DISCLAIMER}</Disclaimer>
        </div>
      ) : null}
    </div>
  );
}
