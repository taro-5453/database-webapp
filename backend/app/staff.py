"""Phase 4 — staff floor operations.

The queue -> seat -> open session -> dashboard loop. branch_id and
staff_id always come from the staff session cookie, never from the
request, so staff can only act at their own branch (the SQL
functions double-check this and raise if e.g. a table belongs to a
different branch).
"""
from datetime import date

from flask import Blueprint, jsonify, request, session

from .auth import staff_required
from .db import ApiError, call_fn, call_fn_scalar
from .util import bool_field, int_field, num_field, str_field

bp = Blueprint("staff", __name__, url_prefix="/api/staff")


@bp.get("/queue")
@staff_required
def queue():
    return jsonify(call_fn("fn_get_queue", session["branch_id"]))


@bp.post("/reservations/<int:reservation_id>/seat")
@staff_required
def seat_reservation(reservation_id: int):
    data = request.get_json(silent=True) or {}
    # a big party can combine several tables, so this takes a list;
    # a bare table_id is still accepted for single-table seatings
    table_ids = data.get("table_ids")
    if table_ids is None:
        table_ids = [int_field(data, "table_id")]
    if (
        not isinstance(table_ids, list)
        or not table_ids
        or not all(isinstance(t, int) and not isinstance(t, bool) for t in table_ids)
    ):
        raise ApiError(400, "table_ids must be a non-empty list of integers")
    call_fn_scalar("fn_seat_reservation",
                   reservation_id, table_ids, session["staff_id"])
    return jsonify({"reservation_id": reservation_id,
                    "table_ids": table_ids,
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


@bp.get("/tiers")
@staff_required
def tiers():
    """The staff member's branch's buffet tiers — fills the tier
    picker on the open-session and add-menu-item screens."""
    return jsonify(call_fn("fn_get_tiers", session["branch_id"]))


# ---------- Phase 5: kitchen, menu, promotions, checkout ----------

@bp.get("/kitchen")
@staff_required
def kitchen():
    """Unserved order lines for active sessions at this branch."""
    return jsonify(call_fn("fn_get_kitchen_orders", session["branch_id"]))


@bp.patch("/orders/<int:order_line_id>")
@staff_required
def update_order_status(order_line_id: int):
    data = request.get_json(silent=True) or {}
    status = str_field(data, "status")  # fn allows ordered/preparing/served
    call_fn_scalar("fn_update_order_status", order_line_id, status)
    return jsonify({"order_line_id": order_line_id, "status": status})


@bp.get("/menu-items")
@staff_required
def menu_items():
    """Every item at the staff member's branch, available or not —
    fills the manage-menu screen's item list."""
    return jsonify(call_fn("fn_get_menu_items", session["branch_id"]))


@bp.post("/menu-items")
@staff_required
def add_menu_item():
    data = request.get_json(silent=True) or {}
    tier_ids = data.get("tier_ids")  # optional: tiers that may order it
    if tier_ids is not None and (
        not isinstance(tier_ids, list)
        or not all(isinstance(t, int) and not isinstance(t, bool) for t in tier_ids)
    ):
        raise ApiError(400, "tier_ids must be a list of integers")
    item_id = call_fn_scalar(
        "fn_add_menu_item",
        session["branch_id"],
        str_field(data, "name"),
        str_field(data, "category", required=False),
        num_field(data, "price"),
        tier_ids,
    )
    return jsonify({"item_id": item_id}), 201


@bp.patch("/menu-items/<int:item_id>/availability")
@staff_required
def update_item_availability(item_id: int):
    data = request.get_json(silent=True) or {}
    available = bool_field(data, "available")
    call_fn_scalar("fn_update_item_availability", item_id, available)
    return jsonify({"item_id": item_id, "available": available})


@bp.get("/promotions")
@staff_required
def promotions():
    return jsonify(call_fn("fn_get_promotions"))


@bp.post("/promotions")
@staff_required
def create_promotion():
    data = request.get_json(silent=True) or {}
    valid_until = None  # None = never expires
    if data.get("valid_until"):
        try:
            valid_until = date.fromisoformat(data["valid_until"])
        except (TypeError, ValueError):
            raise ApiError(400, "valid_until must be a date, e.g. 2026-12-31")
    promotion_id = call_fn_scalar(
        "fn_create_promotion",
        session["staff_id"],
        str_field(data, "code"),
        num_field(data, "discount"),
        str_field(data, "discount_type"),  # percent | fixed
        valid_until,
    )
    return jsonify({"promotion_id": promotion_id}), 201


@bp.get("/promotions/validate")
@staff_required
def validate_promotion():
    code = (request.args.get("code") or "").strip().upper()
    if not code:
        raise ApiError(400, "code query parameter is required")
    rows = call_fn("fn_validate_promotion", code)
    if not rows:  # code doesn't exist at all
        return jsonify({"code": code, "is_valid": False})
    return jsonify({"code": code, **rows[0]})


@bp.post("/dining-sessions/<int:session_id>/checkout")
@staff_required
def checkout(session_id: int):
    data = request.get_json(silent=True) or {}
    code = str_field(data, "promotion_code", required=False)
    bill_id = call_fn_scalar(
        "fn_checkout",
        session_id,
        code.upper() if code else None,  # codes are stored UPPERCASE
        str_field(data, "payment_method", required=False) or "cash",
    )
    return jsonify({"bill_id": bill_id}), 201


@bp.get("/bills/<int:bill_id>")
@staff_required
def get_bill(bill_id: int):
    """The receipt for a finished bill (shown after checkout)."""
    rows = call_fn("fn_get_bill", bill_id)
    if not rows:
        raise ApiError(404, f"bill {bill_id} does not exist")
    return jsonify(rows[0])


@bp.get("/dining-sessions/<int:session_id>/orders")
@staff_required
def session_orders(session_id: int):
    """Every dish ordered in a session (for the itemized receipt).
    Reuses fn_get_session_orders; works on closed sessions too."""
    return jsonify(call_fn("fn_get_session_orders", session_id))
