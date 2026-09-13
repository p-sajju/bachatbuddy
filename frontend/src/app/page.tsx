"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { apiGet } from "@/lib/api";
import { isAuthenticated } from "@/lib/auth";
import type { User } from "@/lib/types";

export default function RootPage() {
  const router = useRouter();

  useEffect(() => {
    let cancelled = false;

    (async () => {
      if (!isAuthenticated()) {
        router.replace("/login");
        return;
      }

      try {
        const res = await apiGet<User>("/api/v1/me");
        if (cancelled) return;
        router.replace(
          res.data.onboarding_completed === true ? "/home" : "/onboarding",
        );
      } catch {
        if (!cancelled) router.replace("/home");
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [router]);

  return (
    <div className="flex min-h-dvh items-center justify-center">
      <div className="h-8 w-8 animate-spin rounded-full border-2 border-[var(--bb-forest)] border-t-transparent" />
    </div>
  );
}
