"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { PageHeader } from "@/components/PageHeader";
import { Disclaimer, EmptyState, Surface } from "@/components/ui";
import { apiGet, ApiRequestError } from "@/lib/api";
import { formatINR } from "@/lib/money";
import type { MoneyLock } from "@/lib/types";

export default function LocksPage() {
  const [locks, setLocks] = useState<MoneyLock[]>([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    apiGet<MoneyLock[]>("/api/v1/money_locks")
      .then((res) => setLocks(res.data || []))
      .catch((err) =>
        setError(
          err instanceof ApiRequestError ? err.message : "Could not load locks.",
        ),
      )
      .finally(() => setLoading(false));
  }, []);

  return (
    <div>
      <PageHeader
        title="Money Locks"
        subtitle="Virtual protection for your savings"
        backHref="/more"
        action={
          <Link
            href="/locks/new"
            className="rounded-xl bg-[var(--bb-forest)] px-3 py-2 text-sm font-semibold text-white"
          >
            Lock
          </Link>
        }
      />
      <Disclaimer>
        Money Lock is behavioural only — BachatBuddy never holds your bank
        balance or UPI funds.
      </Disclaimer>
      <div className="mt-4">
        {loading ? (
          <div className="flex justify-center py-16">
            <div className="h-8 w-8 animate-spin rounded-full border-2 border-[var(--bb-forest)] border-t-transparent" />
          </div>
        ) : error ? (
          <EmptyState title="Unable to load" body={error} />
        ) : locks.length === 0 ? (
          <EmptyState
            title="Nothing locked yet"
            body="Lock an amount toward a goal so impulse spends feel harder."
            action={
              <Link href="/locks/new" className="text-sm font-semibold text-[var(--bb-forest)]">
                Create lock
              </Link>
            }
          />
        ) : (
          <div className="space-y-3">
            {locks.map((lock) => (
              <Link key={lock.id} href={`/locks/${lock.id}`}>
                <Surface className="mb-3 flex items-center justify-between gap-3">
                  <div>
                    <p className="font-semibold">{lock.name}</p>
                    <p className="text-xs capitalize text-[var(--bb-muted)]">
                      {lock.status.replace(/_/g, " ")}
                    </p>
                  </div>
                  <p className="tabular-nums font-semibold text-[var(--bb-forest)]">
                    {formatINR(lock.amount_paise)}
                  </p>
                </Surface>
              </Link>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
