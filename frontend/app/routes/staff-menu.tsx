import { useCallback, useEffect, useState } from "react";
import { Link } from "react-router";
import { Header } from "../components/Header";
import { RequireStaff } from "../lib/guards";
import { api, ApiError } from "../lib/api";
import type { MenuItem, Tier } from "../lib/types";

export function meta() {
  return [{ title: "Manage Menu – Momo Paradise" }];
}

function AddItemForm({ tiers, onAdded }: { tiers: Tier[] | null; onAdded: () => void }) {
  const [name, setName] = useState("");
  const [category, setCategory] = useState("");
  const [price, setPrice] = useState(0);
  const [tierIds, setTierIds] = useState<number[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  function toggleTier(id: number) {
    setTierIds((prev) => (prev.includes(id) ? prev.filter((t) => t !== id) : [...prev, id]));
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setSubmitting(true);
    try {
      await api.post("/api/staff/menu-items", {
        name,
        category: category || undefined,
        price,
        tier_ids: tierIds.length > 0 ? tierIds : undefined,
      });
      setName("");
      setCategory("");
      setPrice(0);
      setTierIds([]);
      onAdded();
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to add item");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <form onSubmit={handleSubmit}>
      <label>
        Name
        <input value={name} onChange={(e) => setName(e.target.value)} required />
      </label>
      <label>
        Category
        <input value={category} onChange={(e) => setCategory(e.target.value)} />
      </label>
      <label>
        Price (0 = buffet-included)
        <input
          type="number"
          min={0}
          step="0.01"
          value={price}
          onChange={(e) => setPrice(Number(e.target.value))}
          required
        />
      </label>
      <fieldset>
        <legend>Available to tiers</legend>
        {!tiers ? (
          <p className="text-gray-500">Loading tiers...</p>
        ) : (
          tiers.map((t) => (
            <label key={t.tier_id}>
              <input
                type="checkbox"
                checked={tierIds.includes(t.tier_id)}
                onChange={() => toggleTier(t.tier_id)}
              />
              {t.name}
            </label>
          ))
        )}
      </fieldset>
      {error && <p role="alert">{error}</p>}
      <button type="submit" disabled={submitting}>
        {submitting ? "Adding..." : "Add item"}
      </button>
    </form>
  );
}

function ItemsList() {
  const [items, setItems] = useState<MenuItem[] | null>(null);
  const [tiers, setTiers] = useState<Tier[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [togglingId, setTogglingId] = useState<number | null>(null);

  const refresh = useCallback(async () => {
    try {
      setItems(await api.get<MenuItem[]>("/api/staff/menu-items"));
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to load menu items");
    }
  }, []);

  useEffect(() => {
    refresh();
    api.get<Tier[]>("/api/staff/tiers").then(setTiers);
  }, [refresh]);

  async function toggleAvailability(item: MenuItem) {
    setTogglingId(item.item_id);
    setError(null);
    try {
      await api.patch(`/api/staff/menu-items/${item.item_id}/availability`, {
        available: !item.available,
      });
      await refresh();
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to update item");
    } finally {
      setTogglingId(null);
    }
  }

  return (
    <>
      <h2>Add item</h2>
      <AddItemForm tiers={tiers} onAdded={refresh} />

      <h2>Items</h2>
      {error && <p role="alert">{error}</p>}
      {!items ? (
        <p className="text-gray-500">Loading items...</p>
      ) : items.length === 0 ? (
        <p className="text-gray-500">No items yet.</p>
      ) : (
        <ul>
          {items.map((item) => (
            <li
              key={item.item_id}
              className={"card flex items-center justify-between" + (item.available ? "" : " opacity-50")}
            >
              <div>
                <p className="font-medium text-gray-900">{item.name}</p>
                <p className="text-sm text-gray-500">
                  {item.category} · ${item.price.toFixed(2)}
                </p>
              </div>
              <button
                onClick={() => toggleAvailability(item)}
                disabled={togglingId === item.item_id}
              >
                {togglingId === item.item_id
                  ? "Updating..."
                  : item.available
                    ? "Mark unavailable"
                    : "Mark available"}
              </button>
            </li>
          ))}
        </ul>
      )}
    </>
  );
}

export default function StaffMenu() {
  return (
    <>
      <Header />
      <main>
        <div className="page max-w-2xl">
          <p className="text-sm text-gray-500">
            <Link to="/staff">&larr; Dashboard</Link>
          </p>
          <p className="eyebrow">STAFF</p>
          <h1>Manage menu</h1>
          <RequireStaff>
            <ItemsList />
          </RequireStaff>
        </div>
      </main>
    </>
  );
}
