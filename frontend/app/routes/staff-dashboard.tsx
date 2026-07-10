import { useCallback, useEffect, useState } from "react";
import { Link } from "react-router";
import { Header } from "../components/Header";
import { RequireStaff } from "../lib/guards";
import { api, ApiError } from "../lib/api";
import type { ActiveSession } from "../lib/types";

const POLL_INTERVAL_MS = 30_000;

export function meta() {
  return [{ title: "Staff Dashboard – Momo Paradise" }];
}

function SessionsList() {
  const [sessions, setSessions] = useState<ActiveSession[] | null>(null);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    try {
      setSessions(await api.get<ActiveSession[]>("/api/staff/dining-sessions"));
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to load sessions");
    }
  }, []);

  useEffect(() => {
    refresh();
    const interval = setInterval(refresh, POLL_INTERVAL_MS);
    return () => clearInterval(interval);
  }, [refresh]);

  if (error) return <p role="alert">{error}</p>;
  if (!sessions) return <p>Loading sessions...</p>;
  if (sessions.length === 0) return <p>No active sessions right now.</p>;

  return (
    <ul>
      {sessions.map((s) => {
        const overtime = s.minutes_remaining < 0;
        return (
          <li
            key={s.session_id}
            className="rounded-md border border-gray-200 p-3 dark:border-gray-800"
          >
            <div className="flex items-center justify-between">
              <span>
                Table {s.table_id} — {s.customer_name} ({s.guest_count} guests) — {s.tier_name}
              </span>
              <span className={overtime ? "font-semibold text-red-600 dark:text-red-400" : ""}>
                {overtime
                  ? `${Math.abs(s.minutes_remaining)} min overtime`
                  : `${s.minutes_remaining} min left`}
              </span>
            </div>
            <p className="text-sm text-gray-600 dark:text-gray-400">
              Server: {s.staff_name} · started {new Date(s.start_time).toLocaleTimeString()} ·
              ends {new Date(s.ends_at).toLocaleTimeString()}
            </p>
          </li>
        );
      })}
    </ul>
  );
}

export default function StaffDashboard() {
  return (
    <>
      <Header />
      <main className="pt-4 p-4 container mx-auto max-w-2xl">
        <h1>Active sessions</h1>
        <p className="flex gap-4 text-sm">
          <Link to="/staff/queue">Queue</Link>
          <Link to="/staff/kitchen">Kitchen</Link>
        </p>
        <RequireStaff>
          <SessionsList />
        </RequireStaff>
      </main>
    </>
  );
}
