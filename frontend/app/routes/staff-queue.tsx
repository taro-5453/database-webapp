import { useCallback, useEffect, useState } from "react";
import { Link } from "react-router";
import { Header } from "../components/Header";
import { RequireStaff } from "../lib/guards";
import { useAuth } from "../lib/auth";
import { api, ApiError } from "../lib/api";
import type { AvailableTable, QueueEntry, Tier } from "../lib/types";

export function meta() {
  return [{ title: "Staff Queue – Momo Paradise" }];
}

function SeatDialog({
  entry,
  branchId,
  onDone,
  onCancel,
}: {
  entry: QueueEntry;
  branchId: number;
  onDone: () => void;
  onCancel: () => void;
}) {
  const [tables, setTables] = useState<AvailableTable[] | null>(null);
  const [tableId, setTableId] = useState<number | "">("");
  const [seated, setSeated] = useState(false);
  const [tiers, setTiers] = useState<Tier[] | null>(null);
  const [tierId, setTierId] = useState<number | "">("");
  const [guestCount, setGuestCount] = useState(entry.party_size);
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    api
      .get<AvailableTable[]>(
        `/api/branches/${branchId}/available-tables?party_size=${entry.party_size}`,
      )
      .then((ts) => {
        setTables(ts);
        if (ts.length > 0) setTableId(ts[0].table_id);
      })
      .catch((err) => setError(err instanceof ApiError ? err.message : "Failed to load tables"));
  }, [branchId, entry.party_size]);

  async function seat() {
    if (tableId === "") return;
    setError(null);
    setSubmitting(true);
    try {
      await api.post(`/api/staff/reservations/${entry.reservation_id}/seat`, {
        table_id: tableId,
      });
      setSeated(true);
      const ts = await api.get<Tier[]>("/api/staff/tiers");
      setTiers(ts);
      if (ts.length > 0) setTierId(ts[0].tier_id);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to seat party");
    } finally {
      setSubmitting(false);
    }
  }

  async function openSession() {
    if (tierId === "" || tableId === "") return;
    setError(null);
    setSubmitting(true);
    try {
      await api.post("/api/staff/dining-sessions", {
        reservation_id: entry.reservation_id,
        table_id: tableId,
        customer_id: entry.customer_id,
        tier_id: tierId,
        guest_count: guestCount,
      });
      onDone();
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to open session");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="mt-3 rounded-xl border border-gray-200 bg-gray-50 p-4">
      {!seated ? (
        <>
          <label>
            Table
            {!tables ? (
              <p className="text-gray-500">Loading tables...</p>
            ) : tables.length === 0 ? (
              <p role="alert">No table fits a party of {entry.party_size} right now.</p>
            ) : (
              <select
                value={tableId}
                onChange={(e) => setTableId(Number(e.target.value))}
              >
                {tables.map((t) => (
                  <option key={t.table_id} value={t.table_id}>
                    Table {t.table_id} — seats {t.capacity}
                  </option>
                ))}
              </select>
            )}
          </label>
          {error && <p role="alert">{error}</p>}
          <div className="mt-3 flex gap-2">
            <button onClick={seat} disabled={submitting || tableId === ""}>
              {submitting ? "Seating..." : "Seat here"}
            </button>
            <button onClick={onCancel} disabled={submitting}>
              Cancel
            </button>
          </div>
        </>
      ) : (
        <>
          <p className="text-sm text-gray-600">
            Seated at table {tableId}. Open the buffet session now — if you skip, this
            party won't appear on the queue or dashboard again, so you'll need to open
            their session directly later.
          </p>
          <label>
            Tier
            {!tiers ? (
              <p className="text-gray-500">Loading tiers...</p>
            ) : (
              <select value={tierId} onChange={(e) => setTierId(Number(e.target.value))}>
                {tiers.map((t) => (
                  <option key={t.tier_id} value={t.tier_id}>
                    {t.name} — ${t.price_per_head.toFixed(2)}/head, {t.duration_minutes} min
                  </option>
                ))}
              </select>
            )}
          </label>
          <label>
            Guest count
            <input
              type="number"
              min={1}
              value={guestCount}
              onChange={(e) => setGuestCount(Number(e.target.value))}
            />
          </label>
          {error && <p role="alert">{error}</p>}
          <div className="mt-3 flex gap-2">
            <button onClick={openSession} disabled={submitting || tierId === ""}>
              {submitting ? "Opening..." : "Open session"}
            </button>
            <button onClick={onDone} disabled={submitting}>
              Skip for now
            </button>
          </div>
        </>
      )}
    </div>
  );
}

function QueueList({ branchId }: { branchId: number }) {
  const [queue, setQueue] = useState<QueueEntry[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [seatingId, setSeatingId] = useState<number | null>(null);

  const refresh = useCallback(async () => {
    try {
      setQueue(await api.get<QueueEntry[]>("/api/staff/queue"));
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to load queue");
    }
  }, []);

  useEffect(() => {
    refresh();
  }, [refresh]);

  function finishSeating() {
    setSeatingId(null);
    refresh();
  }

  if (error) return <p role="alert">{error}</p>;
  if (!queue) return <p className="text-gray-500">Loading queue...</p>;
  if (queue.length === 0) return <p className="text-gray-500">No one is waiting.</p>;

  return (
    <ul>
      {queue.map((entry) => (
        <li key={entry.reservation_id} className="card">
          <div className="flex items-center justify-between">
            <span className="text-gray-900">
              <span className="font-semibold">#{entry.queue_position}</span> —{" "}
              {entry.customer_name} ({entry.phone ?? "no phone"}) — party of{" "}
              {entry.party_size}
            </span>
            {seatingId !== entry.reservation_id && (
              <button onClick={() => setSeatingId(entry.reservation_id)}>Seat</button>
            )}
          </div>
          {seatingId === entry.reservation_id && (
            <SeatDialog
              entry={entry}
              branchId={branchId}
              onDone={finishSeating}
              onCancel={() => setSeatingId(null)}
            />
          )}
        </li>
      ))}
    </ul>
  );
}

export default function StaffQueue() {
  const { user } = useAuth();

  return (
    <>
      <Header />
      <main>
        <div className="page max-w-2xl">
          <p className="text-sm text-gray-500">
            <Link to="/staff">&larr; Dashboard</Link>
          </p>
          <p className="eyebrow">STAFF</p>
          <h1>Queue</h1>
          <RequireStaff>
            {user?.kind === "staff" && <QueueList branchId={user.branch_id} />}
          </RequireStaff>
        </div>
      </main>
    </>
  );
}
