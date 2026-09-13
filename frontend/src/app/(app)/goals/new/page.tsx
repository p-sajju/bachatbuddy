"use client";

import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";
import { PageHeader } from "@/components/PageHeader";
import { Button, ErrorBanner, Field, Input, TextArea } from "@/components/ui";
import { apiPost, ApiRequestError } from "@/lib/api";
import { parseRupeesInput } from "@/lib/money";

export default function NewGoalPage() {
  const router = useRouter();
  const [name, setName] = useState("");
  const [target, setTarget] = useState("");
  const [targetDate, setTargetDate] = useState("");
  const [monthly, setMonthly] = useState("");
  const [notes, setNotes] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    const targetPaise = parseRupeesInput(target);
    if (!name.trim() || targetPaise === null || targetPaise <= 0) {
      setError("Name and a valid target amount are required.");
      return;
    }
    const monthlyPaise = monthly ? parseRupeesInput(monthly) : 0;
    if (monthly && monthlyPaise === null) {
      setError("Invalid monthly contribution.");
      return;
    }
    setLoading(true);
    setError("");
    try {
      const res = await apiPost<{ id: string }>("/api/v1/savings_goals", {
        name: name.trim(),
        target_paise: targetPaise,
        target_date: targetDate || undefined,
        monthly_contribution_paise: monthlyPaise || 0,
        notes: notes || undefined,
      });
      router.replace(`/goals/${res.data.id}`);
    } catch (err) {
      setError(
        err instanceof ApiRequestError ? err.message : "Could not create goal.",
      );
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <PageHeader title="New savings goal" backHref="/goals" />
      <ErrorBanner message={error} />
      <form onSubmit={onSubmit} className="space-y-4">
        <Field label="Goal name">
          <Input
            required
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Emergency fund"
            autoFocus
          />
        </Field>
        <Field label="Target amount (₹)">
          <Input
            inputMode="decimal"
            required
            value={target}
            onChange={(e) => setTarget(e.target.value)}
            placeholder="1,00,000"
          />
        </Field>
        <Field label="Target date">
          <Input
            type="date"
            value={targetDate}
            onChange={(e) => setTargetDate(e.target.value)}
          />
        </Field>
        <Field label="Monthly contribution (₹)" hint="Optional if you set a date">
          <Input
            inputMode="decimal"
            value={monthly}
            onChange={(e) => setMonthly(e.target.value)}
            placeholder="5,000"
          />
        </Field>
        <Field label="Notes">
          <TextArea rows={2} value={notes} onChange={(e) => setNotes(e.target.value)} />
        </Field>
        <Button type="submit" className="w-full" loading={loading}>
          Create goal
        </Button>
      </form>
    </div>
  );
}
