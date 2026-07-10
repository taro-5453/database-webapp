import { useState } from "react";
import { useNavigate, Link } from "react-router";
import { useAuth } from "../lib/auth";
import { ApiError } from "../lib/api";
import { Header } from "../components/Header";

export function meta() {
  return [{ title: "Log in – Momo Paradise" }];
}

export default function Login() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setSubmitting(true);
    try {
      await login(email, password);
      navigate("/");
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Something went wrong");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <>
      <Header />
      <main>
        <div className="page max-w-sm">
          <p className="eyebrow">WELCOME BACK</p>
          <h1>Log in</h1>
          <form onSubmit={handleSubmit}>
            <label>
              Email
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
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
          <p className="text-sm text-gray-500">
            No account? <Link to="/register">Register</Link>
          </p>
          <p className="text-sm text-gray-500">
            Staff? <Link to="/staff/login">Staff log in</Link>
          </p>
        </div>
      </main>
    </>
  );
}
