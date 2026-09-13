import { AuthGuard } from "@/components/AuthGuard";
import { BottomNav } from "@/components/BottomNav";

export default function AppLayout({ children }: { children: React.ReactNode }) {
  return (
    <AuthGuard>
      <div className="bb-shell">
        {children}
        <BottomNav />
      </div>
    </AuthGuard>
  );
}
