#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_root

log "Installing dependencies..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y curl ca-certificates iproute2 jq

if ! command_exists sing-box; then
  log "Installing sing-box..."
  curl -fsSL https://sing-box.app/install.sh | sh
else
  log "sing-box already installed, skipping binary install."
fi

require_binary
check_ip_bound "$PRIMARY_IP"
check_ip_bound "$SECONDARY_IP"
ensure_dirs

bash "$SCRIPT_DIR/generate-config.sh" --force
write_service

systemctl daemon-reload
systemctl enable --now "$SERVICE_NAME"

SB_BIN=$(find_sing_box_bin)
"$SB_BIN" check -c "$CONFIG_PATH"
systemctl restart "$SERVICE_NAME"

log "Install complete."
echo
cat "$INFO_PATH"
echo
log "Service status: systemctl status ${SERVICE_NAME}"
