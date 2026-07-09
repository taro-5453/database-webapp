import { Navigate } from "react-router";
import type { ReactNode } from "react";
import { useAuth } from "./auth";

export function RequireCustomer({ children }: { children: ReactNode }) {
  const { user, loading } = useAuth();
  if (loading) return null;
  if (!user || user.kind !== "customer") return <Navigate to="/login" replace />;
  return <>{children}</>;
}

export function RequireStaff({ children }: { children: ReactNode }) {
  const { user, loading } = useAuth();
  if (loading) return null;
  if (!user || user.kind !== "staff") return <Navigate to="/staff/login" replace />;
  return <>{children}</>;
}
