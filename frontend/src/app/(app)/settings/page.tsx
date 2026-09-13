"use client";

import { FormEvent, useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { PageHeader } from "@/components/PageHeader";
import { PhoneField } from "@/components/PhoneField";
import { ProfileAvatar } from "@/components/ProfileAvatar";
import { Button, ErrorBanner, Field, Input, Surface } from "@/components/ui";
import { apiDelete, apiGet, apiPatch, apiPost, apiUpload, ApiRequestError } from "@/lib/api";
import { clearTokens } from "@/lib/auth";
import {
  DEFAULT_COUNTRY_CODE,
  buildPhoneNumber,
  splitPhoneNumber,
} from "@/lib/phone";
import type { User } from "@/lib/types";

export default function SettingsPage() {
  const router = useRouter();
  const fileRef = useRef<HTMLInputElement>(null);
  const [user, setUser] = useState<User | null>(null);
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [countryCode, setCountryCode] = useState<string>(DEFAULT_COUNTRY_CODE);
  const [localPhone, setLocalPhone] = useState("");
  const [timezone, setTimezone] = useState("Asia/Kolkata");
  const [error, setError] = useState("");
  const [saved, setSaved] = useState(false);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState(false);

  useEffect(() => {
    apiGet<User>("/api/v1/me")
      .then((res) => {
        setUser(res.data);
        setFirstName(res.data.first_name || "");
        setLastName(res.data.last_name || "");
        const split = splitPhoneNumber(res.data.phone_number);
        setCountryCode(split.countryCode);
        setLocalPhone(split.localNumber);
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
    if (localPhone.length !== 10) {
      setError("Enter a valid 10-digit Indian mobile number.");
      setSaving(false);
      return;
    }
    try {
      const payload = {
        first_name: firstName.trim(),
        last_name: lastName.trim(),
        phone_number: buildPhoneNumber(countryCode, localPhone),
        timezone,
      };
      const res = await apiPatch<User>("/api/v1/settings", payload).catch(() =>
        apiPatch<User>("/api/v1/me", payload),
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

  async function onPickPhoto(file: File | null) {
    if (!file) return;
    if (!file.type.startsWith("image/")) {
      setError("Please choose an image file.");
      return;
    }
    if (file.size > 5 * 1024 * 1024) {
      setError("Photo must be under 5 MB.");
      return;
    }
    setUploading(true);
    setError("");
    try {
      const form = new FormData();
      form.append("avatar", file);
      const res = await apiUpload<User>("/api/v1/me/avatar", form, "POST");
      setUser(res.data);
      setSaved(true);
    } catch (err) {
      setError(
        err instanceof ApiRequestError ? err.message : "Could not upload photo.",
      );
    } finally {
      setUploading(false);
      if (fileRef.current) fileRef.current.value = "";
    }
  }

  async function onRemovePhoto() {
    setUploading(true);
    setError("");
    try {
      const res = await apiDelete<User>("/api/v1/me/avatar");
      setUser(res.data);
    } catch (err) {
      setError(
        err instanceof ApiRequestError ? err.message : "Could not remove photo.",
      );
    } finally {
      setUploading(false);
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
            <div className="flex items-center gap-4">
              <ProfileAvatar
                firstName={firstName || user?.first_name}
                lastName={lastName || user?.last_name}
                name={user?.name}
                avatarUrl={user?.avatar_url}
                initials={user?.initials}
                href={undefined}
                size="lg"
              />
              <div className="min-w-0 flex-1">
                <p className="text-sm text-[var(--bb-muted)]">Signed in as</p>
                <p className="truncate font-medium">{user?.email}</p>
                <div className="mt-2 flex flex-wrap gap-2">
                  <Button
                    type="button"
                    variant="secondary"
                    className="!px-3 !py-2 text-sm"
                    loading={uploading}
                    onClick={() => fileRef.current?.click()}
                  >
                    {user?.avatar_url ? "Change photo" : "Add photo"}
                  </Button>
                  {user?.avatar_url ? (
                    <Button
                      type="button"
                      variant="ghost"
                      className="!px-3 !py-2 text-sm"
                      disabled={uploading}
                      onClick={onRemovePhoto}
                    >
                      Remove
                    </Button>
                  ) : null}
                </div>
                <input
                  ref={fileRef}
                  type="file"
                  accept="image/*"
                  className="hidden"
                  onChange={(e) => onPickPhoto(e.target.files?.[0] || null)}
                />
              </div>
            </div>
          </Surface>
          <ErrorBanner message={error} />
          {saved ? (
            <p className="text-sm text-[var(--bb-leaf)]">Settings saved.</p>
          ) : null}
          <form onSubmit={onSave} className="space-y-4">
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <Field label="First name">
                <Input
                  value={firstName}
                  onChange={(e) => setFirstName(e.target.value)}
                  required
                  autoComplete="given-name"
                />
              </Field>
              <Field label="Last name">
                <Input
                  value={lastName}
                  onChange={(e) => setLastName(e.target.value)}
                  required
                  autoComplete="family-name"
                />
              </Field>
            </div>
            <PhoneField
              countryCode={countryCode}
              localNumber={localPhone}
              onCountryCodeChange={setCountryCode}
              onLocalNumberChange={setLocalPhone}
            />
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
