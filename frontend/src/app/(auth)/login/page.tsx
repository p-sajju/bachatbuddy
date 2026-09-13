"use client";

import Link from "next/link";
import { FormEvent, Suspense, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { BrandMark } from "@/components/PageHeader";
import { Button, ErrorBanner, Field, Input, Surface } from "@/components/ui";
import { apiPost, ApiRequestError } from "@/lib/api";
import { setTokens } from "@/lib/auth";
import type { AuthPayload } from "@/lib/types";

function LoginForm() {
  const router = useRouter();
  const search = useSearchParams();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      const res = await apiPost<AuthPayload>(
        "/api/v1/auth/login",
        { email, password },
        { auth: false },
      );
      setTokens({
        accessToken: res.data.access_token,
        refreshToken: res.data.refresh_token,
      });
      const next = search.get("next") || "/home";
      const needsOnboarding = res.data.user.onboarding_completed !== true;
      router.replace(needsOnboarding ? "/onboarding" : next);
    } catch (err) {
      setError(
        err instanceof ApiRequestError
          ? err.message
          : "Could not sign in. Try again.",
      );
    } finally {
      setLoading(false);
    }
  }

  return (
    <Surface className="bb-fade-up-delay">
      <h1 className="mb-4 text-lg font-semibold text-[var(--bb-ink)]">
        Welcome back
      </h1>
      <ErrorBanner message={error} />
      <form onSubmit={onSubmit} className="space-y-4">
        <Field label="Email">
          <Input
            type="email"
            autoComplete="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="you@email.com"
          />
        </Field>
        <Field label="Password">
          <Input
            type="password"
            autoComplete="current-password"
            required
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="••••••••"
          />
        </Field>
        <Button type="submit" className="w-full" loading={loading}>
          Sign in
        </Button>
      </form>
      <p className="mt-4 text-center text-sm text-[var(--bb-muted)]">
        New here?{" "}
        <Link
          href="/signup"
          className="font-semibold text-[var(--bb-forest)] underline-offset-2 hover:underline"
        >
          Create an account
        </Link>
      </p>
    </Surface>
  );
}

export default function LoginPage() {
  return (
    <div className="bb-auth-shell">
      <div className="mb-8 bb-fade-up">
        <BrandMark size="lg" />
      </div>
      <Suspense
        fallback={
          <div className="flex justify-center py-10">
            <div className="h-8 w-8 animate-spin rounded-full border-2 border-[var(--bb-forest)] border-t-transparent" />
          </div>
        }
      >
        <LoginForm />
      </Suspense>
    </div>
  );
}
