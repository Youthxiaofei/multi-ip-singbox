#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

FORCE=0
if [[ "${1:-}" == "--force" ]]; then
  FORCE=1
fi

require_root
require_binary
ensure_dirs
check_ip_bound "$PRIMARY_IP"
check_ip_bound "$SECONDARY_IP"

if [[ -f "$CONFIG_PATH" && $FORCE -ne 1 ]]; then
  die "${CONFIG_PATH} already exists. Use --force to overwrite."
fi

PORT1=$(pick_random_port)
PORT2=$(pick_random_port "$PORT1")
PASS1=$(generate_ss_password)
PASS2=$(generate_ss_password)

cat > "$CONFIG_PATH" <<JSON
{
  "log": {
    "level": "info"
  },
  "dns": {
    "servers": [
      {
        "type": "tls",
        "tag": "google",
        "server": "8.8.8.8"
      }
    ]
  },
  "inbounds": [
    {
      "type": "shadowsocks",
      "tag": "user1-in",
      "listen": "::",
      "listen_port": ${PORT1},
      "network": "tcp",
      "method": "${METHOD}",
      "password": "${PASS1}",
      "multiplex": {
        "enabled": true,
        "padding": true
      }
    },
    {
      "type": "shadowsocks",
      "tag": "user2-in",
      "listen": "::",
      "listen_port": ${PORT2},
      "network": "tcp",
      "method": "${METHOD}",
      "password": "${PASS2}",
      "multiplex": {
        "enabled": true,
        "padding": true
      }
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "ip1-out",
      "inet4_bind_address": "${PRIMARY_IP}"
    },
    {
      "type": "direct",
      "tag": "ip2-out",
      "inet4_bind_address": "${SECONDARY_IP}"
    }
  ],
  "route": {
    "rules": [
      {
        "port": 53,
        "action": "hijack-dns"
      },
      {
        "inbound": ["user1-in"],
        "outbound": "ip1-out"
      },
      {
        "inbound": ["user2-in"],
        "outbound": "ip2-out"
      }
    ]
  }
}
JSON

chmod 600 "$CONFIG_PATH"

mkdir -p "$STATE_DIR"
cat > "$INFO_PATH" <<INFO
Node 1
Type: Shadowsocks
Server: ${PRIMARY_IP}
Port: ${PORT1}
Method: ${METHOD}
Password: ${PASS1}
Expected Egress IP: ${PRIMARY_IP}
URL: ss://${METHOD}:${PASS1}@${PRIMARY_IP}:${PORT1}

Node 2
Type: Shadowsocks
Server: ${PRIMARY_IP}
Port: ${PORT2}
Method: ${METHOD}
Password: ${PASS2}
Expected Egress IP: ${SECONDARY_IP}
URL: ss://${METHOD}:${PASS2}@${PRIMARY_IP}:${PORT2}
INFO
chmod 600 "$INFO_PATH"

open_port_if_needed "$PORT1"
open_port_if_needed "$PORT2"

log "Generated config: $CONFIG_PATH"
log "Saved node info: $INFO_PATH"
log "Node 1 port: $PORT1 -> egress $PRIMARY_IP"
log "Node 2 port: $PORT2 -> egress $SECONDARY_IP"
