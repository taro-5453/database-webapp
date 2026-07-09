"""Entry point: python backend/wsgi.py (dev) or gunicorn backend.wsgi:app."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from app import create_app

app = create_app()

if __name__ == "__main__":
    app.run(port=5001, debug=True)
