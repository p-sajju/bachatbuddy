/** India-only for now; extend COUNTRY_CODES later for OTP multi-country. */
export const COUNTRY_CODES = [
  { code: "+91", label: "India (+91)", iso: "IN" },
] as const;

export const DEFAULT_COUNTRY_CODE = COUNTRY_CODES[0].code;

/** Digits only, max 10 for India local mobile. */
export function sanitizeLocalPhone(value: string, maxLen = 10): string {
  return value.replace(/\D/g, "").slice(0, maxLen);
}

/** Build E.164-ish stored value: +91XXXXXXXXXX */
export function buildPhoneNumber(
  countryCode: string,
  localNumber: string,
): string {
  const local = sanitizeLocalPhone(localNumber);
  const code = countryCode.startsWith("+") ? countryCode : `+${countryCode}`;
  return `${code}${local}`;
}

/** Split stored +91XXXXXXXXXX into country code + local for forms. */
export function splitPhoneNumber(stored: string | null | undefined): {
  countryCode: string;
  localNumber: string;
} {
  const raw = (stored || "").replace(/[\s\-()]/g, "");
  for (const { code } of COUNTRY_CODES) {
    if (raw.startsWith(code)) {
      return {
        countryCode: code,
        localNumber: sanitizeLocalPhone(raw.slice(code.length)),
      };
    }
  }
  // Legacy / bare 10-digit India number
  if (/^\d{10}$/.test(raw)) {
    return { countryCode: DEFAULT_COUNTRY_CODE, localNumber: raw };
  }
  if (raw.startsWith("+")) {
    return {
      countryCode: DEFAULT_COUNTRY_CODE,
      localNumber: sanitizeLocalPhone(raw.replace(/^\+\d{1,3}/, "")),
    };
  }
  return {
    countryCode: DEFAULT_COUNTRY_CODE,
    localNumber: sanitizeLocalPhone(raw),
  };
}
