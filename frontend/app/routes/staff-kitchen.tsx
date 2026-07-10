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
  if (!lines) return <p className="text-gray-500">Loading kitchen orders...</p>;
  if (lines.length === 0)
    return <p className="text-gray-500">Kitchen is caught up — nothing unserved.</p>;

  const badgeStyle: Record<string, string> = {
    ordered: "bg-gray-100 text-gray-700",
    preparing: "bg-amber-100 text-amber-700",
  };

  return (
    <ul>
      {lines.map((line) => {
        const step = NEXT_STATUS[line.status];
        return (
          <li key={line.order_line_id} className="card flex items-center justify-between">
            <span className="text-gray-900">
              <span className="font-semibold">Table {line.table_id}</span> — {line.quantity}x{" "}
              {line.item_name}{" "}
              <span
                className={`ml-1 rounded-full px-2.5 py-1 text-xs font-semibold ${badgeStyle[line.status] ?? "bg-gray-100 text-gray-700"}`}
              >
                {line.status}
              </span>{" "}
              <span className="text-sm text-gray-500">
                {new Date(line.ordered_at).toLocaleTimeString()}
              </span>
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
      <main>
        <div className="page max-w-2xl">
          <p className="text-sm text-gray-500">
            <Link to="/staff">&larr; Dashboard</Link>
          </p>
          <p className="eyebrow">STAFF</p>
          <h1>Kitchen view</h1>
          <RequireStaff>
            <KitchenList />
          </RequireStaff>
        </div>
      </main>
    </>
  );
}
