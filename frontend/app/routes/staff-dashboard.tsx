import { useCallback, useEffect, useRef, useState } from "react";
import { Link } from "react-router";
import { Header } from "../components/Header";
import { RequireStaff } from "../lib/guards";
import { api, ApiError } from "../lib/api";
import type { ActiveSession, BillReceipt, PromotionValidation } from "../lib/types";

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
  const [receipt, setReceipt] = useState<BillReceipt | null>(null);
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
      setReceipt(await api.get<BillReceipt>(`/api/staff/bills/${res.bill_id}`));
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to checkout");
    } finally {
      setSubmitting(false);
    }
  }

  if (receipt) {
    const row = "flex justify-between gap-6";
    return (
      <div className="mt-3 rounded-xl border border-green-200 bg-green-50 p-4">
        <p className="font-semibold text-green-800">Paid — receipt #{receipt.bill_id}</p>
        <div className="mx-auto mt-3 max-w-sm rounded-lg border border-gray-200 bg-white p-4 text-sm text-gray-700">
          <p className="text-center font-semibold text-gray-900">Momo Paradise {receipt.branch_name}</p>
          <p className="text-center text-xs text-gray-500">
            Table {receipt.table_id} · {receipt.customer_name} ·{" "}
            {new Date(receipt.paid_at).toLocaleString()}
          </p>
          <hr className="my-3 border-dashed border-gray-300" />
          <p className={row}>
            <span>
              {receipt.tier_name} buffet — {receipt.guest_count} × ฿
              {receipt.price_per_head.toFixed(2)}
            </span>
            <span>฿{receipt.buffet_total.toFixed(2)}</span>
          </p>
          <p className={row}>
            <span>Extra charges</span>
            <span>฿{receipt.extra_charges.toFixed(2)}</span>
          </p>
          {receipt.discount_amount > 0 && (
            <p className={`${row} text-green-700`}>
              <span>Discount{receipt.promotion_code ? ` (${receipt.promotion_code})` : ""}</span>
              <span>−฿{receipt.discount_amount.toFixed(2)}</span>
            </p>
          )}
          <hr className="my-3 border-dashed border-gray-300" />
          <p className={`${row} text-base font-semibold text-gray-900`}>
            <span>Total</span>
            <span>฿{receipt.final_total.toFixed(2)}</span>
          </p>
          <p className="mt-2 text-xs text-gray-500">
            Paid by {receipt.payment_method}
            {receipt.points_earned > 0 &&
              ` · ${receipt.customer_name} earned ${receipt.points_earned} points`}
          </p>
        </div>
        <button onClick={onDone} className="mt-3">
          Close
        </button>
      </div>
    );
  }

  return (
    <div className="mt-3 rounded-xl border border-gray-200 bg-gray-50 p-4">
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
  // mirrors checkoutId for the poll interval: while a checkout dialog
  // is open we must NOT refresh, or the closed session drops out of
  // the list and unmounts the dialog — taking the receipt with it
  const checkoutIdRef = useRef<number | null>(null);

  const refresh = useCallback(async () => {
    try {
      setSessions(await api.get<ActiveSession[]>("/api/staff/dining-sessions"));
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to load sessions");
    }
  }, []);

  useEffect(() => {
    refresh();
    const interval = setInterval(() => {
      if (checkoutIdRef.current === null) refresh();
    }, POLL_INTERVAL_MS);
    return () => clearInterval(interval);
  }, [refresh]);

  function startCheckout(sessionId: number) {
    checkoutIdRef.current = sessionId;
    setCheckoutId(sessionId);
  }

  function closeCheckout() {
    checkoutIdRef.current = null;
    setCheckoutId(null);
  }

  function finishCheckout() {
    closeCheckout();
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
          <li key={s.session_id} className="card">
            <div className="flex items-center justify-between">
              <span className="font-medium text-gray-900">
                Table {s.table_id} — {s.customer_name} ({s.guest_count} guests) — {s.tier_name}
              </span>
              <div className="flex items-center gap-3">
                <span
                  className={
                    overtime
                      ? "rounded-full bg-red-100 px-2.5 py-1 text-xs font-semibold text-red-700"
                      : "rounded-full bg-gray-100 px-2.5 py-1 text-xs font-semibold text-gray-700"
                  }
                >
                  {overtime
                    ? `${Math.abs(s.minutes_remaining)} min overtime`
                    : `${s.minutes_remaining} min left`}
                </span>
                {checkoutId !== s.session_id && (
                  <button onClick={() => startCheckout(s.session_id)}>Checkout</button>
                )}
              </div>
            </div>
            <p className="mt-1 text-sm text-gray-500">
              Server: {s.staff_name} · started {new Date(s.start_time).toLocaleTimeString()} ·
              ends {new Date(s.ends_at).toLocaleTimeString()}
            </p>
            {checkoutId === s.session_id && (
              <CheckoutDialog
                session={s}
                onDone={finishCheckout}
                onCancel={closeCheckout}
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
      <main>
        <div className="page max-w-3xl">
          <p className="eyebrow">STAFF</p>
          <h1>Active sessions</h1>
          <nav className="mt-3 mb-6 flex gap-4 text-sm font-medium">
            <Link to="/staff/queue">Queue</Link>
            <Link to="/staff/kitchen">Kitchen</Link>
            <Link to="/staff/menu">Menu</Link>
            <Link to="/staff/promotions">Promotions</Link>
          </nav>
          <RequireStaff>
            <SessionsList />
          </RequireStaff>
        </div>
      </main>
    </>
  );
}
