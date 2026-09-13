"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { PageHeader } from "@/components/PageHeader";
import { EmptyState, Surface } from "@/components/ui";
import { apiGet, ApiRequestError } from "@/lib/api";
import { formatINR } from "@/lib/money";
import type { RecurringExpense } from "@/lib/types";

export default function RecurringPage() {
  const [items, setItems] = useState<RecurringExpense[]>([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    apiGet<RecurringExpense[]>("/api/v1/recurring_expenses")
      .then((res) => setItems(res.data || []))
      .catch((err) =>
        setError(
          err instanceof ApiRequestError
            ? err.message
            : "Could not load recurring expenses.",
        ),
      )
      .finally(() => setLoading(false));
  }, []);

  return (
    <div>
      <PageHeader
        title="Recurring expenses"
        subtitle="Rent, EMIs, subscriptions"
        backHref="/more"
        action={
          <Link
            href="/recurring/new"
            className="rounded-xl bg-[var(--bb-forest)] px-3 py-2 text-sm font-semibold text-white"
          >
            Add
          </Link>
        }
      />
      {loading ? (
        <div className="flex justify-center py-16">
          <div className="h-8 w-8 animate-spin rounded-full border-2 border-[var(--bb-forest)] border-t-transparent" />
        </div>
      ) : error ? (
        <EmptyState title="Unable to load" body={error} />
      ) : items.length === 0 ? (
        <EmptyState
          title="No recurring items"
          body="Add rent or EMI so Safe to Spend stays accurate."
          action={
            <Link href="/recurring/new" className="text-sm font-semibold text-[var(--bb-forest)]">
              Add recurring
            </Link>
          }
        />
      ) : (
        <Surface className="!p-0 overflow-hidden">
          <ul className="divide-y divide-[var(--bb-border)]">
            {items.map((item) => (
              <li key={item.id} className="flex items-center justify-between gap-3 px-4 py-3.5">
                <div>
                  <p className="font-medium">{item.name}</p>
                  <p className="text-xs text-[var(--bb-muted)]">
                    {item.cadence}
                    {item.next_due_on ? ` · next ${item.next_due_on}` : ""}
                    {item.person?.name ? ` · ${item.person.name}` : ""}
                  </p>
                </div>
                <span className="tabular-nums font-semibold">
                  {formatINR(item.amount_paise)}
                </span>
              </li>
            ))}
          </ul>
        </Surface>
      )}
    </div>
  );
}
