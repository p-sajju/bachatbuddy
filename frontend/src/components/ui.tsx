"use client";

import { forwardRef } from "react";

export function Field({
  label,
  hint,
  error,
  children,
}: {
  label: string;
  hint?: string;
  error?: string;
  children: React.ReactNode;
}) {
  return (
    <label className="block space-y-1.5">
      <span className="text-sm font-medium text-[var(--bb-ink)]">{label}</span>
      {children}
      {hint && !error ? (
        <span className="block text-xs text-[var(--bb-muted)]">{hint}</span>
      ) : null}
      {error ? (
        <span className="block text-xs text-[var(--bb-danger)]">{error}</span>
      ) : null}
    </label>
  );
}

export const Input = forwardRef<
  HTMLInputElement,
  React.InputHTMLAttributes<HTMLInputElement>
>(function Input({ className = "", ...props }, ref) {
  return (
    <input
      ref={ref}
      className={`w-full rounded-xl border border-[var(--bb-border)] bg-white/80 px-3.5 py-3 text-[var(--bb-ink)] outline-none transition focus:border-[var(--bb-leaf)] focus:ring-2 focus:ring-[var(--bb-leaf)]/25 ${className}`}
      {...props}
    />
  );
});

export const Select = forwardRef<
  HTMLSelectElement,
  React.SelectHTMLAttributes<HTMLSelectElement>
>(function Select({ className = "", children, ...props }, ref) {
  return (
    <select
      ref={ref}
      className={`w-full rounded-xl border border-[var(--bb-border)] bg-white/80 px-3.5 py-3 text-[var(--bb-ink)] outline-none transition focus:border-[var(--bb-leaf)] focus:ring-2 focus:ring-[var(--bb-leaf)]/25 ${className}`}
      {...props}
    >
      {children}
    </select>
  );
});

export const TextArea = forwardRef<
  HTMLTextAreaElement,
  React.TextareaHTMLAttributes<HTMLTextAreaElement>
>(function TextArea({ className = "", ...props }, ref) {
  return (
    <textarea
      ref={ref}
      className={`w-full rounded-xl border border-[var(--bb-border)] bg-white/80 px-3.5 py-3 text-[var(--bb-ink)] outline-none transition focus:border-[var(--bb-leaf)] focus:ring-2 focus:ring-[var(--bb-leaf)]/25 ${className}`}
      {...props}
    />
  );
});

type ButtonProps = React.ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: "primary" | "secondary" | "ghost" | "danger";
  loading?: boolean;
};

export function Button({
  variant = "primary",
  loading,
  className = "",
  children,
  disabled,
  ...props
}: ButtonProps) {
  const styles = {
    primary:
      "bg-[var(--bb-forest)] text-white shadow-[0_8px_20px_rgba(27,67,50,0.22)] hover:bg-[var(--bb-forest-deep)]",
    secondary:
      "bg-white/90 text-[var(--bb-forest)] border border-[var(--bb-border)] hover:bg-white",
    ghost: "bg-transparent text-[var(--bb-ink)] hover:bg-black/5",
    danger:
      "bg-[var(--bb-danger)] text-white hover:brightness-95",
  }[variant];

  return (
    <button
      className={`inline-flex items-center justify-center gap-2 rounded-xl px-4 py-3 text-sm font-semibold transition disabled:cursor-not-allowed disabled:opacity-55 ${styles} ${className}`}
      disabled={disabled || loading}
      {...props}
    >
      {loading ? (
        <span className="h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent" />
      ) : null}
      {children}
    </button>
  );
}

export function Surface({
  children,
  className = "",
}: {
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <section
      className={`rounded-2xl border border-[var(--bb-border)] bg-[var(--bb-surface)]/90 p-4 shadow-[0_1px_0_rgba(27,67,50,0.04)] ${className}`}
    >
      {children}
    </section>
  );
}

export function EmptyState({
  title,
  body,
  action,
}: {
  title: string;
  body?: string;
  action?: React.ReactNode;
}) {
  return (
    <div className="rounded-2xl border border-dashed border-[var(--bb-border)] bg-white/40 px-4 py-10 text-center">
      <p className="font-medium text-[var(--bb-ink)]">{title}</p>
      {body ? (
        <p className="mt-1 text-sm text-[var(--bb-muted)]">{body}</p>
      ) : null}
      {action ? <div className="mt-4 flex justify-center">{action}</div> : null}
    </div>
  );
}

export function ErrorBanner({ message }: { message: string }) {
  if (!message) return null;
  return (
    <div
      role="alert"
      className="mb-4 rounded-xl border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-800"
    >
      {message}
    </div>
  );
}

export function Disclaimer({ children }: { children: React.ReactNode }) {
  return (
    <p className="rounded-xl bg-[var(--bb-sand)]/70 px-3 py-2 text-xs leading-relaxed text-[var(--bb-muted)]">
      {children}
    </p>
  );
}

export function StatTile({
  label,
  value,
  tone = "default",
}: {
  label: string;
  value: string;
  tone?: "default" | "good" | "warn" | "locked";
}) {
  const toneClass = {
    default: "text-[var(--bb-ink)]",
    good: "text-[var(--bb-leaf)]",
    warn: "text-amber-800",
    locked: "text-[var(--bb-forest)]",
  }[tone];
  return (
    <div className="rounded-2xl border border-[var(--bb-border)] bg-white/70 p-3">
      <p className="text-xs text-[var(--bb-muted)]">{label}</p>
      <p className={`mt-1 text-base font-semibold tabular-nums ${toneClass}`}>
        {value}
      </p>
    </div>
  );
}

export function ProgressBar({ value }: { value: number }) {
  const pct = Math.max(0, Math.min(100, value));
  return (
    <div className="h-2 overflow-hidden rounded-full bg-[var(--bb-sand)]">
      <div
        className="h-full rounded-full bg-[var(--bb-leaf)] transition-[width] duration-500"
        style={{ width: `${pct}%` }}
      />
    </div>
  );
}
