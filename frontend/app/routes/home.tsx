import type { Route } from "./+types/home";
import { Link } from "react-router";
import { Welcome } from "../welcome/welcome";
import { useAuth } from "../lib/auth";

export function meta({}: Route.MetaArgs) {
  return [
    { title: "New React Router App" },
    { name: "description", content: "Welcome to React Router!" },
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
      {" · "}
      <button onClick={() => logout()}>Log out</button>
    </p>
  );
}

export default function Home() {
  return (
    <>
      <div className="p-4 text-center">
        <AuthStatus />
      </div>
      <Welcome />
    </>
  );
}
