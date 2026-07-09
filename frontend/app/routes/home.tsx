import { useEffect, useState } from "react";
import type { Route } from "./+types/home";
import { Link } from "react-router";
import { useAuth } from "../lib/auth";
import { api, ApiError } from "../lib/api";
import type { Branch } from "../lib/types";

export function meta({}: Route.MetaArgs) {
  return [
    { title: "Momo Paradise" },
    { name: "description", content: "Multi-branch all-you-can-eat shabu/sukiyaki" },
  ];
}

function AuthStatus() {
  const { user, loading, logout } = useAuth();

  if (loading) return <p>Checking session...</p>;

  if (!user) {
    return (
      <p>
        Not logged in. <Link to="/login">Log in</Link> ·{" "}
        <Link to="/register">Register</Link> ·{" "}
        <Link to="/staff/login">Staff log in</Link>
      </p>
    );
  }

  return (
    <p>
      Logged in as <strong>{user.name}</strong> ({user.kind})
      {user.kind === "customer" && (
        <>
          {" · "}
          <Link to="/profile">Profile</Link>
        </>
      )}
      {" · "}
      <button onClick={() => logout()}>Log out</button>
    </p>
  );
}

function BranchList() {
  const [branches, setBranches] = useState<Branch[] | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    api
      .get<Branch[]>("/api/branches")
      .then(setBranches)
      .catch((err) =>
        setError(err instanceof ApiError ? err.message : "Failed to load branches"),
      );
  }, []);

  if (error) return <p role="alert">{error}</p>;
  if (!branches) return <p>Loading branches...</p>;

  return (
    <ul>
      {branches.map((b) => (
        <li key={b.branch_id}>
          <Link to={`/branches/${b.branch_id}`}>{b.name}</Link>
          <div>
            {b.address} · {b.phone}
          </div>
        </li>
      ))}
    </ul>
  );
}

export default function Home() {
  return (
    <main className="pt-16 p-4 container mx-auto">
      <AuthStatus />
      <h1>Branches</h1>
      <BranchList />
    </main>
  );
}
