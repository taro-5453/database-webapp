import { useEffect, useState } from "react";
import type { Route } from "./+types/home";
import { Link } from "react-router";
import { api, ApiError } from "../lib/api";
import type { Branch } from "../lib/types";
import { Header } from "../components/Header";

export function meta({}: Route.MetaArgs) {
  return [
    { title: "Momo Paradise" },
    { name: "description", content: "Multi-branch all-you-can-eat shabu/sukiyaki" },
  ];
}

function PinIcon() {
  return (
    <svg viewBox="0 0 20 20" fill="none" className="h-4 w-4 shrink-0 text-gray-400">
      <path
        d="M10 18s6-5.2 6-10a6 6 0 1 0-12 0c0 4.8 6 10 6 10Z"
        stroke="currentColor"
        strokeWidth="1.5"
      />
      <circle cx="10" cy="8" r="2" stroke="currentColor" strokeWidth="1.5" />
    </svg>
  );
}

function PhoneIcon() {
  return (
    <svg viewBox="0 0 20 20" fill="none" className="h-4 w-4 shrink-0 text-gray-400">
      <path
        d="M4.5 3h2.2l1.2 3.4-1.6 1.4a10 10 0 0 0 5.9 5.9l1.4-1.6L17 13.3v2.2c0 .8-.7 1.5-1.5 1.4C8.6 16.4 3.6 11.4 3.1 4.5 3 3.7 3.7 3 4.5 3Z"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinejoin="round"
      />
    </svg>
  );
}

function BranchCard({ branch }: { branch: Branch }) {
  return (
    <div className="flex flex-col rounded-2xl border border-gray-200 bg-white p-6 shadow-sm">
      <h3 className="text-lg font-semibold text-gray-900">{branch.name}</h3>

      <div className="mt-3 flex items-start gap-2 text-sm text-gray-500">
        <span className="mt-0.5">
          <PinIcon />
        </span>
        <span>{branch.address}</span>
      </div>

      <div className="mt-2 flex items-center gap-2 text-sm text-gray-500">
        <PhoneIcon />
        <span>{branch.phone}</span>
      </div>

      <Link
        to={`/branches/${branch.branch_id}`}
        className="mt-5 inline-flex items-center gap-1 text-sm font-semibold text-[#C1502F] hover:text-[#a5432a]"
      >
        Reserve
        <span aria-hidden="true">&rarr;</span>
      </Link>
    </div>
  );
}

function BranchGrid() {
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

  if (!branches) {
    return (
      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3">
        {Array.from({ length: 6 }).map((_, i) => (
          <div
            key={i}
            className="h-40 animate-pulse rounded-2xl border border-gray-200 bg-gray-50"
          />
        ))}
      </div>
    );
  }

  return (
    <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3">
      {branches.map((b) => (
        <BranchCard key={b.branch_id} branch={b} />
      ))}
    </div>
  );
}

export default function Home() {
  return (
    <>
      <Header />
      <main className="min-h-screen bg-white">
        <div className="container mx-auto px-4 py-10">
          <p className="text-sm font-bold tracking-wide text-[#C1502F]">
            SHABU &amp; SUKIYAKI BUFFET
          </p>
          <h1 className="mt-2 text-4xl font-bold text-gray-900">Find your table</h1>
          <p className="mt-2 text-gray-500">
            Choose a branch to reserve a time slot or join the walk-in queue.
          </p>

          <div className="mt-8">
            <BranchGrid />
          </div>
        </div>
      </main>
    </>
  );
}
