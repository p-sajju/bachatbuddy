/** Money helpers — API amounts are integer paise. */

export function paiseToRupees(paise: number): number {
  return paise / 100;
}

export function rupeesToPaise(rupees: number): number {
  return Math.round(rupees * 100);
}

/** Parse a rupee amount string (e.g. "1,250.50" or "1250") into paise. */
export function parseRupeesInput(value: string): number | null {
  const cleaned = value.replace(/,/g, "").trim();
  if (!cleaned) return null;
  const n = Number(cleaned);
  if (!Number.isFinite(n) || n < 0) return null;
  return rupeesToPaise(n);
}

export function formatINR(
  paise: number,
  opts: { showPaise?: boolean; signed?: boolean } = {},
): string {
  const { showPaise = true, signed = false } = opts;
  const rupees = paiseToRupees(paise);
  const abs = Math.abs(rupees);
  const formatted = new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency: "INR",
    minimumFractionDigits: showPaise ? 2 : 0,
    maximumFractionDigits: showPaise ? 2 : 0,
  }).format(abs);

  if (!signed) return rupees < 0 ? `-${formatted}` : formatted;
  if (paise > 0) return `+${formatted}`;
  if (paise < 0) return `-${formatted}`;
  return formatted;
}

export function formatINRCompact(paise: number): string {
  const rupees = paiseToRupees(paise);
  return new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency: "INR",
    notation: "compact",
    maximumFractionDigits: 1,
  }).format(rupees);
}
