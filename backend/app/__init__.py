import datetime
import decimal
import os
from pathlib import Path

from dotenv import load_dotenv
from flask import Flask, jsonify
from flask.json.provider import DefaultJSONProvider
from flask_cors import CORS

from .db import ApiError, call_fn, init_pool


class DbJSONProvider(DefaultJSONProvider):
    """DECIMAL columns -> float, timestamps -> ISO 8601 strings."""

    @staticmethod
    def default(obj):
        if isinstance(obj, decimal.Decimal):
            return float(obj)
        if isinstance(obj, (datetime.datetime, datetime.date, datetime.time)):
            return obj.isoformat()
        return DefaultJSONProvider.default(obj)


def create_app() -> Flask:
    # repo-root .env (backend/app/__init__.py -> two levels up)
    load_dotenv(Path(__file__).resolve().parents[2] / ".env")

    app = Flask(__name__)
    app.json = DbJSONProvider(app)
    app.secret_key = os.environ["FLASK_SECRET_KEY"]
    app.config["SESSION_COOKIE_HTTPONLY"] = True
    app.config["SESSION_COOKIE_SAMESITE"] = "Lax"

    # the browser frontend's origin; credentials lets the session
    # cookie ride along on fetch() calls
    frontend_origin = os.environ.get("FRONTEND_ORIGIN", "http://localhost:3000")
    CORS(app, origins=[frontend_origin], supports_credentials=True)

    # set COOKIE_CROSS_SITE=1 when the deployed frontend lives on a
    # DIFFERENT domain than the API (e.g. Vercel + Render): browsers
    # only send cross-site cookies with SameSite=None + Secure
    if os.environ.get("COOKIE_CROSS_SITE") == "1":
        app.config["SESSION_COOKIE_SAMESITE"] = "None"
        app.config["SESSION_COOKIE_SECURE"] = True

    init_pool(os.environ["MOMO_APP_URL"])

    from . import auth, customer, staff
    app.register_blueprint(auth.bp)
    app.register_blueprint(customer.bp)
    app.register_blueprint(staff.bp)

    @app.get("/api/health")
    def health():
        branches = call_fn("fn_get_branches")
        return jsonify({"status": "ok", "branches": len(branches)})

    @app.errorhandler(ApiError)
    def handle_api_error(exc: ApiError):
        return jsonify({"error": exc.message}), exc.status

    # JSON errors everywhere — an API should never answer with an
    # HTML error page
    @app.errorhandler(404)
    def not_found(_):
        return jsonify({"error": "not found"}), 404

    @app.errorhandler(405)
    def method_not_allowed(_):
        return jsonify({"error": "method not allowed"}), 405

    @app.errorhandler(500)
    def internal_error(_):
        return jsonify({"error": "internal server error"}), 500

    return app
