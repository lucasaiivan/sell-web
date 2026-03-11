import http.server
import socketserver

PORT = 8080

class PNARequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Accept')
        self.send_header('Access-Control-Allow-Private-Network', 'true')
        http.server.SimpleHTTPRequestHandler.end_headers(self)

    def do_OPTIONS(self):
        self.send_response(204)
        self.end_headers()

    def do_GET(self):
        if self.path == '/status':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(b'{"status":"ok", "version":"1.0.0"}')
        else:
            self.send_response(404)
            self.end_headers()

with socketserver.TCPServer(("", PORT), PNARequestHandler) as httpd:
    print("Serving HTTP on port", PORT)
    httpd.serve_forever()
