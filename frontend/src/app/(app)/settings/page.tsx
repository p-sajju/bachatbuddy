"use client";

import { FormEvent, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { PageHeader } from "@/components/PageHeader";
import { Button, ErrorBanner, Field, Input, Surface } from "@/components/ui";
import { apiGet, apiPatch, apiPost, ApiRequestError } from "@/lib/api";
import { clearTokens } from "@/lib/auth";
import type { User } from "@/lib/types";

export default function SettingsPage() {
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  const [name, setName] = useState("");
  const [timezone, setTimezone] = useState("Asia/Kolkata");
  const [error, setError] = useState("");
  const [saved, setSaved] = useState(false);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    apiGet<User>("/api/v1/me")
      .then((res) => {
        setUser(res.data);
        setName(res.data.name || "");
        setTimezone(res.data.timezone || "Asia/Kolkata");
      })
      .catch((err) =>
        setError(
          err instanceof ApiRequestError ? err.message : "Could not load profile.",
        ),
      )
      .finally(() => setLoading(false));
  }, []);

  async function onSave(e: FormEvent) {
    e.preventDefault();
    setSaving(true);
    setError("");
    setSaved(false);
    try {
      const res = await apiPatch<User>("/api/v1/settings", {
        name: name.trim(),
        timezone,
      }).catch(() =>
        apiPatch<User>("/api/v1/me", { name: name.trim(), timezone }),
      );
      setUser(res.data);
      setSaved(true);
    } catch (err) {
      setError(
        err instanceof ApiRequestError ? err.message : "Could not save settings.",
      );
    } finally {
      setSaving(false);
    }
  }

  async function onLogout() {
    try {
      await apiPost("/api/v1/auth/logout", {}, { idempotency: false });
    } catch {
      // clear locally anyway
    }
    clearTokens();
    router.replace("/login");
  }

  return (
    <div>
      <PageHeader title="Settings" backHref="/more" />
      {loading ? (
        <div className="flex justify-center py-16">
          <div className="h-8 w-8 animate-spin rounded-full border-2 border-[var(--bb-forest)] border-t-transparent" />
        </div>
      ) : (
        <div className="space-y-4">
          <Surface>
            <p className="text-sm text-[var(--bb-muted)]">Signed in as</p>
            <p className="font-medium">{user?.email}</p>
          </Surface>
          <ErrorBanner message={error} />
          {saved ? (
            <p className="text-sm text-[var(--bb-leaf)]">Settings saved.</p>
          ) : null}
          <form onSubmit={onSave} className="space-y-4">
            <Field label="Name">
              <Input
                value={name}
                onChange={(e) => setName(e.target.value)}
                required
              />
            </Field>
            <Field label="Timezone">
              <Input
                value={timezone}
                onChange={(e) => setTimezone(e.target.value)}
                placeholder="Asia/Kolkata"
              />
            </Field>
            <Button type="submit" className="w-full" loading={saving}>
              Save settings
            </Button>
          </form>
          <Button variant="secondary" className="w-full" onClick={onLogout}>
            Sign out
          </Button>
        </div>
      )}
    </div>
  );
}
