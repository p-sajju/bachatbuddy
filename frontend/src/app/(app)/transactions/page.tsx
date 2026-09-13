"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { PageHeader } from "@/components/PageHeader";
import { EmptyState, Surface } from "@/components/ui";
import { apiGet, ApiRequestError } from "@/lib/api";
import { formatINR } from "@/lib/money";
import type { Expense, Income, TransactionItem } from "@/lib/types";

export default function TransactionsPage() {
  const [items, setItems] = useState<TransactionItem[]>([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const [incomes, expenses] = await Promise.all([
          apiGet<Income[]>("/api/v1/incomes"),
          apiGet<Expense[]>("/api/v1/expenses"),
        ]);
        const merged: TransactionItem[] = [
          ...(incomes.data || []).map((i) => ({ ...i, type: "income" as const })),
          ...(expenses.data || []).map((e) => ({
            ...e,
            type: "expense" as const,
          })),
        ];
        merged.sort((a, b) => {
          const da = a.type === "income" ? a.received_on : a.spent_on;
          const db = b.type === "income" ? b.received_on : b.spent_on;
          return db.localeCompare(da);
        });
        if (!cancelled) setItems(merged);
      } catch (err) {
        if (!cancelled) {
          setError(
            err instanceof ApiRequestError
              ? err.message
              : "Could not load transactions.",
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

  return (
    <div>
      <PageHeader
        title="Transactions"
        subtitle="Income and expenses in one place"
        action={
          <Link
            href="/add"
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
          title="No transactions yet"
          body="Add income or a quick expense to get started."
          action={
            <Link href="/add" className="text-sm font-semibold text-[var(--bb-forest)]">
              Add now
            </Link>
          }
        />
      ) : (
        <Surface className="!p-0 overflow-hidden">
          <ul className="divide-y divide-[var(--bb-border)]">
            {items.map((item) => {
              const isIncome = item.type === "income";
              const date = isIncome ? item.received_on : item.spent_on;
              const label = isIncome
                ? item.source || item.note || "Income"
                : item.category?.name || item.note || "Expense";
              const sub = isIncome
                ? item.note
                : item.person?.name
                  ? `For ${item.person.name}`
                  : item.note;
              return (
                <li key={`${item.type}-${item.id}`}>
                  <Link
                    href={`/transactions/${item.type}-${item.id}`}
                    className="flex items-center justify-between gap-3 px-4 py-3.5 hover:bg-black/[0.02]"
                  >
                    <div className="min-w-0">
                      <p className="truncate font-medium text-[var(--bb-ink)]">
                        {label}
                      </p>
                      <p className="truncate text-xs text-[var(--bb-muted)]">
                        {date}
                        {sub ? ` · ${sub}` : ""}
                      </p>
                    </div>
                    <p
                      className={`shrink-0 tabular-nums font-semibold ${
                        isIncome ? "text-[var(--bb-leaf)]" : "text-[var(--bb-ink)]"
                      }`}
                    >
                      {isIncome ? "+" : "−"}
                      {formatINR(item.amount_paise)}
                    </p>
                  </Link>
                </li>
              );
            })}
          </ul>
        </Surface>
      )}
    </div>
  );
}
