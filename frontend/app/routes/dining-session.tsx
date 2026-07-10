import { useCallback, useEffect, useState } from "react";
import { useParams, Link } from "react-router";
import { RequireCustomer } from "../lib/guards";
import { api, ApiError } from "../lib/api";
import type { MenuItem, OrderLine, Bill } from "../lib/types";
import { Header } from "../components/Header";

const POLL_INTERVAL_MS = 10_000;

export function meta() {
  return [{ title: "Dining Session – Momo Paradise" }];
}

function SessionContent({ sessionId }: { sessionId: number }) {
  const [menu, setMenu] = useState<MenuItem[] | null>(null);
  const [orders, setOrders] = useState<OrderLine[] | null>(null);
  const [bill, setBill] = useState<Bill | null>(null);
  const [pageError, setPageError] = useState<string | null>(null);
  const [orderError, setOrderError] = useState<string | null>(null);
  const [placingId, setPlacingId] = useState<number | null>(null);

  const refreshOrdersAndBill = useCallback(async () => {
    try {
      const [o, b] = await Promise.all([
        api.get<OrderLine[]>(`/api/dining-sessions/${sessionId}/orders`),
        api.get<Bill>(`/api/dining-sessions/${sessionId}/bill`),
      ]);
      setOrders(o);
      setBill(b);
    } catch (err) {
      setPageError(err instanceof ApiError ? err.message : "Failed to load session");
    }
  }, [sessionId]);

  useEffect(() => {
    api
      .get<MenuItem[]>(`/api/dining-sessions/${sessionId}/menu`)
      .then(setMenu)
      .catch((err) =>
        setPageError(err instanceof ApiError ? err.message : "Failed to load menu"),
      );
    refreshOrdersAndBill();
  }, [sessionId, refreshOrdersAndBill]);

  useEffect(() => {
    const interval = setInterval(refreshOrdersAndBill, POLL_INTERVAL_MS);
    return () => clearInterval(interval);
  }, [refreshOrdersAndBill]);

  async function placeOrder(itemId: number) {
    setOrderError(null);
    setPlacingId(itemId);
    try {
      await api.post(`/api/dining-sessions/${sessionId}/orders`, {
        item_id: itemId,
        quantity: 1,
      });
      await refreshOrdersAndBill();
    } catch (err) {
      setOrderError(err instanceof ApiError ? err.message : "Failed to place order");
    } finally {
      setPlacingId(null);
    }
  }

  if (pageError) return <p role="alert">{pageError}</p>;

  const statusStyle: Record<string, string> = {
    ordered: "bg-gray-100 text-gray-700",
    preparing: "bg-amber-100 text-amber-700",
    served: "bg-green-100 text-green-700",
  };

  return (
    <div className="grid gap-8 md:grid-cols-2">
      <section>
        <h2>Menu</h2>
        {!menu ? (
          <p className="text-gray-500">Loading menu...</p>
        ) : (
          <ul>
            {menu.map((item) => (
              <li
                key={item.item_id}
                className="card flex items-center justify-between gap-3"
              >
                <div>
                  <p className="font-medium text-gray-900">{item.name}</p>
                  <p className="text-sm text-gray-500">
                    {item.category} · ${item.price.toFixed(2)}
                  </p>
                </div>
                <button
                  onClick={() => placeOrder(item.item_id)}
                  disabled={placingId === item.item_id}
                >
                  {placingId === item.item_id ? "Adding..." : "Add"}
                </button>
              </li>
            ))}
          </ul>
        )}
        {orderError && <p role="alert">{orderError}</p>}
      </section>

      <div className="flex flex-col gap-8">
        <section>
          <h2>My orders</h2>
          {!orders ? (
            <p className="text-gray-500">Loading orders...</p>
          ) : orders.length === 0 ? (
            <p className="text-gray-500">No orders yet.</p>
          ) : (
            <ul>
              {orders.map((o) => (
                <li key={o.order_line_id} className="card flex items-center justify-between">
                  <span className="text-gray-900">
                    {o.quantity}x {o.item_name}{" "}
                    <span className="text-sm text-gray-500">${o.line_total.toFixed(2)}</span>
                  </span>
                  <span
                    className={`rounded-full px-2.5 py-1 text-xs font-semibold ${statusStyle[o.status] ?? "bg-gray-100 text-gray-700"}`}
                  >
                    {o.status}
                  </span>
                </li>
              ))}
            </ul>
          )}
        </section>

        <section>
          <h2>Bill</h2>
          {!bill ? (
            <p className="text-gray-500">Loading bill...</p>
          ) : (
            <div className="card flex flex-col gap-2">
              <div className="flex justify-between text-sm text-gray-600">
                <span>Buffet total ({bill.guest_count} guests)</span>
                <span>${bill.buffet_total.toFixed(2)}</span>
              </div>
              <div className="flex justify-between text-sm text-gray-600">
                <span>Extra charges</span>
                <span>${bill.extra_charges.toFixed(2)}</span>
              </div>
              <div className="mt-2 flex justify-between border-t border-gray-200 pt-2 text-base font-semibold text-gray-900">
                <span>Running total</span>
                <span>${bill.running_total.toFixed(2)}</span>
              </div>
            </div>
          )}
        </section>
      </div>
    </div>
  );
}

export default function DiningSession() {
  const { id } = useParams();
  const sessionId = Number(id);

  return (
    <>
      <Header />
      <main>
        <div className="page max-w-4xl">
          <p className="text-sm text-gray-500">
            <Link to="/">&larr; Back to branches</Link>
          </p>
          <p className="eyebrow">DINING NOW</p>
          <h1>Dining session #{id}</h1>
          <RequireCustomer>
            <SessionContent sessionId={sessionId} />
          </RequireCustomer>
        </div>
      </main>
    </>
  );
}
