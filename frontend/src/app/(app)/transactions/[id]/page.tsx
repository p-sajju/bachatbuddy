"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { PageHeader } from "@/components/PageHeader";
import { EmptyState, Surface } from "@/components/ui";
import { apiGet, ApiRequestError } from "@/lib/api";
import { formatINR } from "@/lib/money";
import type { Expense, Income } from "@/lib/types";

export default function TransactionDetailPage() {
  const params = useParams<{ id: string }>();
  const raw = params.id || "";
  const [type, id] = raw.includes("-")
    ? [raw.slice(0, raw.indexOf("-")), raw.slice(raw.indexOf("-") + 1)]
    : ["", ""];
  const [item, setItem] = useState<Income | Expense | null>(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!id || (type !== "income" && type !== "expense")) {
      setError("Invalid transaction.");
      setLoading(false);
      return;
    }
    let cancelled = false;
    (async () => {
      try {
        const path =
          type === "income" ? `/api/v1/incomes/${id}` : `/api/v1/expenses/${id}`;
        const res = await apiGet<Income | Expense>(path);
        if (!cancelled) setItem(res.data);
      } catch (err) {
        if (!cancelled) {
          setError(
            err instanceof ApiRequestError
              ? err.message
              : "Could not load transaction.",
          );
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [id, type]);

  const isIncome = type === "income";

  return (
    <div>
      <PageHeader
        title={isIncome ? "Income" : "Expense"}
        backHref="/transactions"
      />
      {loading ? (
        <div className="flex justify-center py-16">
          <div className="h-8 w-8 animate-spin rounded-full border-2 border-[var(--bb-forest)] border-t-transparent" />
        </div>
      ) : error || !item ? (
        <EmptyState title="Not found" body={error || "Transaction missing."} />
      ) : (
        <Surface className="space-y-3">
          <p
            className={`font-[family-name:var(--font-display)] text-3xl font-semibold tabular-nums ${
              isIncome ? "text-[var(--bb-leaf)]" : "text-[var(--bb-ink)]"
            }`}
          >
            {isIncome ? "+" : "−"}
            {formatINR(item.amount_paise)}
          </p>
          <dl className="space-y-2 text-sm">
            <Row
              label="Date"
              value={
                isIncome
                  ? (item as Income).received_on
                  : (item as Expense).spent_on
              }
            />
            {isIncome ? (
              <Row label="Source" value={(item as Income).source || "—"} />
            ) : (
              <>
                <Row
                  label="Category"
                  value={(item as Expense).category?.name || "—"}
                />
                <Row
                  label="Spent for"
                  value={(item as Expense).person?.name || "Myself"}
                />
              </>
            )}
            <Row
              label="Payment"
              value={item.payment_source?.name || "—"}
            />
            <Row label="Note" value={item.note || "—"} />
          </dl>
        </Surface>
      )}
    </div>
  );
}

function Row({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex justify-between gap-4 border-b border-[var(--bb-border)] py-2 last:border-0">
      <dt className="text-[var(--bb-muted)]">{label}</dt>
      <dd className="text-right font-medium text-[var(--bb-ink)]">{value}</dd>
    </div>
  );
}
