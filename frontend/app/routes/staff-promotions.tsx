import { useCallback, useEffect, useState } from "react";
import { Link } from "react-router";
import { Header } from "../components/Header";
import { RequireStaff } from "../lib/guards";
import { api, ApiError } from "../lib/api";
import type { Promotion } from "../lib/types";

export function meta() {
  return [{ title: "Manage Promotions – Momo Paradise" }];
}

function CreatePromotionForm({ onCreated }: { onCreated: () => void }) {
  const [code, setCode] = useState("");
  const [discount, setDiscount] = useState(10);
  const [discountType, setDiscountType] = useState<"percent" | "fixed">("percent");
  const [validUntil, setValidUntil] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setSubmitting(true);
    try {
      await api.post("/api/staff/promotions", {
        code,
        discount,
        discount_type: discountType,
        valid_until: validUntil || undefined,
      });
      setCode("");
      setDiscount(10);
      setValidUntil("");
      onCreated();
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to create promotion");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <form onSubmit={handleSubmit}>
      <label>
        Code
        <input
          value={code}
          onChange={(e) => setCode(e.target.value.toUpperCase())}
          required
        />
      </label>
      <fieldset>
        <label>
          <input
            type="radio"
            name="discount_type"
            checked={discountType === "percent"}
            onChange={() => setDiscountType("percent")}
          />
          Percent off
        </label>
        <label>
          <input
            type="radio"
            name="discount_type"
            checked={discountType === "fixed"}
            onChange={() => setDiscountType("fixed")}
          />
          Fixed amount off
        </label>
      </fieldset>
      <label>
        Discount ({discountType === "percent" ? "%" : "$"})
        <input
          type="number"
          min={0}
          max={discountType === "percent" ? 100 : undefined}
          step="0.01"
          value={discount}
          onChange={(e) => setDiscount(Number(e.target.value))}
          required
        />
      </label>
      <label>
        Valid until (blank = never expires)
        <input type="date" value={validUntil} onChange={(e) => setValidUntil(e.target.value)} />
      </label>
      {error && <p role="alert">{error}</p>}
      <button type="submit" disabled={submitting}>
        {submitting ? "Creating..." : "Create promotion"}
      </button>
    </form>
  );
}

function PromotionsList() {
  const [promos, setPromos] = useState<Promotion[] | null>(null);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    try {
      setPromos(await api.get<Promotion[]>("/api/staff/promotions"));
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to load promotions");
    }
  }, []);

  useEffect(() => {
    refresh();
  }, [refresh]);

  return (
    <>
      <h2>New promotion</h2>
      <CreatePromotionForm onCreated={refresh} />

      <h2>Promotions</h2>
      {error && <p role="alert">{error}</p>}
      {!promos ? (
        <p>Loading promotions...</p>
      ) : promos.length === 0 ? (
        <p>No promotions yet.</p>
      ) : (
        <ul>
          {promos.map((p) => (
            <li
              key={p.promotion_id}
              className={
                "rounded-md border border-gray-200 p-3 dark:border-gray-800" +
                (p.is_active ? "" : " opacity-50")
              }
            >
              <strong>{p.code}</strong> —{" "}
              {p.discount_type === "percent" ? `${p.discount}%` : `$${p.discount.toFixed(2)}`}{" "}
              off — {p.valid_until ? `expires ${p.valid_until}` : "never expires"} —{" "}
              {p.is_active ? "active" : "expired"} (by {p.created_by})
            </li>
          ))}
        </ul>
      )}
    </>
  );
}

export default function StaffPromotions() {
  return (
    <>
      <Header />
      <main className="pt-4 p-4 container mx-auto max-w-2xl">
        <p>
          <Link to="/staff">&larr; Dashboard</Link>
        </p>
        <h1>Manage promotions</h1>
        <RequireStaff>
          <PromotionsList />
        </RequireStaff>
      </main>
    </>
  );
}
