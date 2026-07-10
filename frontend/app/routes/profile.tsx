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
      <p className="eyebrow">MY ACCOUNT</p>
      <h1>{membership.customer_name}</h1>
      <div className="card mt-4 flex max-w-sm items-center justify-between">
        <div>
          <p className="text-sm text-gray-500">Membership tier</p>
          <p className="text-lg font-semibold text-gray-900 capitalize">
            {membership.tier}
          </p>
        </div>
        <div className="text-right">
          <p className="text-sm text-gray-500">Points</p>
          <p className="text-lg font-semibold text-[#C1502F]">{membership.points}</p>
        </div>
      </div>
      <h2>Point history</h2>
      {points.length === 0 ? (
        <p className="text-gray-500">No point activity yet.</p>
      ) : (
        <ul>
          {points.map((t) => (
            <li key={t.transaction_id} className="card flex items-center justify-between">
              <span className="text-sm text-gray-500">
                {new Date(t.created_at).toLocaleString()} · {t.type}
              </span>
              <span
                className={
                  t.change_amount > 0
                    ? "font-semibold text-green-600"
                    : "font-semibold text-gray-900"
                }
              >
                {t.change_amount > 0 ? "+" : ""}
                {t.change_amount}
              </span>
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
      <main>
        <div className="page max-w-md">
          <p className="text-sm text-gray-500">
            <Link to="/">&larr; Back to branches</Link>
          </p>
          <RequireCustomer>
            <ProfileContent />
          </RequireCustomer>
        </div>
      </main>
    </>
  );
}
