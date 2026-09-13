"use client";

import { useEffect, useState } from "react";
import { PageHeader } from "@/components/PageHeader";
import { EmptyState, StatTile, Surface } from "@/components/ui";
import { apiGet, ApiRequestError } from "@/lib/api";
import { formatINR } from "@/lib/money";
import type { ReportSummary } from "@/lib/types";

export default function ReportsPage() {
  const [report, setReport] = useState<ReportSummary | null>(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    apiGet<ReportSummary>("/api/v1/reports/monthly")
      .then((res) => setReport(res.data))
      .catch((err) => {
        setError(
          err instanceof ApiRequestError
            ? err.message
            : "Could not load reports.",
        );
      })
      .finally(() => setLoading(false));
  }, []);

  return (
    <div>
      <PageHeader
        title="Reports"
        subtitle="This month at a glance"
        backHref="/more"
      />
      {loading ? (
        <div className="flex justify-center py-16">
          <div className="h-8 w-8 animate-spin rounded-full border-2 border-[var(--bb-forest)] border-t-transparent" />
        </div>
      ) : error || !report ? (
        <EmptyState title="No report yet" body={error || "Add transactions first."} />
      ) : (
        <div className="space-y-4">
          <p className="text-sm text-[var(--bb-muted)]">
            {report.period.label ||
              `${report.period.start} → ${report.period.end}`}
          </p>
          <div className="grid grid-cols-2 gap-3">
            <StatTile label="Income" value={formatINR(report.income_paise)} tone="good" />
            <StatTile
              label="Expenses"
              value={formatINR(report.expenses_paise)}
              tone="warn"
            />
          </div>
          <StatTile
            label="Net"
            value={formatINR(report.net_paise, { signed: true })}
            tone={report.net_paise >= 0 ? "good" : "warn"}
          />

          {report.by_category && report.by_category.length > 0 ? (
            <Surface>
              <h2 className="mb-3 font-semibold">By category</h2>
              <ul className="space-y-2 text-sm">
                {report.by_category.map((row) => (
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

          {report.by_person && report.by_person.length > 0 ? (
            <Surface>
              <h2 className="mb-3 font-semibold">By person</h2>
              <ul className="space-y-2 text-sm">
                {report.by_person.map((row) => (
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
        </div>
      )}
    </div>
  );
}
