import { useEffect, useState } from "react";
import { Link } from "react-router";
import { RequireCustomer } from "../lib/guards";
import { api, ApiError } from "../lib/api";
import type { Branch, Reservation } from "../lib/types";
import { Header } from "../components/Header";

export function meta() {
  return [{ title: "Reserve – Momo Paradise" }];
}

function ReserveForm() {
  const [branches, setBranches] = useState<Branch[] | null>(null);
  const [branchId, setBranchId] = useState<number | "">("");
  const [partySize, setPartySize] = useState(2);
  const [mode, setMode] = useState<"queue" | "slot">("queue");
  const [slotTime, setSlotTime] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<Reservation | null>(null);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    api.get<Branch[]>("/api/branches").then((bs) => {
      setBranches(bs);
      if (bs.length > 0) setBranchId(bs[0].branch_id);
    });
  }, []);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setResult(null);
    setSubmitting(true);
    try {
      if (mode === "slot" && !slotTime) {
        throw new ApiError(400, "Pick a date and time for your slot");
      }
      const payload: Record<string, unknown> = {
        branch_id: branchId,
        party_size: partySize,
      };
      if (mode === "slot") {
        payload.slot_time = new Date(slotTime).toISOString();
      }
      const res = await api.post<Reservation>("/api/reservations", payload);
      setResult(res);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to reserve");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <form onSubmit={handleSubmit}>
      <label>
        Branch
        <select
          value={branchId}
          onChange={(e) => setBranchId(Number(e.target.value))}
          required
        >
          {!branches && <option>Loading...</option>}
          {branches?.map((b) => (
            <option key={b.branch_id} value={b.branch_id}>
              {b.name}
            </option>
          ))}
        </select>
      </label>
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
      <fieldset>
        <label>
          <input
            type="radio"
            name="mode"
            checked={mode === "queue"}
            onChange={() => setMode("queue")}
          />
          Join queue now
        </label>
        <label>
          <input
            type="radio"
            name="mode"
            checked={mode === "slot"}
            onChange={() => setMode("slot")}
          />
          Book a time slot
        </label>
      </fieldset>
      {mode === "slot" && (
        <label>
          Date &amp; time
          <input
            type="datetime-local"
            value={slotTime}
            onChange={(e) => setSlotTime(e.target.value)}
            required
          />
        </label>
      )}
      {error && <p role="alert">{error}</p>}
      <button type="submit" disabled={submitting}>
        {submitting ? "Reserving..." : "Reserve"}
      </button>
      {result && (
        <p>
          Reservation #{result.reservation_id} — status: <strong>{result.status}</strong>.
          A staff member will seat you when your table is ready.
        </p>
      )}
    </form>
  );
}

export default function Reserve() {
  return (
    <>
      <Header />
      <main className="pt-4 p-4 container mx-auto max-w-md">
        <p>
          <Link to="/">&larr; Back to branches</Link>
        </p>
        <h1>Make a reservation</h1>
        <RequireCustomer>
          <ReserveForm />
        </RequireCustomer>
      </main>
    </>
  );
}
