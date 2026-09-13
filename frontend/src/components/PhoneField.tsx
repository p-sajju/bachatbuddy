"use client";

import { Input } from "@/components/ui";
import { DEFAULT_COUNTRY_CODE, sanitizeLocalPhone } from "@/lib/phone";

type PhoneFieldProps = {
  countryCode?: string;
  localNumber: string;
  onCountryCodeChange?: (code: string) => void;
  onLocalNumberChange: (local: string) => void;
  required?: boolean;
  disabled?: boolean;
};

export function PhoneField({
  countryCode = DEFAULT_COUNTRY_CODE,
  localNumber,
  onLocalNumberChange,
  required = true,
  disabled = false,
}: PhoneFieldProps) {
  const inputId = "phone-local-number";

  return (
    <div className="block space-y-1.5">
      <label
        htmlFor={inputId}
        className="block text-sm font-medium text-[var(--bb-ink)]"
      >
        Phone number
      </label>
      <div className="flex gap-2">
        {/* India-only for now — static prefix, no dropdown chevron */}
        <div
          className="flex w-[5.5rem] shrink-0 items-center justify-center rounded-xl border border-[var(--bb-border)] bg-[var(--bb-mint)]/40 px-3 py-3 text-sm font-medium text-[var(--bb-ink)]"
          aria-label={`Country code ${countryCode}`}
          title="India"
        >
          {countryCode}
        </div>
        <Input
          id={inputId}
          type="tel"
          required={required}
          disabled={disabled}
          value={localNumber}
          onChange={(e) =>
            onLocalNumberChange(sanitizeLocalPhone(e.target.value))
          }
          placeholder="9876543210"
          autoComplete="tel-national"
          inputMode="numeric"
          maxLength={10}
          pattern="[0-9]{10}"
          title="Enter 10-digit Indian mobile number"
          className="min-w-0 flex-1"
        />
      </div>
      <p className="text-xs text-[var(--bb-muted)]">
        Enter your 10-digit mobile number.
      </p>
    </div>
  );
}
