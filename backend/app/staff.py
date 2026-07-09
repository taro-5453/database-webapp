"""Phase 4 — staff floor operations.

The queue -> seat -> open session -> dashboard loop. branch_id and
staff_id always come from the staff session cookie, never from the
request, so staff can only act at their own branch (the SQL
functions double-check this and raise if e.g. a table belongs to a
different branch).
"""
from flask import Blueprint, jsonify, request, session

from .auth import staff_required
from .db import call_fn, call_fn_scalar
from .util import int_field

bp = Blueprint("staff", __name__, url_prefix="/api/staff")


@bp.get("/queue")
@staff_required
def queue():
    return jsonify(call_fn("fn_get_queue", session["branch_id"]))


@bp.post("/reservations/<int:reservation_id>/seat")
@staff_required
def seat_reservation(reservation_id: int):
    data = request.get_json(silent=True) or {}
    table_id = int_field(data, "table_id")
    call_fn_scalar("fn_seat_reservation",
                   reservation_id, table_id, session["staff_id"])
    return jsonify({"reservation_id": reservation_id,
                    "table_id": table_id,
                    "status": "seated"})


@bp.post("/dining-sessions")
@staff_required
def open_session():
    data = request.get_json(silent=True) or {}
    session_id = call_fn_scalar(
        "fn_open_session",
        int_field(data, "reservation_id", required=False),  # NULL = walk-in
        session["branch_id"],
        int_field(data, "table_id"),
        int_field(data, "customer_id"),
        int_field(data, "tier_id"),
        session["staff_id"],
        int_field(data, "guest_count"),
    )
    return jsonify({"session_id": session_id}), 201


@bp.get("/dining-sessions")
@staff_required
def active_sessions():
    return jsonify(call_fn("fn_get_active_sessions", session["branch_id"]))
