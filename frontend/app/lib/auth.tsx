import { createContext, useContext, useEffect, useState, type ReactNode } from "react";
import { api } from "./api";

export type CustomerSession = {
  kind: "customer";
  customer_id: number;
  name: string;
};

export type StaffSession = {
  kind: "staff";
  staff_id: number;
  branch_id: number;
  name: string;
  role: string;
};

export type Session = CustomerSession | StaffSession;

type AuthContextValue = {
  user: Session | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  register: (name: string, email: string, password: string, phone?: string) => Promise<void>;
  staffLogin: (name: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
};

const AuthContext = createContext<AuthContextValue | null>(null);

async function fetchMe(): Promise<Session | null> {
  try {
    return await api.get<Session>("/api/auth/me");
  } catch {
    return null;
  }
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchMe().then((session) => {
      setUser(session);
      setLoading(false);
    });
  }, []);

  async function login(email: string, password: string) {
    await api.post("/api/auth/login", { email, password });
    setUser(await fetchMe());
  }

  async function register(name: string, email: string, password: string, phone?: string) {
    await api.post("/api/auth/register", { name, email, password, phone });
    setUser(await fetchMe());
  }

  async function staffLogin(name: string, password: string) {
    await api.post("/api/auth/staff-login", { name, password });
    setUser(await fetchMe());
  }

  async function logout() {
    await api.post("/api/auth/logout");
    setUser(null);
  }

  return (
    <AuthContext.Provider value={{ user, loading, login, register, staffLogin, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
