"use client";

import { FormEvent, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { BrandMark } from "@/components/PageHeader";
import { Button, ErrorBanner, Field, Input, Surface } from "@/components/ui";
import { apiGet, apiPatch, ApiRequestError } from "@/lib/api";
import { isAuthenticated } from "@/lib/auth";
import { parseRupeesInput } from "@/lib/money";
import type { User } from "@/lib/types";

export default function OnboardingPage() {
  const router = useRouter();
  const [displayName, setDisplayName] = useState("");
  const [salary, setSalary] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!isAuthenticated()) {
      router.replace("/login");
      return;
    }
    apiGet<User>("/api/v1/me")
      .then((res) => {
        if (res.data.onboarding_completed === true) {
          router.replace("/home");
          return;
        }
        const full =
          res.data.name ||
          [res.data.first_name, res.data.last_name].filter(Boolean).join(" ");
        if (full) setDisplayName(full);
      })
      .catch(() => undefined);
  }, [router]);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setError("");
    const amountPaise = parseRupeesInput(salary);
    if (amountPaise === null || amountPaise <= 0) {
      setError("Enter a valid first salary amount.");
      return;
    }
    setLoading(true);
    try {
      await apiPatch<User>("/api/v1/me", {
        onboarding_completed: true,
        first_income: {
          amount_paise: amountPaise,
          received_on: new Date().toISOString().slice(0, 10),
          source: "Salary",
          note: "First salary (onboarding)",
        },
      });
      router.replace("/home");
    } catch (err) {
      setError(
        err instanceof ApiRequestError
          ? err.message
          : "Could not finish onboarding.",
      );
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="bb-auth-shell">
      <div className="mb-8 bb-fade-up">
        <BrandMark size="lg" />
      </div>
      <Surface className="bb-fade-up-delay">
        <h1 className="font-[family-name:var(--font-display)] text-2xl font-semibold text-[var(--bb-ink)]">
          Let&apos;s set your baseline
        </h1>
        <p className="mt-1 mb-4 text-sm text-[var(--bb-muted)]">
          {displayName
            ? `Welcome, ${displayName}. Add your first salary so BachatBuddy can calculate Safe to Spend.`
            : "Add your first salary so BachatBuddy can calculate Safe to Spend."}
        </p>
        <ErrorBanner message={error} />
        <form onSubmit={onSubmit} className="space-y-4">
          <Field
            label="First salary (₹)"
            hint="Enter rupees — we’ll store it as paise securely."
          >
            <Input
              inputMode="decimal"
              required
              value={salary}
              onChange={(e) => setSalary(e.target.value)}
              placeholder="50,000"
              autoFocus
            />
          </Field>
          <Button type="submit" className="w-full" loading={loading}>
            Continue to dashboard
          </Button>
        </form>
      </Surface>
    </div>
  );
}
