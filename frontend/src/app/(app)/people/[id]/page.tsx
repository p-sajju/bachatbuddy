"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { PageHeader } from "@/components/PageHeader";
import { EmptyState, StatTile, Surface } from "@/components/ui";
import { apiGet, ApiRequestError } from "@/lib/api";
import { formatINR } from "@/lib/money";
import type { Expense, Person } from "@/lib/types";

type PersonSummary = Person & {
  expenses?: Expense[];
  by_category?: { name: string; amount_paise: number }[];
};

export default function PersonDetailPage() {
  const { id } = useParams<{ id: string }>();
  const [data, setData] = useState<PersonSummary | null>(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    apiGet<PersonSummary>(`/api/v1/people/${id}/summary`)
      .then((res) => setData(res.data))
      .catch(async (err) => {
        try {
          const fallback = await apiGet<Person>(`/api/v1/people/${id}`);
          setData(fallback.data);
        } catch {
          setError(
            err instanceof ApiRequestError
              ? err.message
              : "Could not load person.",
          );
        }
      })
      .finally(() => setLoading(false));
  }, [id]);

  return (
    <div>
      <PageHeader
        title={data?.name || "Person"}
        subtitle={data?.relationship || undefined}
        backHref="/people"
      />
      {loading ? (
        <div className="flex justify-center py-16">
          <div className="h-8 w-8 animate-spin rounded-full border-2 border-[var(--bb-forest)] border-t-transparent" />
        </div>
      ) : error || !data ? (
        <EmptyState title="Not found" body={error} />
      ) : (
        <div className="space-y-4">
          <StatTile
            label="Total spent for them"
            value={formatINR(data.total_spent_paise || 0)}
          />
          {data.by_category && data.by_category.length > 0 ? (
            <Surface>
              <h2 className="mb-3 font-semibold">By category</h2>
              <ul className="space-y-2 text-sm">
                {data.by_category.map((row) => (
                  <li key={row.name} className="flex justify-between gap-3">
                    <span>{row.name}</span>
                    <span className="tabular-nums font-medium">
                      {formatINR(row.amount_paise)}
                    </span>
                  </li>
                ))}
              </ul>
            </Surface>
          ) : null}
          {data.expenses && data.expenses.length > 0 ? (
            <Surface>
              <h2 className="mb-3 font-semibold">Recent expenses</h2>
              <ul className="space-y-2 text-sm">
                {data.expenses.slice(0, 10).map((e) => (
                  <li key={e.id} className="flex justify-between gap-3">
                    <span>
                      {e.spent_on}
                      {e.category?.name ? ` · ${e.category.name}` : ""}
                    </span>
                    <span className="tabular-nums font-medium">
                      {formatINR(e.amount_paise)}
                    </span>
                  </li>
                ))}
              </ul>
            </Surface>
          ) : (
            <p className="text-sm text-[var(--bb-muted)]">
              No expenses tagged for this person yet.
            </p>
          )}
        </div>
      )}
    </div>
  );
}
