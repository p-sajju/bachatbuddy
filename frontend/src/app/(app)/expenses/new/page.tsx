"use client";

import { FormEvent, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { PageHeader } from "@/components/PageHeader";
import { Button, ErrorBanner, Field, Input, Select, TextArea } from "@/components/ui";
import { apiGet, apiPost, ApiRequestError } from "@/lib/api";
import { parseRupeesInput } from "@/lib/money";
import type { Category, PaymentSource, Person } from "@/lib/types";

export default function NewExpensePage() {
  const router = useRouter();
  const [amount, setAmount] = useState("");
  const [spentOn, setSpentOn] = useState(
    () => new Date().toISOString().slice(0, 10),
  );
  const [categoryId, setCategoryId] = useState("");
  const [personId, setPersonId] = useState("");
  const [paymentSourceId, setPaymentSourceId] = useState("");
  const [note, setNote] = useState("");
  const [categories, setCategories] = useState<Category[]>([]);
  const [people, setPeople] = useState<Person[]>([]);
  const [paymentSources, setPaymentSources] = useState<PaymentSource[]>([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    Promise.all([
      apiGet<Category[]>("/api/v1/categories"),
      apiGet<Person[]>("/api/v1/people"),
      apiGet<PaymentSource[]>("/api/v1/payment_sources"),
    ])
      .then(([cats, ppl, sources]) => {
        const expenseCats = (cats.data || []).filter((c) => c.kind === "expense");
        setCategories(expenseCats);
        if (expenseCats[0]) setCategoryId(expenseCats[0].id);
        setPeople(ppl.data || []);
        setPaymentSources(sources.data || []);
      })
      .catch(() => undefined);
  }, []);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setError("");
    const amountPaise = parseRupeesInput(amount);
    if (amountPaise === null || amountPaise <= 0) {
      setError("Enter a valid amount.");
      return;
    }
    setLoading(true);
    try {
      await apiPost("/api/v1/expenses", {
        amount_paise: amountPaise,
        spent_on: spentOn,
        category_id: categoryId || undefined,
        person_id: personId || undefined,
        payment_source_id: paymentSourceId || undefined,
        note: note || undefined,
      });
      router.replace("/transactions");
    } catch (err) {
      setError(
        err instanceof ApiRequestError ? err.message : "Could not save expense.",
      );
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <PageHeader
        title="Add expense"
        subtitle="Fast path — keep it simple"
        backHref="/add"
      />
      <ErrorBanner message={error} />
      <form onSubmit={onSubmit} className="space-y-4">
        <Field label="Amount (₹)">
          <Input
            inputMode="decimal"
            required
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            placeholder="250"
            autoFocus
          />
        </Field>
        <Field label="Category">
          <Select
            value={categoryId}
            onChange={(e) => setCategoryId(e.target.value)}
            required={categories.length > 0}
          >
            {categories.length === 0 ? (
              <option value="">Loading…</option>
            ) : (
              categories.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))
            )}
          </Select>
        </Field>
        <Field label="Spent for" hint="Leave blank for Myself">
          <Select value={personId} onChange={(e) => setPersonId(e.target.value)}>
            <option value="">Myself</option>
            {people.map((p) => (
              <option key={p.id} value={p.id}>
                {p.name}
              </option>
            ))}
          </Select>
        </Field>
        <Field label="Date">
          <Input
            type="date"
            required
            value={spentOn}
            onChange={(e) => setSpentOn(e.target.value)}
          />
        </Field>
        {paymentSources.length > 0 ? (
          <Field label="Paid via">
            <Select
              value={paymentSourceId}
              onChange={(e) => setPaymentSourceId(e.target.value)}
            >
              <option value="">Optional</option>
              {paymentSources.map((p) => (
                <option key={p.id} value={p.id}>
                  {p.name}
                </option>
              ))}
            </Select>
          </Field>
        ) : null}
        <Field label="Note">
          <TextArea
            rows={2}
            value={note}
            onChange={(e) => setNote(e.target.value)}
            placeholder="Optional"
          />
        </Field>
        <Button type="submit" className="w-full" loading={loading}>
          Save expense
        </Button>
      </form>
    </div>
  );
}
