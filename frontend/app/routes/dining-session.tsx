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

  return (
    <>
      <section>
        <h2>Menu</h2>
        {!menu ? (
          <p>Loading menu...</p>
        ) : (
          <ul>
            {menu.map((item) => (
              <li key={item.item_id}>
                {item.name} ({item.category}) — ${item.price.toFixed(2)}{" "}
                <button
                  onClick={() => placeOrder(item.item_id)}
                  disabled={placingId === item.item_id}
                >
                  {placingId === item.item_id ? "Adding..." : "Add to order"}
                </button>
              </li>
            ))}
          </ul>
        )}
        {orderError && <p role="alert">{orderError}</p>}
      </section>

      <section>
        <h2>My orders</h2>
        {!orders ? (
          <p>Loading orders...</p>
        ) : orders.length === 0 ? (
          <p>No orders yet.</p>
        ) : (
          <ul>
            {orders.map((o) => (
              <li key={o.order_line_id}>
                {o.quantity}x {o.item_name} — ${o.line_total.toFixed(2)} ({o.status})
              </li>
            ))}
          </ul>
        )}
      </section>

      <section>
        <h2>Bill</h2>
        {!bill ? (
          <p>Loading bill...</p>
        ) : (
          <ul>
            <li>
              Buffet total ({bill.guest_count} guests): ${bill.buffet_total.toFixed(2)}
            </li>
            <li>Extra charges: ${bill.extra_charges.toFixed(2)}</li>
            <li>
              <strong>Running total: ${bill.running_total.toFixed(2)}</strong>
            </li>
          </ul>
        )}
      </section>
    </>
  );
}

export default function DiningSession() {
  const { id } = useParams();
  const sessionId = Number(id);

  return (
    <>
      <Header />
      <main className="pt-4 p-4 container mx-auto max-w-2xl">
        <p>
          <Link to="/">&larr; Back to branches</Link>
        </p>
        <h1>Dining session #{id}</h1>
        <RequireCustomer>
          <SessionContent sessionId={sessionId} />
        </RequireCustomer>
      </main>
    </>
  );
}
