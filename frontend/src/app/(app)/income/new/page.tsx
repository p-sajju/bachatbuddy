"use client";

import { FormEvent, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { PageHeader } from "@/components/PageHeader";
import { Button, ErrorBanner, Field, Input, Select, TextArea } from "@/components/ui";
import { apiGet, apiPost, ApiRequestError } from "@/lib/api";
import { parseRupeesInput } from "@/lib/money";
import type { Category, PaymentSource } from "@/lib/types";

export default function NewIncomePage() {
  const router = useRouter();
  const [amount, setAmount] = useState("");
  const [receivedOn, setReceivedOn] = useState(
    () => new Date().toISOString().slice(0, 10),
  );
  const [source, setSource] = useState("Salary");
  const [note, setNote] = useState("");
  const [categoryId, setCategoryId] = useState("");
  const [paymentSourceId, setPaymentSourceId] = useState("");
  const [categories, setCategories] = useState<Category[]>([]);
  const [paymentSources, setPaymentSources] = useState<PaymentSource[]>([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    Promise.all([
      apiGet<Category[]>("/api/v1/categories"),
      apiGet<PaymentSource[]>("/api/v1/payment_sources"),
    ])
      .then(([cats, sources]) => {
        setCategories((cats.data || []).filter((c) => c.kind === "income"));
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
      await apiPost("/api/v1/incomes", {
        amount_paise: amountPaise,
        received_on: receivedOn,
        source,
        note: note || undefined,
        category_id: categoryId || undefined,
        payment_source_id: paymentSourceId || undefined,
      });
      router.replace("/transactions");
    } catch (err) {
      setError(
        err instanceof ApiRequestError ? err.message : "Could not save income.",
      );
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <PageHeader title="Add income" backHref="/add" />
      <ErrorBanner message={error} />
      <form onSubmit={onSubmit} className="space-y-4">
        <Field label="Amount (₹)">
          <Input
            inputMode="decimal"
            required
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            placeholder="50,000"
            autoFocus
          />
        </Field>
        <Field label="Received on">
          <Input
            type="date"
            required
            value={receivedOn}
            onChange={(e) => setReceivedOn(e.target.value)}
          />
        </Field>
        <Field label="Source">
          <Input
            value={source}
            onChange={(e) => setSource(e.target.value)}
            placeholder="Salary"
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
        {paymentSources.length > 0 ? (
          <Field label="Payment source">
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
          />
        </Field>
        <Button type="submit" className="w-full" loading={loading}>
          Save income
        </Button>
      </form>
    </div>
  );
}
