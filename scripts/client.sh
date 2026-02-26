#!/usr/bin/env bash
set -euo pipefail

LB_IP="${1:-192.168.100.10}"
export DEBIAN_FRONTEND=noninteractive

echo "[client] Instalando Node.js 22 (compatibilidad Artillery 2.x)..."
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs

echo "[client] Instalando Artillery..."
sudo npm i -g artillery@latest

echo "[client] Preparando carpeta de pruebas..."
mkdir -p /home/vagrant/tests
chown -R vagrant:vagrant /home/vagrant/tests

echo "[client] Creando scripts de pruebas (baseline/spike/soak) contra http://${LB_IP} ..."

cat >/home/vagrant/tests/baseline.yml <<EOF
config:
  target: "http://${LB_IP}"
  phases:
    - duration: 30
      arrivalRate: 10
scenarios:
  - name: "baseline"
    flow:
      - get:
          url: "/"
      - get:
          url: "/health"
EOF

cat >/home/vagrant/tests/spike.yml <<EOF
config:
  target: "http://${LB_IP}"
  phases:
    - duration: 10
      arrivalRate: 10
    - duration: 10
      arrivalRate: 80
    - duration: 10
      arrivalRate: 10
scenarios:
  - name: "spike"
    flow:
      - get:
          url: "/"
EOF

cat >/home/vagrant/tests/soak.yml <<EOF
config:
  target: "http://${LB_IP}"
  phases:
    - duration: 120
      arrivalRate: 30
scenarios:
  - name: "soak"
    flow:
      - get:
          url: "/"
EOF

echo
echo "[client] Listo "
echo "Comandos:"
echo "  vagrant ssh client"
echo "  artillery --version"
echo "  artillery run ~/tests/baseline.yml"
echo "  artillery run ~/tests/spike.yml"
echo "  artillery run ~/tests/soak.yml"
