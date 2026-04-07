#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_root

if systemctl list-unit-files | grep -q "^${SERVICE_NAME}.service"; then
  systemctl disable --now "$SERVICE_NAME" || true
fi
rm -f "$SERVICE_PATH"
systemctl daemon-reload

rm -f "$CONFIG_PATH"
rm -rf "$STATE_DIR"

log "Removed service and generated files."
log "sing-box binary was not removed."
