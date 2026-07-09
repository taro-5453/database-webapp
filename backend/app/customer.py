"""Phases 2+3 — customer endpoints.

Public: branches + available tables (needed before login to book).
Logged-in: membership, points, reservations, and the dining-session
flow (menu -> order -> live bill). customer_id always comes from
the session cookie, never from the URL or body; dining-session
routes verify ownership through fn_get_session_owner.
"""
from datetime import datetime

from flask import Blueprint, jsonify, request, session

from .auth import customer_required
from .db import ApiError, call_fn, call_fn_scalar
from .util import int_field

bp = Blueprint("customer", __name__, url_prefix="/api")


def _owned_session(session_id: int) -> None:
    """404 if the dining session doesn't exist, 403 if it isn't ours."""
    rows = call_fn("fn_get_session_owner", session_id)
    if not rows:
        raise ApiError(404, f"dining session {session_id} does not exist")
    if rows[0]["customer_id"] != session["customer_id"]:
        raise ApiError(403, "this dining session belongs to another customer")


@bp.get("/branches")
def branches():
    return jsonify(call_fn("fn_get_branches"))


@bp.get("/branches/<int:branch_id>/available-tables")
def available_tables(branch_id: int):
    party_size = request.args.get("party_size", type=int)
    if party_size is None or party_size < 1:
        raise ApiError(400, "party_size (positive integer) is required")
    return jsonify(call_fn("fn_get_available_tables", branch_id, party_size))


@bp.get("/me/membership")
@customer_required
def my_membership():
    rows = call_fn("fn_get_membership", session["customer_id"])
    if not rows:  # possible for accounts predating auto-membership
        raise ApiError(404, "no membership found for this account")
    return jsonify(rows[0])


@bp.get("/me/points")
@customer_required
def my_points():
    return jsonify(call_fn("fn_get_point_history", session["customer_id"]))


# ---------- Phase 3: reservations + the dining-session flow ----------

@bp.post("/reservations")
@customer_required
def create_reservation():
    data = request.get_json(silent=True) or {}
    branch_id = int_field(data, "branch_id")
    party_size = int_field(data, "party_size")
    table_id = int_field(data, "table_id", required=False)

    slot_time = None  # NULL slot_time = join the walk-in queue
    if data.get("slot_time"):
        try:
            slot_time = datetime.fromisoformat(data["slot_time"])
        except (TypeError, ValueError):
            raise ApiError(400, "slot_time must be ISO 8601, e.g. 2026-07-15T18:00:00")

    reservation_id = call_fn_scalar(
        "fn_create_reservation",
        session["customer_id"], branch_id, table_id, slot_time, party_size,
    )
    status = "queued" if slot_time is None else "reserved"
    return jsonify({"reservation_id": reservation_id, "status": status}), 201


@bp.get("/dining-sessions/<int:session_id>/menu")
@customer_required
def session_menu(session_id: int):
    _owned_session(session_id)
    return jsonify(call_fn("fn_get_tier_menu", session_id))


@bp.post("/dining-sessions/<int:session_id>/orders")
@customer_required
def place_order(session_id: int):
    _owned_session(session_id)
    data = request.get_json(silent=True) or {}
    item_id = int_field(data, "item_id")
    quantity = int_field(data, "quantity")
    order_line_id = call_fn_scalar("fn_place_order", session_id, item_id, quantity)
    return jsonify({"order_line_id": order_line_id}), 201


@bp.get("/dining-sessions/<int:session_id>/orders")
@customer_required
def session_orders(session_id: int):
    _owned_session(session_id)
    return jsonify(call_fn("fn_get_session_orders", session_id))


@bp.get("/dining-sessions/<int:session_id>/bill")
@customer_required
def session_bill(session_id: int):
    _owned_session(session_id)
    rows = call_fn("fn_get_current_bill", session_id)
    if not rows:
        raise ApiError(404, "no bill data for this session")
    return jsonify(rows[0])
