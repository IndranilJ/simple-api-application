"""
Cloud Run-compatible Celery worker entrypoint.

Cloud Run requires every container to listen on an HTTP port.
This script starts a minimal health-check HTTP server on PORT (default 8080)
in a background thread, then starts the Celery worker in the main thread.
"""
import os
import threading
import http.server

PORT = int(os.environ.get("PORT", 8080))


class HealthHandler(http.server.BaseHTTPRequestHandler):
    """Minimal HTTP handler — responds 200 OK to any GET for Cloud Run health checks."""

    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"healthy")

    def log_message(self, *args):
        pass  # suppress noisy access logs


def start_health_server():
    server = http.server.HTTPServer(("", PORT), HealthHandler)
    server.serve_forever()


# Start health server in background daemon thread
t = threading.Thread(target=start_health_server, daemon=True)
t.start()
print(f"[worker] Health check server running on port {PORT}", flush=True)

# Start Celery worker — blocks in the main thread
from app.celery_app import celery_app  # noqa: E402

worker = celery_app.Worker(pool="solo", loglevel="info")
worker.start()
