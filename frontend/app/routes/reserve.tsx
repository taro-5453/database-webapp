import { useEffect, useState } from "react";
import { Link, useSearchParams } from "react-router";
import { RequireCustomer } from "../lib/guards";
import { api, ApiError } from "../lib/api";
import type { Branch, Reservation, Tier } from "../lib/types";
import { Header } from "../components/Header";

export function meta() {
  return [{ title: "Reserve – Momo Paradise" }];
}

function ReserveForm() {
  // the "find your table" page links here with ?branch=..&party=..
  // so the customer doesn't re-enter what they already told us
  const [searchParams] = useSearchParams();
  const [branches, setBranches] = useState<Branch[] | null>(null);
  const [branchId, setBranchId] = useState<number | "">("");
  const [partySize, setPartySize] = useState<number | "">(() => {
    const p = Number(searchParams.get("party"));
    return Number.isInteger(p) && p > 0 ? p : 2;
  });
  const [tiers, setTiers] = useState<Tier[] | null>(null);
  const [tierId, setTierId] = useState<number | "">(""); // "" = decide when seated
  const [mode, setMode] = useState<"queue" | "slot">("queue");
  const [slotTime, setSlotTime] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<Reservation | null>(null);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    api.get<Branch[]>("/api/branches").then((bs) => {
      setBranches(bs);
      const wanted = Number(searchParams.get("branch"));
      if (bs.some((b) => b.branch_id === wanted)) setBranchId(wanted);
      else if (bs.length > 0) setBranchId(bs[0].branch_id);
    });
    // searchParams only matter on first render — the user takes over after
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (branchId === "") return;
    setTiers(null);
    setTierId(""); // a tier from another branch would be rejected
    api
      .get<Tier[]>(`/api/branches/${branchId}/tiers`)
      .then(setTiers)
      .catch(() => setTiers([])); // pricing is a nice-to-have; booking still works
  }, [branchId]);

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
      if (tierId !== "") {
        payload.tier_id = tierId;
      }
      if (mode === "slot") {
        // send the datetime-local value as-is (local wall-clock time):
        // the DB column is a plain TIMESTAMP, so "18:00" stays 18:00
        // instead of being shifted to UTC
        payload.slot_time = slotTime;
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
      {tiers && tiers.length > 0 && (
        <fieldset>
          <legend>Buffet tier</legend>
          {tiers.map((t) => (
            <label key={t.tier_id}>
              <input
                type="radio"
                name="tier"
                checked={tierId === t.tier_id}
                onChange={() => setTierId(t.tier_id)}
              />
              <span className="flex-1 font-medium text-gray-900">{t.name}</span>
              <span className="text-sm text-gray-500">
                ${t.price_per_head.toFixed(2)}/person · {t.duration_minutes} min
              </span>
            </label>
          ))}
          <label>
            <input
              type="radio"
              name="tier"
              checked={tierId === ""}
              onChange={() => setTierId("")}
            />
            <span className="flex-1 text-gray-700">I&apos;ll decide when seated</span>
          </label>
        </fieldset>
      )}
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
        <p className="rounded-lg border border-green-200 bg-green-50 px-3.5 py-2.5 text-sm text-green-700">
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
      <main>
        <div className="page max-w-md">
          <p className="text-sm text-gray-500">
            <Link to="/">&larr; Back to branches</Link>
          </p>
          <p className="eyebrow">SECURE YOUR TABLE</p>
          <h1>Make a reservation</h1>
          <RequireCustomer>
            <ReserveForm />
          </RequireCustomer>
        </div>
      </main>
    </>
  );
}
