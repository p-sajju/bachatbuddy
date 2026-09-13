"use client";

import Link from "next/link";
import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";
import { BrandMark } from "@/components/PageHeader";
import { Button, ErrorBanner, Field, Input, Surface } from "@/components/ui";
import { apiPost, ApiRequestError } from "@/lib/api";
import { setTokens } from "@/lib/auth";
import type { AuthPayload } from "@/lib/types";

export default function SignupPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [name, setName] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      const res = await apiPost<AuthPayload>(
        "/api/v1/auth/signup",
        { email, password, name: name || undefined },
        { auth: false },
      );
      setTokens({
        accessToken: res.data.access_token,
        refreshToken: res.data.refresh_token,
      });
      const needsOnboarding = res.data.user.onboarding_completed !== true;
      router.replace(needsOnboarding ? "/onboarding" : "/home");
    } catch (err) {
      setError(
        err instanceof ApiRequestError
          ? err.message
          : "Could not create account.",
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
        <h1 className="mb-4 text-lg font-semibold text-[var(--bb-ink)]">
          Create your account
        </h1>
        <ErrorBanner message={error} />
        <form onSubmit={onSubmit} className="space-y-4">
          <Field label="Name" hint="You can finish this in onboarding">
            <Input
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Your name"
              autoComplete="name"
            />
          </Field>
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
          <Field label="Password" hint="At least 8 characters">
            <Input
              type="password"
              autoComplete="new-password"
              required
              minLength={8}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
            />
          </Field>
          <Button type="submit" className="w-full" loading={loading}>
            Sign up
          </Button>
        </form>
        <p className="mt-4 text-center text-sm text-[var(--bb-muted)]">
          Already have an account?{" "}
          <Link
            href="/login"
            className="font-semibold text-[var(--bb-forest)] underline-offset-2 hover:underline"
          >
            Sign in
          </Link>
        </p>
      </Surface>
    </div>
  );
}
