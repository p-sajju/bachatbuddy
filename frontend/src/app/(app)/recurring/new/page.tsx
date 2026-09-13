"use client";

import { FormEvent, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { PageHeader } from "@/components/PageHeader";
import { Button, ErrorBanner, Field, Input, Select } from "@/components/ui";
import { apiGet, apiPost, ApiRequestError } from "@/lib/api";
import { parseRupeesInput } from "@/lib/money";
import type { Category, Person } from "@/lib/types";

export default function NewRecurringPage() {
  const router = useRouter();
  const [name, setName] = useState("");
  const [amount, setAmount] = useState("");
  const [cadence, setCadence] = useState("monthly");
  const [nextDue, setNextDue] = useState("");
  const [categoryId, setCategoryId] = useState("");
  const [personId, setPersonId] = useState("");
  const [categories, setCategories] = useState<Category[]>([]);
  const [people, setPeople] = useState<Person[]>([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    Promise.all([
      apiGet<Category[]>("/api/v1/categories"),
      apiGet<Person[]>("/api/v1/people"),
    ])
      .then(([cats, ppl]) => {
        setCategories((cats.data || []).filter((c) => c.kind === "expense"));
        setPeople(ppl.data || []);
      })
      .catch(() => undefined);
  }, []);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    const amountPaise = parseRupeesInput(amount);
    if (!name.trim() || amountPaise === null || amountPaise <= 0) {
      setError("Name and amount are required.");
      return;
    }
    setLoading(true);
    setError("");
    try {
      await apiPost("/api/v1/recurring_expenses", {
        name: name.trim(),
        amount_paise: amountPaise,
        cadence,
        next_due_on: nextDue || undefined,
        category_id: categoryId || undefined,
        person_id: personId || undefined,
      });
      router.replace("/recurring");
    } catch (err) {
      setError(
        err instanceof ApiRequestError
          ? err.message
          : "Could not save recurring expense.",
      );
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <PageHeader title="Add recurring" backHref="/recurring" />
      <ErrorBanner message={error} />
      <form onSubmit={onSubmit} className="space-y-4">
        <Field label="Name">
          <Input
            required
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="House rent"
            autoFocus
          />
        </Field>
        <Field label="Amount (₹)">
          <Input
            inputMode="decimal"
            required
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            placeholder="15,000"
          />
        </Field>
        <Field label="Cadence">
          <Select value={cadence} onChange={(e) => setCadence(e.target.value)}>
            <option value="monthly">Monthly</option>
            <option value="weekly">Weekly</option>
            <option value="yearly">Yearly</option>
          </Select>
        </Field>
        <Field label="Next due">
          <Input
            type="date"
            value={nextDue}
            onChange={(e) => setNextDue(e.target.value)}
          />
        </Field>
        {categories.length > 0 ? (
          <Field label="Category">
            <Select
              value={categoryId}
              onChange={(e) => setCategoryId(e.target.value)}
            >
              <option value="">Optional</option>
              {categories.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </Select>
          </Field>
        ) : null}
        <Field label="Spent for">
          <Select value={personId} onChange={(e) => setPersonId(e.target.value)}>
            <option value="">Myself</option>
            {people.map((p) => (
              <option key={p.id} value={p.id}>
                {p.name}
              </option>
            ))}
          </Select>
        </Field>
        <Button type="submit" className="w-full" loading={loading}>
          Save
        </Button>
      </form>
    </div>
  );
}
