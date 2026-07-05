from http.server import HTTPServer, BaseHTTPRequestHandler
import redis
import os


# Connect to Redis
redis_client = redis.Redis(
    host=os.getenv("REDIS_HOST", "redis"),
    port=int(os.getenv("REDIS_PORT", 6379)),
    decode_responses=True
)


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):

        # Increment counter in Redis
        visits = redis_client.incr("visit_count")

        
        response = f"""
        <html>
          <body style="font-family: sans-serif; padding: 40px;">
            <h1>Hello from Docker Compose!</h1>
            <h2>Visit count: {visits}</h2>
            <p>This number is stored in Redis — a separate container.</p>
            <p>Refresh the page to increment it.</p>
          </body>
        </html>
        """.encode()

        self.send_response(200)
        self.send_header("Content-Type", "text/html")
        self.end_headers()
        self.wfile.write(response)

    # Silence request logs
    def log_message(self, format, *args):
        pass



print("Server running on port 8080")
HTTPServer(("", 8080), Handler).serve_forever()