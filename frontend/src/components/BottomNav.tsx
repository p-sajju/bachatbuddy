"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const tabs = [
  { href: "/home", label: "Home", icon: HomeIcon },
  { href: "/transactions", label: "Transactions", icon: ListIcon },
  { href: "/add", label: "Add", icon: PlusIcon, primary: true },
  { href: "/goals", label: "Goals", icon: GoalIcon },
  { href: "/more", label: "More", icon: MoreIcon },
] as const;

export function BottomNav() {
  const pathname = usePathname();

  return (
    <nav
      className="fixed bottom-0 inset-x-0 z-40 border-t border-[var(--bb-border)] bg-[color-mix(in_srgb,var(--bb-surface)_92%,transparent)] backdrop-blur-md"
      aria-label="Main"
    >
      <div className="mx-auto flex max-w-lg items-end justify-between px-2 pb-[max(0.5rem,env(safe-area-inset-bottom))] pt-1">
        {tabs.map((tab) => {
          const active =
            pathname === tab.href || pathname.startsWith(`${tab.href}/`);
          const Icon = tab.icon;
          if ("primary" in tab && tab.primary) {
            return (
              <Link
                key={tab.href}
                href={tab.href}
                className="group relative -mt-5 flex flex-1 flex-col items-center gap-1"
              >
                <span className="flex h-14 w-14 items-center justify-center rounded-full bg-[var(--bb-forest)] text-white shadow-[0_10px_24px_rgba(27,67,50,0.35)] transition-transform duration-200 group-active:scale-95">
                  <Icon className="h-6 w-6" />
                </span>
                <span className="text-[11px] font-medium text-[var(--bb-forest)]">
                  {tab.label}
                </span>
              </Link>
            );
          }
          return (
            <Link
              key={tab.href}
              href={tab.href}
              className={`flex flex-1 flex-col items-center gap-1 py-2 text-[11px] transition-colors ${
                active
                  ? "text-[var(--bb-forest)] font-semibold"
                  : "text-[var(--bb-muted)]"
              }`}
            >
              <Icon className={`h-5 w-5 ${active ? "opacity-100" : "opacity-70"}`} />
              {tab.label}
            </Link>
          );
        })}
      </div>
    </nav>
  );
}

function HomeIcon({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8">
      <path d="M4 10.5 12 4l8 6.5V20a1 1 0 0 1-1 1h-5v-6H10v6H5a1 1 0 0 1-1-1v-9.5Z" />
    </svg>
  );
}

function ListIcon({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8">
      <path d="M8 7h12M8 12h12M8 17h12M4 7h.01M4 12h.01M4 17h.01" strokeLinecap="round" />
    </svg>
  );
}

function PlusIcon({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2">
      <path d="M12 5v14M5 12h14" strokeLinecap="round" />
    </svg>
  );
}

function GoalIcon({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8">
      <circle cx="12" cy="12" r="8" />
      <circle cx="12" cy="12" r="4" />
      <circle cx="12" cy="12" r="1.2" fill="currentColor" />
    </svg>
  );
}

function MoreIcon({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="currentColor">
      <circle cx="5" cy="12" r="1.6" />
      <circle cx="12" cy="12" r="1.6" />
      <circle cx="19" cy="12" r="1.6" />
    </svg>
  );
}
