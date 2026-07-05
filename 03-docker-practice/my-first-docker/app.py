from http.server import HTTPServer, BaseHTTPRequestHandler

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"Hello from inside Docker!")

    def log_message(self, format, *args):
        pass


print("Server running on port 8080")
HTTPServer(("", 8080), Handler).serve_forever()