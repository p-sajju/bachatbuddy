"use client";

import Link from "next/link";

type ProfileAvatarProps = {
  name?: string | null;
  firstName?: string | null;
  lastName?: string | null;
  avatarUrl?: string | null;
  initials?: string | null;
  href?: string;
  size?: "sm" | "md" | "lg";
};

function computeInitials(
  firstName?: string | null,
  lastName?: string | null,
  name?: string | null,
  initials?: string | null,
): string {
  if (initials && initials.trim()) return initials.trim().slice(0, 2).toUpperCase();
  const fromParts = [firstName, lastName]
    .map((p) => (p || "").trim()[0] || "")
    .join("");
  if (fromParts) return fromParts.toUpperCase().slice(0, 2);
  const fromName = (name || "")
    .trim()
    .split(/\s+/)
    .map((p) => p[0] || "")
    .join("");
  return (fromName || "?").toUpperCase().slice(0, 2);
}

const sizeMap = {
  sm: "h-9 w-9 text-xs",
  md: "h-12 w-12 text-sm",
  lg: "h-16 w-16 text-lg",
};

export function ProfileAvatar({
  name,
  firstName,
  lastName,
  avatarUrl,
  initials,
  href = "/settings",
  size = "md",
}: ProfileAvatarProps) {
  const label = computeInitials(firstName, lastName, name, initials);
  const classes = `relative inline-flex ${sizeMap[size]} shrink-0 items-center justify-center overflow-hidden rounded-full bg-[var(--bb-forest)] font-semibold text-white shadow-sm ring-2 ring-white`;

  const content = avatarUrl ? (
    // eslint-disable-next-line @next/next/no-img-element
    <img
      src={avatarUrl}
      alt=""
      className="h-full w-full object-cover"
    />
  ) : (
    <span aria-hidden>{label}</span>
  );

  if (href) {
    return (
      <Link
        href={href}
        className={classes}
        aria-label="Open profile settings"
        title="Profile"
      >
        {content}
      </Link>
    );
  }

  return <div className={classes}>{content}</div>;
}
