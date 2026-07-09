"""Auth endpoints + the decorators later phases use to guard routes.

Identity lives in Flask's signed session cookie. Route handlers must
always take customer_id/staff_id/branch_id from the cookie, never
from the request body or URL.
"""
from functools import wraps

from flask import Blueprint, jsonify, request, session

from .db import ApiError, call_fn, call_fn_scalar

bp = Blueprint("auth", __name__, url_prefix="/api/auth")


def _json_body() -> dict:
    return request.get_json(silent=True) or {}


def _require(data: dict, *fields) -> None:
    missing = [f for f in fields if not data.get(f)]
    if missing:
        raise ApiError(400, f"missing required field(s): {', '.join(missing)}")


@bp.post("/register")
def register():
    data = _json_body()
    _require(data, "name", "email", "password")
    customer_id = call_fn_scalar(
        "fn_register_customer",
        data["name"], data["email"], data.get("phone"), data["password"],
    )
    session.clear()
    session.update(kind="customer", customer_id=customer_id,
                   name=data["name"].strip())
    return jsonify({"customer_id": customer_id}), 201


@bp.post("/login")
def login():
    data = _json_body()
    _require(data, "email", "password")
    rows = call_fn("fn_login_customer", data["email"], data["password"])
    if not rows:  # the fn returns 0 rows on bad email OR password
        raise ApiError(401, "invalid email or password")
    customer = rows[0]
    session.clear()
    session.update(kind="customer", customer_id=customer["customer_id"],
                   name=customer["name"])
    return jsonify(customer)


@bp.post("/staff-login")
def staff_login():
    data = _json_body()
    _require(data, "name", "password")
    rows = call_fn("fn_login_staff", data["name"], data["password"])
    if not rows:
        raise ApiError(401, "invalid name or password")
    staff = rows[0]
    session.clear()
    session.update(kind="staff", staff_id=staff["staff_id"],
                   branch_id=staff["branch_id"], name=staff["name"],
                   role=staff["role"])
    return jsonify(staff)


@bp.post("/logout")
def logout():
    session.clear()
    return jsonify({"ok": True})


@bp.get("/me")
def me():
    if "kind" not in session:
        raise ApiError(401, "not logged in")
    return jsonify(dict(session))


def customer_required(view):
    @wraps(view)
    def wrapped(*args, **kwargs):
        if session.get("kind") != "customer":
            raise ApiError(401, "customer login required")
        return view(*args, **kwargs)
    return wrapped


def staff_required(view):
    @wraps(view)
    def wrapped(*args, **kwargs):
        if session.get("kind") != "staff":
            raise ApiError(401, "staff login required")
        return view(*args, **kwargs)
    return wrapped
