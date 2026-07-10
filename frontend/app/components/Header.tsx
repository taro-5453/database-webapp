import { Link } from "react-router";
import { useAuth } from "../lib/auth";

export function Header() {
  const { user, loading, logout } = useAuth();

  return (
    <header className="sticky top-0 z-10 bg-[#6B2A22] text-white">
      <div className="container mx-auto flex items-center justify-between px-4 py-3">
        <Link to="/" className="flex items-center gap-2 text-lg font-semibold tracking-tight">
          <span aria-hidden="true">🍲</span>
          Momo Paradise
        </Link>

        <nav className="flex items-center gap-5 text-sm font-medium">
          {loading ? null : user ? (
            <>
              {user.kind === "customer" ? (
                <>
                  <Link to="/reserve" className="hover:text-white/80">
                    Reserve
                  </Link>
                  <Link to="/profile" className="hover:text-white/80">
                    {user.name}
                  </Link>
                </>
              ) : (
                <span className="text-white/90">
                  {user.name} · {user.role}
                </span>
              )}
              <button
                onClick={() => logout()}
                className="!self-auto rounded-md !bg-white/10 px-3 !py-1.5 font-medium !text-white hover:!bg-white/20"
              >
                Log out
              </button>
            </>
          ) : (
            <>
              <Link to="/login" className="hover:text-white/80">
                Log in
              </Link>
              <Link to="/register" className="hover:text-white/80">
                Sign up
              </Link>
              <Link to="/staff/login" className="text-white/70 hover:text-white/90">
                Staff
              </Link>
            </>
          )}
        </nav>
      </div>
    </header>
  );
}
