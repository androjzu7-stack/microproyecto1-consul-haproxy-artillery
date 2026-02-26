#!/usr/bin/env bash
set -euo pipefail

NODE_NAME="$1"          # lb | web1 | web2
BIND_IP="$2"            # 192.168.100.x
IS_SERVER="$3"          # true/false (usaremos true en los 3 para formar cluster)
BOOTSTRAP_EXPECT="$4"   # 3
RETRY_JOIN_CSV="$5"     # "ip1,ip2,ip3"

# Repo oficial HashiCorp
wget -O - https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(. /etc/os-release && echo $UBUNTU_CODENAME) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null

sudo apt-get update -y
sudo apt-get install -y consul

# Usuario + carpetas (data_dir fuera de /vagrant)
sudo id consul &>/dev/null || sudo useradd --system --home /etc/consul.d --shell /bin/false consul
sudo mkdir -p /etc/consul.d /opt/consul
sudo chown -R consul:consul /etc/consul.d /opt/consul
sudo chmod 750 /etc/consul.d /opt/consul

# retry_join list
IFS=',' read -ra JOIN <<< "$RETRY_JOIN_CSV"
JOIN_HCL=$(printf "\"%s\"," "${JOIN[@]}" | sed 's/,$//')

sudo tee /etc/consul.d/consul.hcl >/dev/null <<EOF
datacenter  = "dc1"
node_name   = "${NODE_NAME}"
data_dir    = "/opt/consul"
bind_addr   = "${BIND_IP}"
client_addr = "0.0.0.0"

server = ${IS_SERVER}
bootstrap_expect = ${BOOTSTRAP_EXPECT}
retry_join = [${JOIN_HCL}]

ui_config {
  enabled = true
}
EOF

sudo chown consul:consul /etc/consul.d/consul.hcl

# systemd
sudo tee /etc/systemd/system/consul.service >/dev/null <<'EOF'
[Unit]
Description=HashiCorp Consul Agent
Requires=network-online.target
After=network-online.target

[Service]
User=consul
Group=consul
ExecStart=/usr/bin/consul agent -config-dir=/etc/consul.d
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now consul