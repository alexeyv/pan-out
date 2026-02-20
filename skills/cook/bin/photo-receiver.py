#!/usr/bin/env python3
"""
Pan Out photo receiver.

Listens for incoming photo POSTs and saves them to the session inbox directory.
Accepts both raw binary bodies and multipart/form-data uploads.

Usage: photo-receiver.py <inbox_dir> [port]

Prints to stdout:
  READY: Listening on port <N>   — startup confirmation
  PHOTO: <filepath>              — each time a photo arrives
"""

import sys
import os
import datetime
import cgi
from http.server import HTTPServer, BaseHTTPRequestHandler


class PhotoHandler(BaseHTTPRequestHandler):
    inbox_dir = None

    def do_POST(self):
        content_type = self.headers.get("Content-Type", "")
        timestamp = datetime.datetime.now().strftime("%H%M%S")
        filepath = os.path.join(self.inbox_dir, f"photo-{timestamp}.jpg")

        try:
            if "multipart" in content_type:
                form = cgi.FieldStorage(
                    fp=self.rfile,
                    headers=self.headers,
                    environ={"REQUEST_METHOD": "POST", "CONTENT_TYPE": content_type},
                )
                data = None
                for key in form.keys():
                    item = form[key]
                    if hasattr(item, "file"):
                        data = item.file.read()
                        break
            else:
                length = int(self.headers.get("Content-Length", 0))
                data = self.rfile.read(length)

            if data:
                with open(filepath, "wb") as f:
                    f.write(data)
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b"OK")
                print(f"PHOTO: {filepath}", flush=True)
            else:
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b"No image data received")

        except Exception as e:
            self.send_response(500)
            self.end_headers()
            self.wfile.write(str(e).encode())

    def log_message(self, format, *args):
        pass  # Suppress default access logs — PHOTO lines are enough


if __name__ == "__main__":
    inbox_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    port = int(sys.argv[2]) if len(sys.argv) > 2 else 8765

    os.makedirs(inbox_dir, exist_ok=True)
    PhotoHandler.inbox_dir = inbox_dir

    server = HTTPServer(("", port), PhotoHandler)
    print(f"READY: Listening on port {port}", flush=True)

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
