#!/usr/bin/env bash
set -euo pipefail

NODE_NAME="$1"
BIND_IP="$2"
REPLICAS="$3"      # ej: 3
START_PORT="$4"    # ej: 3000

# Node 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# App
sudo mkdir -p /opt/webapp
sudo tee /opt/webapp/server.js >/dev/null <<'EOF'
const http = require('http');
const os = require('os');

const nodeName = process.env.NODE_NAME || os.hostname();
const port = parseInt(process.env.PORT || '3000', 10);
const instance = process.env.INSTANCE || String(port);

const server = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, {'Content-Type':'text/plain'});
    return res.end('ok');
  }
  res.writeHead(200, {'Content-Type':'application/json'});
  res.end(JSON.stringify({ node: nodeName, instance, port, time: new Date().toISOString() }));
});

server.listen(port, '0.0.0.0', () => console.log(`listening on ${port}`));
EOF

# systemd template
sudo tee /etc/systemd/system/web@.service >/dev/null <<EOF
[Unit]
Description=Node Web (${NODE_NAME}) instance %i
After=network.target consul.service
Requires=consul.service

[Service]
Environment=NODE_NAME=${NODE_NAME}
Environment=PORT=%i
Environment=INSTANCE=%i
WorkingDirectory=/opt/webapp
ExecStart=/usr/bin/node /opt/webapp/server.js
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload

# Registrar N replicas en Consul + levantar N instancias
END_PORT=$((START_PORT + REPLICAS - 1))
for PORT in $(seq "$START_PORT" "$END_PORT"); do
  sudo tee /etc/consul.d/web-${PORT}.json >/dev/null <<EOF
{
  "service": {
    "name": "web",
    "id": "web-${NODE_NAME}-${PORT}",
    "address": "${BIND_IP}",
    "port": ${PORT},
    "checks": [
      { "http": "http://127.0.0.1:${PORT}/health", "interval": "5s", "timeout": "2s" }
    ]
  }
}
EOF
  sudo systemctl enable --now "web@${PORT}"
done

sudo consul reload || sudo systemctl restart consul