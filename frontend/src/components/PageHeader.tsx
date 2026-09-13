import Link from "next/link";

type Props = {
  title?: string;
  subtitle?: string;
  backHref?: string;
  action?: React.ReactNode;
  hero?: boolean;
};

export function PageHeader({
  title,
  subtitle,
  backHref,
  action,
  hero = false,
}: Props) {
  return (
    <header className={`mb-5 ${hero ? "pt-2" : ""}`}>
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          {backHref ? (
            <Link
              href={backHref}
              className="mb-2 inline-flex items-center gap-1 text-sm text-[var(--bb-muted)] hover:text-[var(--bb-ink)]"
            >
              <span aria-hidden>←</span> Back
            </Link>
          ) : null}
          {hero ? (
            <p className="font-[family-name:var(--font-display)] text-3xl font-semibold tracking-tight text-[var(--bb-forest)] sm:text-4xl">
              BachatBuddy
            </p>
          ) : null}
          {title ? (
            <h1
              className={`${
                hero
                  ? "mt-1 text-lg font-medium text-[var(--bb-ink)]"
                  : "font-[family-name:var(--font-display)] text-2xl font-semibold tracking-tight text-[var(--bb-ink)]"
              }`}
            >
              {title}
            </h1>
          ) : null}
          {subtitle ? (
            <p className="mt-1 text-sm leading-relaxed text-[var(--bb-muted)]">
              {subtitle}
            </p>
          ) : null}
        </div>
        {action}
      </div>
    </header>
  );
}

export function BrandMark({ size = "md" }: { size?: "sm" | "md" | "lg" }) {
  const sizeClass =
    size === "lg"
      ? "text-4xl sm:text-5xl"
      : size === "sm"
        ? "text-xl"
        : "text-3xl";
  return (
    <div className="animate-[fadeUp_0.6s_ease_both]">
      <p
        className={`font-[family-name:var(--font-display)] ${sizeClass} font-semibold tracking-tight text-[var(--bb-forest)]`}
      >
        BachatBuddy
      </p>
      <p className="mt-2 max-w-sm text-sm leading-relaxed text-[var(--bb-muted)]">
        Track your money. Protect your savings. Spend with purpose.
      </p>
    </div>
  );
}
