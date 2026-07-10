import { useEffect, useState } from "react";
import { Link } from "react-router";
import { RequireCustomer } from "../lib/guards";
import { api, ApiError } from "../lib/api";
import type { Membership, PointTransaction } from "../lib/types";
import { Header } from "../components/Header";

export function meta() {
  return [{ title: "Profile – Momo Paradise" }];
}

function ProfileContent() {
  const [membership, setMembership] = useState<Membership | null>(null);
  const [points, setPoints] = useState<PointTransaction[] | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    Promise.all([
      api.get<Membership>("/api/me/membership"),
      api.get<PointTransaction[]>("/api/me/points"),
    ])
      .then(([m, p]) => {
        setMembership(m);
        setPoints(p);
      })
      .catch((err) =>
        setError(err instanceof ApiError ? err.message : "Failed to load profile"),
      );
  }, []);

  if (error) return <p role="alert">{error}</p>;
  if (!membership || !points) return <p>Loading profile...</p>;

  return (
    <>
      <h1>{membership.customer_name}</h1>
      <p>Tier: {membership.tier}</p>
      <p>Points: {membership.points}</p>
      <h2>Point history</h2>
      {points.length === 0 ? (
        <p>No point activity yet.</p>
      ) : (
        <ul>
          {points.map((t) => (
            <li key={t.transaction_id}>
              {new Date(t.created_at).toLocaleString()} — {t.type} —{" "}
              {t.change_amount > 0 ? "+" : ""}
              {t.change_amount}
            </li>
          ))}
        </ul>
      )}
    </>
  );
}

export default function Profile() {
  return (
    <>
      <Header />
      <main className="pt-4 p-4 container mx-auto max-w-md">
        <p>
          <Link to="/">&larr; Back to branches</Link>
        </p>
        <RequireCustomer>
          <ProfileContent />
        </RequireCustomer>
      </main>
    </>
  );
}
