"use client";

import { FormEvent, useEffect, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense } from "react";
import { PageHeader } from "@/components/PageHeader";
import {
  Button,
  Disclaimer,
  ErrorBanner,
  Field,
  Input,
  Select,
  TextArea,
} from "@/components/ui";
import { apiGet, apiPost, ApiRequestError } from "@/lib/api";
import { parseRupeesInput } from "@/lib/money";
import type { SavingsGoal } from "@/lib/types";

function CreateLockForm() {
  const router = useRouter();
  const search = useSearchParams();
  const [name, setName] = useState("");
  const [amount, setAmount] = useState("");
  const [purpose, setPurpose] = useState("");
  const [goalId, setGoalId] = useState(search.get("goal") || "");
  const [goals, setGoals] = useState<SavingsGoal[]>([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    apiGet<SavingsGoal[]>("/api/v1/savings_goals")
      .then((res) => setGoals(res.data || []))
      .catch(() => undefined);
  }, []);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    const amountPaise = parseRupeesInput(amount);
    if (!name.trim() || amountPaise === null || amountPaise <= 0) {
      setError("Name and a valid amount are required.");
      return;
    }
    setLoading(true);
    setError("");
    try {
      const res = await apiPost<{ id: string }>("/api/v1/money_locks", {
        name: name.trim(),
        amount_paise: amountPaise,
        purpose: purpose || undefined,
        savings_goal_id: goalId || undefined,
      });
      router.replace(`/locks/${res.data.id}`);
    } catch (err) {
      setError(
        err instanceof ApiRequestError ? err.message : "Could not create lock.",
      );
    } finally {
      setLoading(false);
    }
  }

  return (
    <>
      <Disclaimer>
        This is a virtual lock inside BachatBuddy. Your bank account is
        unchanged.
      </Disclaimer>
      <ErrorBanner message={error} />
      <form onSubmit={onSubmit} className="mt-4 space-y-4">
        <Field label="Lock name">
          <Input
            required
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Emergency buffer"
            autoFocus
          />
        </Field>
        <Field label="Amount (₹)">
          <Input
            inputMode="decimal"
            required
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            placeholder="20,000"
          />
        </Field>
        <Field label="Linked goal">
          <Select value={goalId} onChange={(e) => setGoalId(e.target.value)}>
            <option value="">None</option>
            {goals.map((g) => (
              <option key={g.id} value={g.id}>
                {g.name}
              </option>
            ))}
          </Select>
        </Field>
        <Field label="Purpose">
          <TextArea
            rows={2}
            value={purpose}
            onChange={(e) => setPurpose(e.target.value)}
            placeholder="Why are you protecting this?"
          />
        </Field>
        <Button type="submit" className="w-full" loading={loading}>
          Create Money Lock
        </Button>
      </form>
    </>
  );
}

export default function NewLockPage() {
  return (
    <div>
      <PageHeader title="Create Money Lock" backHref="/locks" />
      <Suspense
        fallback={
          <div className="flex justify-center py-10">
            <div className="h-8 w-8 animate-spin rounded-full border-2 border-[var(--bb-forest)] border-t-transparent" />
          </div>
        }
      >
        <CreateLockForm />
      </Suspense>
    </div>
  );
}
