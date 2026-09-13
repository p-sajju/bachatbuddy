"use client";

import { useEffect, useState } from "react";
import { usePathname, useRouter } from "next/navigation";
import { apiGet } from "@/lib/api";
import { isAuthenticated } from "@/lib/auth";
import type { User } from "@/lib/types";

export function AuthGuard({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const [ready, setReady] = useState(false);

  useEffect(() => {
    let cancelled = false;

    (async () => {
      if (!isAuthenticated()) {
        const next = encodeURIComponent(pathname || "/home");
        router.replace(`/login?next=${next}`);
        return;
      }

      try {
        const res = await apiGet<User>("/api/v1/me");
        if (cancelled) return;
        if (res.data.onboarding_completed === false) {
          router.replace("/onboarding");
          return;
        }
      } catch {
        // If /me fails, still allow the app shell; pages handle their own errors.
      }

      if (!cancelled) setReady(true);
    })();

    return () => {
      cancelled = true;
    };
  }, [pathname, router]);

  if (!ready) {
    return (
      <div className="flex min-h-[60vh] items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-2 border-[var(--bb-forest)] border-t-transparent" />
      </div>
    );
  }

  return <>{children}</>;
}
