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
  const [partySize, setPartySize] = useState(2);
  const [tables, setTables] = useState<AvailableTable[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function checkAvailability(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);
    setTables(null);
    try {
      const result = await api.get<AvailableTable[]>(
        `/api/branches/${id}/available-tables?party_size=${partySize}`,
      );
      setTables(result);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to load availability");
    } finally {
      setLoading(false);
    }
  }

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
                onChange={(e) => setPartySize(Number(e.target.value))}
                required
              />
            </label>
            <button type="submit" disabled={loading}>
              {loading ? "Checking..." : "Check availability"}
            </button>
          </form>
          {error && <p role="alert">{error}</p>}
          {tables &&
            (tables.length === 0 ? (
              <p className="text-gray-500">No tables available for that party size right now.</p>
            ) : (
              <ul>
                {tables.map((t) => (
                  <li key={t.table_id} className="card flex items-center justify-between">
                    <span className="font-medium text-gray-900">Table {t.table_id}</span>
                    <span className="text-sm text-gray-500">
                      seats {t.capacity} · {t.status}
                    </span>
                  </li>
                ))}
              </ul>
            ))}
        </div>
      </main>
    </>
  );
}
