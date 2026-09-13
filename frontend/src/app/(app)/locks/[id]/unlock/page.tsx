"use client";

import { FormEvent, useEffect, useMemo, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { PageHeader } from "@/components/PageHeader";
import {
  Button,
  Disclaimer,
  ErrorBanner,
  Field,
  Input,
  Select,
  Surface,
  TextArea,
} from "@/components/ui";
import { apiGet, apiPost, ApiRequestError } from "@/lib/api";
import { formatINR } from "@/lib/money";
import type { MoneyLock, UnlockPreview } from "@/lib/types";

type Step = "warning" | "reason" | "urgency" | "confirm";

export default function UnlockFlowPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const [lock, setLock] = useState<MoneyLock | null>(null);
  const [preview, setPreview] = useState<UnlockPreview | null>(null);
  const [step, setStep] = useState<Step>("warning");
  const [reason, setReason] = useState("");
  const [urgency, setUrgency] = useState<"planned" | "soon" | "emergency">(
    "planned",
  );
  const [confirmText, setConfirmText] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    apiGet<MoneyLock>(`/api/v1/money_locks/${id}`)
      .then((res) => setLock(res.data))
      .catch(() => setError("Could not load lock."));
  }, [id]);

  const phrase = useMemo(() => {
    if (preview?.confirmation_phrase) return preview.confirmation_phrase;
    if (!lock) return "";
    const rupees = (lock.amount_paise / 100).toLocaleString("en-IN", {
      maximumFractionDigits: 0,
    });
    return `UNLOCK ${rupees}`;
  }, [lock, preview]);

  async function loadPreview() {
    try {
      const res = await apiPost<UnlockPreview>(
        `/api/v1/money_locks/${id}/unlock_preview`,
        { reason, urgency },
      );
      setPreview(res.data);
    } catch {
      // Preview optional — continue with local phrase
    }
  }

  async function submitRequest() {
    setLoading(true);
    setError("");
    try {
      if (urgency === "emergency") {
        await apiPost(`/api/v1/money_locks/${id}/emergency_unlock`, {
          reason,
          confirmation: confirmText.trim(),
        });
      } else {
        await apiPost(`/api/v1/money_locks/${id}/unlock_request`, {
          reason,
          urgency,
        });
        if (urgency === "soon" || preview?.requires_confirmation_phrase) {
          // Some APIs confirm immediately after cooling; try confirm if phrase provided
          if (confirmText.trim()) {
            await apiPost(`/api/v1/money_locks/${id}/confirm_unlock`, {
              confirmation: confirmText.trim(),
            }).catch(() => undefined);
          }
        }
      }
      router.replace(`/locks/${id}`);
    } catch (err) {
      setError(
        err instanceof ApiRequestError
          ? err.message
          : "Unlock could not be completed.",
      );
    } finally {
      setLoading(false);
    }
  }

  async function onContinue(e?: FormEvent) {
    e?.preventDefault();
    setError("");
    if (step === "warning") {
      setStep("reason");
      return;
    }
    if (step === "reason") {
      if (reason.trim().length < 3) {
        setError("Please share a short reason.");
        return;
      }
      setStep("urgency");
      return;
    }
    if (step === "urgency") {
      await loadPreview();
      setStep("confirm");
      return;
    }
    if (step === "confirm") {
      if (urgency === "emergency" && confirmText.trim() !== phrase) {
        setError(`Type exactly: ${phrase}`);
        return;
      }
      await submitRequest();
    }
  }

  return (
    <div>
      <PageHeader title="Unlock flow" backHref={`/locks/${id}`} />
      <ErrorBanner message={error} />

      {step === "warning" ? (
        <Surface className="space-y-4 bb-fade-up">
          <h2 className="font-[family-name:var(--font-display)] text-xl font-semibold">
            Pause before you unlock
          </h2>
          <p className="text-sm leading-relaxed text-[var(--bb-muted)]">
            You locked{" "}
            <strong className="text-[var(--bb-ink)]">
              {lock ? formatINR(lock.amount_paise) : "this amount"}
            </strong>{" "}
            for a reason. Unlocking is available, but friction helps protect
            your savings from impulse.
          </p>
          <Disclaimer>
            This unlock is virtual inside BachatBuddy — not a bank transfer.
          </Disclaimer>
          <Button className="w-full" onClick={() => onContinue()}>
            I understand — continue
          </Button>
        </Surface>
      ) : null}

      {step === "reason" ? (
        <form onSubmit={onContinue} className="space-y-4">
          <Field label="Why do you need this money?">
            <TextArea
              required
              rows={4}
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              placeholder="Be honest with yourself…"
              autoFocus
            />
          </Field>
          <Button type="submit" className="w-full">
            Next
          </Button>
        </form>
      ) : null}

      {step === "urgency" ? (
        <form onSubmit={onContinue} className="space-y-4">
          <Field label="How urgent is this?">
            <Select
              value={urgency}
              onChange={(e) =>
                setUrgency(e.target.value as typeof urgency)
              }
            >
              <option value="planned">Can wait — use cooling off</option>
              <option value="soon">Needed soon</option>
              <option value="emergency">Emergency — unlock now</option>
            </Select>
          </Field>
          <p className="text-sm text-[var(--bb-muted)]">
            Planned unlocks may wait through a cooling-off period. Emergencies
            require typing a confirmation phrase.
          </p>
          <Button type="submit" className="w-full">
            Continue
          </Button>
        </form>
      ) : null}

      {step === "confirm" ? (
        <form onSubmit={onContinue} className="space-y-4">
          <Surface>
            <p className="text-sm text-[var(--bb-muted)]">You are unlocking</p>
            <p className="mt-1 text-2xl font-semibold tabular-nums text-[var(--bb-forest)]">
              {lock ? formatINR(lock.amount_paise) : "—"}
            </p>
            <p className="mt-2 text-sm">Reason: {reason}</p>
            <p className="text-sm capitalize text-[var(--bb-muted)]">
              Urgency: {urgency}
            </p>
          </Surface>
          {urgency === "emergency" ? (
            <Field
              label={`Type ${phrase} to confirm`}
              hint="Emergency unlocks skip cooling off and are audited."
            >
              <Input
                value={confirmText}
                onChange={(e) => setConfirmText(e.target.value)}
                placeholder={phrase}
                autoComplete="off"
                required
              />
            </Field>
          ) : (
            <Disclaimer>
              A cooling-off period may apply. You can return later if the unlock
              is still pending.
            </Disclaimer>
          )}
          <Button
            type="submit"
            className="w-full"
            variant={urgency === "emergency" ? "danger" : "primary"}
            loading={loading}
          >
            {urgency === "emergency" ? "Confirm emergency unlock" : "Request unlock"}
          </Button>
        </form>
      ) : null}
    </div>
  );
}
