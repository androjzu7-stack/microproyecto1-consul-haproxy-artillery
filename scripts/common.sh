#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

sudo apt-get update -y
sudo apt-get install -y curl wget unzip jq dnsutils ca-certificates gnupg lsb-release