import os
from pathlib import Path

from dotenv import load_dotenv
from flask import Flask, jsonify

from .db import ApiError, call_fn, init_pool


def create_app() -> Flask:
    # repo-root .env (backend/app/__init__.py -> two levels up)
    load_dotenv(Path(__file__).resolve().parents[2] / ".env")

    app = Flask(__name__)
    app.secret_key = os.environ["FLASK_SECRET_KEY"]
    app.config["SESSION_COOKIE_HTTPONLY"] = True
    app.config["SESSION_COOKIE_SAMESITE"] = "Lax"

    init_pool(os.environ["MOMO_APP_URL"])

    from . import auth
    app.register_blueprint(auth.bp)

    @app.get("/api/health")
    def health():
        branches = call_fn("fn_get_branches")
        return jsonify({"status": "ok", "branches": len(branches)})

    @app.errorhandler(ApiError)
    def handle_api_error(exc: ApiError):
        return jsonify({"error": exc.message}), exc.status

    return app
