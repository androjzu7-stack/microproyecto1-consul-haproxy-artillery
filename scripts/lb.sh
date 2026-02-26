#!/usr/bin/env bash
set -euo pipefail

sudo apt-get install -y haproxy

sudo mkdir -p /etc/haproxy/errors
sudo tee /etc/haproxy/errors/503.http >/dev/null <<'EOF'
HTTP/1.0 503 Service Unavailable
Cache-Control: no-cache
Connection: close
Content-Type: text/html

<html><body style="font-family:Arial">
<h1>Lo sentimos</h1>
<p>No hay servidores disponibles en este momento.</p>
</body></html>
EOF

sudo tee /etc/haproxy/haproxy.cfg >/dev/null <<'EOF'
global
  log /dev/log local0
  maxconn 2048
  daemon

defaults
  log global
  mode http
  option httplog
  timeout connect 5s
  timeout client  1m
  timeout server  1m

frontend stats
  bind *:1936
  mode http
  stats uri /
  stats refresh 5s
  no log

frontend http_front
  bind *:80
  default_backend http_back

backend http_back
  balance roundrobin
  server-template mywebapp 1-10 _web._tcp.service.consul resolvers consul resolve-opts allow-dup-ip resolve-prefer ipv4 check
  errorfile 503 /etc/haproxy/errors/503.http

resolvers consul
  nameserver consul 127.0.0.1:8600
  hold valid 5s
EOF

sudo haproxy -c -f /etc/haproxy/haproxy.cfg
sudo systemctl enable --now haproxy
sudo systemctl restart haproxy