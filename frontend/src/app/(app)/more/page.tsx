import Link from "next/link";
import { PageHeader } from "@/components/PageHeader";
import { Surface } from "@/components/ui";

const links = [
  { href: "/people", title: "People", body: "Spent For · family tracking" },
  { href: "/locks", title: "Money Locks", body: "Protect savings virtually" },
  { href: "/recurring", title: "Recurring expenses", body: "Rent, EMI, bills" },
  { href: "/reports", title: "Reports", body: "Monthly income vs spend" },
  { href: "/notifications", title: "Notifications", body: "Nudges & insights" },
  { href: "/settings", title: "Settings", body: "Profile & sign out" },
];

export default function MorePage() {
  return (
    <div>
      <PageHeader
        hero
        title="More"
        subtitle="Everything else for calm money habits"
      />
      <div className="space-y-3">
        {links.map((link) => (
          <Link key={link.href} href={link.href} className="block">
            <Surface className="transition hover:translate-y-[-1px]">
              <p className="font-semibold text-[var(--bb-ink)]">{link.title}</p>
              <p className="mt-1 text-sm text-[var(--bb-muted)]">{link.body}</p>
            </Surface>
          </Link>
        ))}
      </div>
    </div>
  );
}
