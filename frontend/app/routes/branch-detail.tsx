import { useState } from "react";
import { useParams, Link } from "react-router";
import { api, ApiError } from "../lib/api";
import type { AvailableTable } from "../lib/types";
import { Header } from "../components/Header";

export function meta() {
  return [{ title: "Branch – Momo Paradise" }];
}

export default function BranchDetail() {
  const { id } = useParams();
  const [partySize, setPartySize] = useState<number | "">(2);
  const [checkedSize, setCheckedSize] = useState(0);
  const [tables, setTables] = useState<AvailableTable[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function checkAvailability(e: React.FormEvent) {
    e.preventDefault();
    if (partySize === "" || partySize < 1) return;
    setError(null);
    setLoading(true);
    setTables(null);
    try {
      // fetch every free table (party_size=1): big parties can combine
      // several tables, so a single table doesn't have to fit them all
      const result = await api.get<AvailableTable[]>(
        `/api/branches/${id}/available-tables?party_size=1`,
      );
      setTables(result);
      setCheckedSize(partySize);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to load availability");
    } finally {
      setLoading(false);
    }
  }

  const fittingTables = (tables ?? []).filter((t) => t.capacity >= checkedSize);
  const combinedCapacity = (tables ?? []).reduce((sum, t) => sum + t.capacity, 0);

  return (
    <>
      <Header />
      <main>
        <div className="page max-w-md">
          <p className="text-sm text-gray-500">
            <Link to="/">&larr; Back to branches</Link>
          </p>
          <p className="eyebrow">CHECK AVAILABILITY</p>
          <h1>Branch #{id}</h1>
          <form onSubmit={checkAvailability}>
            <label>
              Party size
              <input
                type="number"
                min={1}
                value={partySize}
                onChange={(e) =>
                  setPartySize(e.target.value === "" ? "" : Number(e.target.value))
                }
                required
              />
            </label>
            <button type="submit" disabled={loading}>
              {loading ? "Checking..." : "Check availability"}
            </button>
          </form>
          {error && <p role="alert">{error}</p>}
          {tables &&
            (fittingTables.length > 0 ? (
              <ul>
                {fittingTables.map((t) => (
                  <li key={t.table_id} className="card flex items-center justify-between">
                    <span className="font-medium text-gray-900">Table {t.table_id}</span>
                    <span className="text-sm text-gray-500">
                      seats {t.capacity} · {t.status}
                    </span>
                  </li>
                ))}
              </ul>
            ) : combinedCapacity >= checkedSize ? (
              <p className="text-gray-500">
                No single table seats {checkedSize}, but staff can combine tables — the free
                tables here seat {combinedCapacity} in total, so you can still reserve.
              </p>
            ) : (
              <p className="text-gray-500">
                This branch can&apos;t seat a party of {checkedSize} right now
                {combinedCapacity > 0
                  ? ` (only ${combinedCapacity} free seats even combining every table).`
                  : "."}
              </p>
            ))}
        </div>
      </main>
    </>
  );
}
