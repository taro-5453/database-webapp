"""Phase 2 — customer browse endpoints (read-only).

Public: branches + available tables (needed before login to book).
Logged-in: membership + point history; customer_id always comes
from the session cookie, never from the URL or body.
"""
from flask import Blueprint, jsonify, request, session

from .auth import customer_required
from .db import ApiError, call_fn

bp = Blueprint("customer", __name__, url_prefix="/api")


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
