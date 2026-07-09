import { useState } from "react";
import { useNavigate, Link } from "react-router";
import { useAuth } from "../lib/auth";
import { ApiError } from "../lib/api";

export function meta() {
  return [{ title: "Staff log in – Momo Paradise" }];
}

export default function StaffLogin() {
  const { staffLogin } = useAuth();
  const navigate = useNavigate();
  const [name, setName] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setSubmitting(true);
    try {
      await staffLogin(name, password);
      navigate("/");
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Something went wrong");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <main className="pt-16 p-4 container mx-auto max-w-sm">
      <h1>Staff log in</h1>
      <form onSubmit={handleSubmit}>
        <label>
          Name
          <input value={name} onChange={(e) => setName(e.target.value)} required />
        </label>
        <label>
          Password
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />
        </label>
        {error && <p role="alert">{error}</p>}
        <button type="submit" disabled={submitting}>
          {submitting ? "Logging in..." : "Log in"}
        </button>
      </form>
      <p>
        Not staff? <Link to="/login">Customer log in</Link>
      </p>
    </main>
  );
}
