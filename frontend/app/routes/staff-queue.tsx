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
  const [tableIds, setTableIds] = useState<number[]>([]);
  const [seated, setSeated] = useState(false);
  const [tiers, setTiers] = useState<Tier[] | null>(null);
  const [tierId, setTierId] = useState<number | "">("");
  const [guestCount, setGuestCount] = useState<number | "">(entry.party_size);
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    // party_size=1 lists every free table: big parties combine several
    // small ones, so no single table has to fit the whole party
    api
      .get<AvailableTable[]>(`/api/branches/${branchId}/available-tables?party_size=1`)
      .then(setTables)
      .catch((err) => setError(err instanceof ApiError ? err.message : "Failed to load tables"));
  }, [branchId]);

  const combinedCapacity = (tables ?? [])
    .filter((t) => tableIds.includes(t.table_id))
    .reduce((sum, t) => sum + t.capacity, 0);
  const enoughSeats = combinedCapacity >= entry.party_size;

  function toggleTable(id: number) {
    setTableIds((ids) =>
      ids.includes(id) ? ids.filter((x) => x !== id) : [...ids, id],
    );
  }

  async function seat() {
    if (!enoughSeats) return;
    setError(null);
    setSubmitting(true);
    try {
      await api.post(`/api/staff/reservations/${entry.reservation_id}/seat`, {
        table_ids: tableIds,
      });
      setSeated(true);
      const ts = await api.get<Tier[]>("/api/staff/tiers");
      setTiers(ts);
      // default to the tier the customer picked at booking, if any
      if (entry.tier_id !== null && ts.some((t) => t.tier_id === entry.tier_id)) {
        setTierId(entry.tier_id);
      } else if (ts.length > 0) {
        setTierId(ts[0].tier_id);
      }
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to seat party");
    } finally {
      setSubmitting(false);
    }
  }

  async function openSession() {
    if (tierId === "" || tableIds.length === 0 || guestCount === "" || guestCount < 1) return;
    setError(null);
    setSubmitting(true);
    try {
      await api.post("/api/staff/dining-sessions", {
        reservation_id: entry.reservation_id,
        table_id: tableIds[0], // the session's primary table
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
          <fieldset>
            <legend>Tables (combine as many as the party needs)</legend>
            {!tables ? (
              <p className="text-gray-500">Loading tables...</p>
            ) : tables.length === 0 ? (
              <p role="alert">No tables are free right now.</p>
            ) : (
              <>
                {tables.map((t) => (
                  <label key={t.table_id}>
                    <input
                      type="checkbox"
                      checked={tableIds.includes(t.table_id)}
                      onChange={() => toggleTable(t.table_id)}
                    />
                    Table {t.table_id} — seats {t.capacity}
                  </label>
                ))}
                <p className={enoughSeats ? "text-sm text-green-700" : "text-sm text-gray-500"}>
                  Selected seats: {combinedCapacity} / party of {entry.party_size}
                </p>
              </>
            )}
          </fieldset>
          {error && <p role="alert">{error}</p>}
          <div className="mt-3 flex gap-2">
            <button onClick={seat} disabled={submitting || !enoughSeats}>
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
            Seated at table{tableIds.length > 1 ? "s" : ""} {tableIds.join(", ")}. Open the
            buffet session now — if you skip, this
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
              onChange={(e) =>
                setGuestCount(e.target.value === "" ? "" : Number(e.target.value))
              }
            />
          </label>
          {error && <p role="alert">{error}</p>}
          <div className="mt-3 flex gap-2">
            <button
              onClick={openSession}
              disabled={submitting || tierId === "" || guestCount === "" || guestCount < 1}
            >
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
              {entry.tier_name && ` — wants ${entry.tier_name}`}
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
