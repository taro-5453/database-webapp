import { useCallback, useEffect, useState } from "react";
import { Link } from "react-router";
import { Header } from "../components/Header";
import { RequireStaff } from "../lib/guards";
import { api, ApiError } from "../lib/api";
import type { KitchenOrderLine } from "../lib/types";

const POLL_INTERVAL_MS = 10_000;

export function meta() {
  return [{ title: "Kitchen View – Momo Paradise" }];
}

const NEXT_STATUS: Record<string, { label: string; next: string } | undefined> = {
  ordered: { label: "Start preparing", next: "preparing" },
  preparing: { label: "Mark served", next: "served" },
};

function KitchenList() {
  const [lines, setLines] = useState<KitchenOrderLine[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [updatingId, setUpdatingId] = useState<number | null>(null);

  const refresh = useCallback(async () => {
    try {
      setLines(await api.get<KitchenOrderLine[]>("/api/staff/kitchen"));
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to load kitchen orders");
    }
  }, []);

  useEffect(() => {
    refresh();
    const interval = setInterval(refresh, POLL_INTERVAL_MS);
    return () => clearInterval(interval);
  }, [refresh]);

  async function advance(line: KitchenOrderLine) {
    const step = NEXT_STATUS[line.status];
    if (!step) return;
    setUpdatingId(line.order_line_id);
    setError(null);
    try {
      await api.patch(`/api/staff/orders/${line.order_line_id}`, { status: step.next });
      await refresh();
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to update order");
    } finally {
      setUpdatingId(null);
    }
  }

  if (error) return <p role="alert">{error}</p>;
  if (!lines) return <p>Loading kitchen orders...</p>;
  if (lines.length === 0) return <p>Kitchen is caught up — nothing unserved.</p>;

  return (
    <ul>
      {lines.map((line) => {
        const step = NEXT_STATUS[line.status];
        return (
          <li
            key={line.order_line_id}
            className="flex items-center justify-between rounded-md border border-gray-200 p-3 dark:border-gray-800"
          >
            <span>
              Table {line.table_id} — {line.quantity}x {line.item_name} — {line.status} —{" "}
              {new Date(line.ordered_at).toLocaleTimeString()}
            </span>
            {step && (
              <button onClick={() => advance(line)} disabled={updatingId === line.order_line_id}>
                {updatingId === line.order_line_id ? "Updating..." : step.label}
              </button>
            )}
          </li>
        );
      })}
    </ul>
  );
}

export default function StaffKitchen() {
  return (
    <>
      <Header />
      <main className="pt-4 p-4 container mx-auto max-w-2xl">
        <p>
          <Link to="/staff">&larr; Dashboard</Link>
        </p>
        <h1>Kitchen view</h1>
        <RequireStaff>
          <KitchenList />
        </RequireStaff>
      </main>
    </>
  );
}
