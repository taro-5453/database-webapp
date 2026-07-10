import { useCallback, useEffect, useState } from "react";
import { Link } from "react-router";
import { Header } from "../components/Header";
import { RequireStaff } from "../lib/guards";
import { api, ApiError } from "../lib/api";
import type { ActiveSession, PromotionValidation } from "../lib/types";

const POLL_INTERVAL_MS = 30_000;

export function meta() {
  return [{ title: "Staff Dashboard – Momo Paradise" }];
}

function CheckoutDialog({
  session,
  onDone,
  onCancel,
}: {
  session: ActiveSession;
  onDone: () => void;
  onCancel: () => void;
}) {
  const [code, setCode] = useState("");
  const [validation, setValidation] = useState<PromotionValidation | null>(null);
  const [checking, setChecking] = useState(false);
  const [paymentMethod, setPaymentMethod] = useState("cash");
  const [result, setResult] = useState<{ bill_id: number } | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  async function checkCode() {
    if (!code.trim()) return;
    setChecking(true);
    setError(null);
    setValidation(null);
    try {
      setValidation(
        await api.get<PromotionValidation>(
          `/api/staff/promotions/validate?code=${encodeURIComponent(code.trim())}`,
        ),
      );
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to validate code");
    } finally {
      setChecking(false);
    }
  }

  async function confirmCheckout() {
    setSubmitting(true);
    setError(null);
    try {
      const res = await api.post<{ bill_id: number }>(
        `/api/staff/dining-sessions/${session.session_id}/checkout`,
        {
          promotion_code: validation?.is_valid ? code.trim() : undefined,
          payment_method: paymentMethod,
        },
      );
      setResult(res);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to checkout");
    } finally {
      setSubmitting(false);
    }
  }

  if (result) {
    return (
      <div className="mt-2 rounded-md border border-gray-300 p-3 dark:border-gray-700">
        <p>
          Checked out — Bill #{result.bill_id}
          {validation?.is_valid &&
            ` (${validation.discount_type === "percent" ? `${validation.discount}%` : `$${validation.discount}`} off applied)`}
          .
        </p>
        <button onClick={onDone}>Close</button>
      </div>
    );
  }

  return (
    <div className="mt-2 rounded-md border border-gray-300 p-3 dark:border-gray-700">
      <label>
        Promotion code (optional)
        <div className="flex gap-2">
          <input
            value={code}
            onChange={(e) => {
              setCode(e.target.value.toUpperCase());
              setValidation(null);
            }}
          />
          <button type="button" onClick={checkCode} disabled={checking || !code.trim()}>
            {checking ? "Checking..." : "Check code"}
          </button>
        </div>
      </label>
      {validation && (
        <p role={validation.is_valid ? undefined : "alert"}>
          {validation.is_valid
            ? `Valid — ${validation.discount_type === "percent" ? `${validation.discount}% off` : `$${validation.discount} off`}`
            : `"${validation.code}" is not a valid code`}
        </p>
      )}
      <label>
        Payment method
        <select value={paymentMethod} onChange={(e) => setPaymentMethod(e.target.value)}>
          <option value="cash">Cash</option>
          <option value="card">Card</option>
          <option value="qr">QR</option>
        </select>
      </label>
      {error && <p role="alert">{error}</p>}
      <div className="mt-3 flex gap-2">
        <button onClick={confirmCheckout} disabled={submitting}>
          {submitting ? "Checking out..." : "Confirm checkout"}
        </button>
        <button onClick={onCancel} disabled={submitting}>
          Cancel
        </button>
      </div>
    </div>
  );
}

function SessionsList() {
  const [sessions, setSessions] = useState<ActiveSession[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [checkoutId, setCheckoutId] = useState<number | null>(null);

  const refresh = useCallback(async () => {
    try {
      setSessions(await api.get<ActiveSession[]>("/api/staff/dining-sessions"));
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to load sessions");
    }
  }, []);

  useEffect(() => {
    refresh();
    const interval = setInterval(refresh, POLL_INTERVAL_MS);
    return () => clearInterval(interval);
  }, [refresh]);

  function finishCheckout() {
    setCheckoutId(null);
    refresh();
  }

  if (error) return <p role="alert">{error}</p>;
  if (!sessions) return <p>Loading sessions...</p>;
  if (sessions.length === 0) return <p>No active sessions right now.</p>;

  return (
    <ul>
      {sessions.map((s) => {
        const overtime = s.minutes_remaining < 0;
        return (
          <li
            key={s.session_id}
            className="rounded-md border border-gray-200 p-3 dark:border-gray-800"
          >
            <div className="flex items-center justify-between">
              <span>
                Table {s.table_id} — {s.customer_name} ({s.guest_count} guests) — {s.tier_name}
              </span>
              <div className="flex items-center gap-3">
                <span className={overtime ? "font-semibold text-red-600 dark:text-red-400" : ""}>
                  {overtime
                    ? `${Math.abs(s.minutes_remaining)} min overtime`
                    : `${s.minutes_remaining} min left`}
                </span>
                {checkoutId !== s.session_id && (
                  <button onClick={() => setCheckoutId(s.session_id)}>Checkout</button>
                )}
              </div>
            </div>
            <p className="text-sm text-gray-600 dark:text-gray-400">
              Server: {s.staff_name} · started {new Date(s.start_time).toLocaleTimeString()} ·
              ends {new Date(s.ends_at).toLocaleTimeString()}
            </p>
            {checkoutId === s.session_id && (
              <CheckoutDialog
                session={s}
                onDone={finishCheckout}
                onCancel={() => setCheckoutId(null)}
              />
            )}
          </li>
        );
      })}
    </ul>
  );
}

export default function StaffDashboard() {
  return (
    <>
      <Header />
      <main className="pt-4 p-4 container mx-auto max-w-2xl">
        <h1>Active sessions</h1>
        <p className="flex gap-4 text-sm">
          <Link to="/staff/queue">Queue</Link>
          <Link to="/staff/kitchen">Kitchen</Link>
          <Link to="/staff/menu">Menu</Link>
          <Link to="/staff/promotions">Promotions</Link>
        </p>
        <RequireStaff>
          <SessionsList />
        </RequireStaff>
      </main>
    </>
  );
}
