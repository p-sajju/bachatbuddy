"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { PageHeader } from "@/components/PageHeader";
import { EmptyState, Surface } from "@/components/ui";
import { apiGet, ApiRequestError } from "@/lib/api";
import { formatINR } from "@/lib/money";
import type { Person } from "@/lib/types";

export default function PeoplePage() {
  const [people, setPeople] = useState<Person[]>([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    apiGet<Person[]>("/api/v1/people")
      .then((res) => setPeople(res.data || []))
      .catch((err) =>
        setError(
          err instanceof ApiRequestError
            ? err.message
            : "Could not load people.",
        ),
      )
      .finally(() => setLoading(false));
  }, []);

  return (
    <div>
      <PageHeader
        title="People"
        subtitle="Track who you spend for"
        backHref="/more"
        action={
          <Link
            href="/people/new"
            className="rounded-xl bg-[var(--bb-forest)] px-3 py-2 text-sm font-semibold text-white"
          >
            Add
          </Link>
        }
      />
      {loading ? (
        <Spinner />
      ) : error ? (
        <EmptyState title="Unable to load" body={error} />
      ) : people.length === 0 ? (
        <EmptyState
          title="No people yet"
          body="Add family members you often spend for."
          action={
            <Link href="/people/new" className="text-sm font-semibold text-[var(--bb-forest)]">
              Add person
            </Link>
          }
        />
      ) : (
        <Surface className="!p-0 overflow-hidden">
          <ul className="divide-y divide-[var(--bb-border)]">
            {people.map((p) => (
              <li key={p.id}>
                <Link
                  href={`/people/${p.id}`}
                  className="flex items-center justify-between gap-3 px-4 py-3.5"
                >
                  <div>
                    <p className="font-medium">{p.name}</p>
                    {p.relationship ? (
                      <p className="text-xs text-[var(--bb-muted)]">
                        {p.relationship}
                      </p>
                    ) : null}
                  </div>
                  <span className="tabular-nums text-sm font-semibold">
                    {formatINR(p.total_spent_paise || 0, { showPaise: false })}
                  </span>
                </Link>
              </li>
            ))}
          </ul>
        </Surface>
      )}
    </div>
  );
}

function Spinner() {
  return (
    <div className="flex justify-center py-16">
      <div className="h-8 w-8 animate-spin rounded-full border-2 border-[var(--bb-forest)] border-t-transparent" />
    </div>
  );
}
