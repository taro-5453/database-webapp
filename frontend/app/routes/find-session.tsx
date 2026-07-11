import { useState } from "react";
import { Link, useNavigate } from "react-router";
import { Header } from "../components/Header";
import { RequireCustomer } from "../lib/guards";

export function meta() {
  return [{ title: "My Session – Momo Paradise" }];
}

function FindSessionForm() {
  const navigate = useNavigate();
  const [sessionId, setSessionId] = useState("");

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    const id = sessionId.trim();
    if (id) navigate(`/session/${id}`);
  }

  return (
    <>
      <p className="eyebrow">DINE IN</p>
      <h1>Open my session</h1>
      <p className="text-sm text-gray-600">
        Once you're seated, staff will give you a session number. Enter it here to see
        the menu, order dishes, and track your bill.
      </p>
      <form onSubmit={handleSubmit}>
        <label>
          Session number
          <input
            type="number"
            min={1}
            value={sessionId}
            onChange={(e) => setSessionId(e.target.value)}
            placeholder="e.g. 36"
            required
          />
        </label>
        <button type="submit" disabled={!sessionId.trim()}>
          Go to my session
        </button>
      </form>
    </>
  );
}

export default function FindSession() {
  return (
    <>
      <Header />
      <main>
        <div className="page max-w-sm">
          <p className="text-sm text-gray-500">
            <Link to="/">&larr; Back to branches</Link>
          </p>
          <RequireCustomer>
            <FindSessionForm />
          </RequireCustomer>
        </div>
      </main>
    </>
  );
}
