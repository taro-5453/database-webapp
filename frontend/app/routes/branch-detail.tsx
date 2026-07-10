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
      <main className="pt-4 p-4 container mx-auto max-w-md">
        <p>
          <Link to="/">&larr; Back to branches</Link>
        </p>
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
            <p>No tables available for that party size right now.</p>
          ) : (
            <ul>
              {tables.map((t) => (
                <li key={t.table_id}>
                  Table {t.table_id} — seats {t.capacity} ({t.status})
                </li>
              ))}
            </ul>
          ))}
      </main>
    </>
  );
}
