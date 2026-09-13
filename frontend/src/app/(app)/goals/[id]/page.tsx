"use client";

import { FormEvent, useEffect, useState } from "react";
import { useParams } from "next/navigation";
import Link from "next/link";
import { PageHeader } from "@/components/PageHeader";
import {
  Button,
  EmptyState,
  ErrorBanner,
  Field,
  Input,
  ProgressBar,
  Surface,
} from "@/components/ui";
import { apiGet, apiPost, ApiRequestError } from "@/lib/api";
import { formatINR, parseRupeesInput } from "@/lib/money";
import type { SavingsGoal } from "@/lib/types";

export default function GoalDetailPage() {
  const { id } = useParams<{ id: string }>();
  const [goal, setGoal] = useState<SavingsGoal | null>(null);
  const [amount, setAmount] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  function load() {
    return apiGet<SavingsGoal>(`/api/v1/savings_goals/${id}`)
      .then((res) => setGoal(res.data))
      .catch((err) =>
        setError(
          err instanceof ApiRequestError ? err.message : "Could not load goal.",
        ),
      );
  }

  useEffect(() => {
    load().finally(() => setLoading(false));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id]);

  async function onContribute(e: FormEvent) {
    e.preventDefault();
    const amountPaise = parseRupeesInput(amount);
    if (amountPaise === null || amountPaise <= 0) {
      setError("Enter a valid contribution.");
      return;
    }
    setSaving(true);
    setError("");
    try {
      await apiPost(`/api/v1/savings_goals/${id}/contribute`, {
        amount_paise: amountPaise,
      });
      setAmount("");
      await load();
    } catch (err) {
      setError(
        err instanceof ApiRequestError
          ? err.message
          : "Could not add contribution.",
      );
    } finally {
      setSaving(false);
    }
  }

  const pct =
    goal && goal.target_paise > 0
      ? (goal.current_paise / goal.target_paise) * 100
      : 0;

  return (
    <div>
      <PageHeader title={goal?.name || "Goal"} backHref="/goals" />
      {loading ? (
        <div className="flex justify-center py-16">
          <div className="h-8 w-8 animate-spin rounded-full border-2 border-[var(--bb-forest)] border-t-transparent" />
        </div>
      ) : !goal ? (
        <EmptyState title="Not found" body={error} />
      ) : (
        <div className="space-y-4">
          <Surface className="space-y-3">
            <p className="font-[family-name:var(--font-display)] text-3xl font-semibold tabular-nums text-[var(--bb-forest)]">
              {formatINR(goal.current_paise)}
            </p>
            <p className="text-sm text-[var(--bb-muted)]">
              of {formatINR(goal.target_paise)} · {Math.round(pct)}%
            </p>
            <ProgressBar value={pct} />
            {goal.suggested_contribution_paise != null ? (
              <p className="text-sm text-[var(--bb-muted)]">
                Suggested this month:{" "}
                <span className="font-semibold text-[var(--bb-ink)]">
                  {formatINR(goal.suggested_contribution_paise)}
                </span>
              </p>
            ) : null}
            <Link
              href={`/locks/new?goal=${goal.id}`}
              className="inline-block text-sm font-semibold text-[var(--bb-forest)]"
            >
              Protect with a Money Lock →
            </Link>
          </Surface>

          <Surface>
            <h2 className="mb-3 font-semibold">Add contribution</h2>
            <ErrorBanner message={error} />
            <form onSubmit={onContribute} className="space-y-3">
              <Field label="Amount (₹)">
                <Input
                  inputMode="decimal"
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  placeholder={
                    goal.suggested_contribution_paise
                      ? String(goal.suggested_contribution_paise / 100)
                      : "1,000"
                  }
                />
              </Field>
              <Button type="submit" className="w-full" loading={saving}>
                Contribute
              </Button>
            </form>
          </Surface>
        </div>
      )}
    </div>
  );
}
