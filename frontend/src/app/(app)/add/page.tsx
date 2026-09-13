import Link from "next/link";
import { PageHeader } from "@/components/PageHeader";
import { Surface } from "@/components/ui";

const actions = [
  {
    href: "/expenses/new",
    title: "Add expense",
    body: "Fast path — amount, category, spent for.",
    accent: "bg-[var(--bb-mint)]",
  },
  {
    href: "/income/new",
    title: "Add income",
    body: "Salary, freelance, or other inflow.",
    accent: "bg-[var(--bb-sand)]",
  },
  {
    href: "/locks/new",
    title: "Create money lock",
    body: "Protect savings from impulse spending.",
    accent: "bg-white",
  },
  {
    href: "/goals/new",
    title: "New savings goal",
    body: "Give your bachat a clear purpose.",
    accent: "bg-white",
  },
];

export default function AddPage() {
  return (
    <div>
      <PageHeader
        title="Add"
        subtitle="Log money quickly, protect what matters"
      />
      <div className="space-y-3">
        {actions.map((a, i) => (
          <Link key={a.href} href={a.href} className="block">
            <Surface
              className={`${a.accent} transition hover:translate-y-[-1px] ${
                i === 0 ? "bb-fade-up" : "bb-fade-up-delay"
              }`}
            >
              <p className="font-semibold text-[var(--bb-ink)]">{a.title}</p>
              <p className="mt-1 text-sm text-[var(--bb-muted)]">{a.body}</p>
            </Surface>
          </Link>
        ))}
      </div>
    </div>
  );
}
