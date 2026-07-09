"""Database access: a connection pool as momo_app and the one
helper every endpoint uses, call_fn().

The role can ONLY execute fn_* functions (see database/security.sql),
so this module deliberately offers no way to run arbitrary SQL.
"""
import atexit
import re

import psycopg
from psycopg.rows import dict_row
from psycopg_pool import ConnectionPool


class ApiError(Exception):
    """Carries an HTTP status + message to the Flask error handler."""

    def __init__(self, status: int, message: str):
        super().__init__(message)
        self.status = status
        self.message = message


_pool: ConnectionPool | None = None

# fn names come from our own code, never from requests; the regex is
# a guard against future misuse, not input validation
_FN_NAME = re.compile(r"^fn_[a-z0-9_]+$")


def init_pool(conninfo: str) -> None:
    global _pool
    _pool = ConnectionPool(
        conninfo,
        min_size=1,
        max_size=5,
        kwargs={"row_factory": dict_row},
        open=True,
    )
    # close cleanly on interpreter exit; without this an aborted
    # startup prints a PythonFinalizationError traceback
    atexit.register(_pool.close)


def call_fn(name: str, *args) -> list[dict]:
    """SELECT * FROM fn_x(%s, ...) with parameterized args.

    Returns a list of row dicts (empty for e.g. a failed login).
    plpgsql RAISE EXCEPTION (a business-rule rejection) becomes
    ApiError(400) with the function's own message.
    """
    if not _FN_NAME.match(name):
        raise ValueError(f"not a fn_* function: {name}")
    placeholders = ", ".join(["%s"] * len(args))
    query = f"SELECT * FROM {name}({placeholders})"
    try:
        with _pool.connection() as conn:
            return conn.execute(query, args).fetchall()
    except psycopg.errors.RaiseException as exc:
        raise ApiError(400, exc.diag.message_primary or "rejected by database")
    except psycopg.OperationalError as exc:
        raise ApiError(503, "database unavailable") from exc


def call_fn_scalar(name: str, *args):
    """For fns returning a single value (the new row's id)."""
    rows = call_fn(name, *args)
    if not rows:
        return None
    return next(iter(rows[0].values()))
