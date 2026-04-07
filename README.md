# multi-ip-singbox

A minimal GitHub-ready project for **Ubuntu 22.04** that installs `sing-box`, generates a **Shadowsocks 2022** configuration, and binds **different inbound ports to different IPv4 egress IPs**.

## Features

- Installs sing-box on Ubuntu/Debian using the official installer
- Generates two random TCP ports by default
- Generates valid `2022-blake3-aes-128-gcm` passwords
- Binds each inbound to a dedicated outbound using `inet4_bind_address`
- Writes a `systemd` service
- Outputs ready-to-use `ss://` links
- Safe to re-run with `--force`

## Default topology

- Primary IP: `64.186.224.205`
- Secondary IP: `154.26.181.3`
- Protocol: `Shadowsocks 2022`
- Port assignment: random

## Quick start

```bash
git clone https://github.com/<yourname>/multi-ip-singbox.git
cd multi-ip-singbox
chmod +x install.sh generate-config.sh uninstall.sh
sudo ./install.sh
```

After install, node information is saved to:

```bash
/etc/multi-ip-singbox/node-info.txt
```

## Example output

The installer prints something like:

```text
Node 1: ss://2022-blake3-aes-128-gcm:...@64.186.224.205:38124
Node 2: ss://2022-blake3-aes-128-gcm:...@64.186.224.205:42781
```

## Files

- `install.sh` — install sing-box, generate config, create service
- `generate-config.sh` — generate `/etc/sing-box/config.json`
- `uninstall.sh` — remove service and config
- `templates/config.json.tpl` — reference template
- `lib/common.sh` — shared helpers

## Re-generate ports and passwords

```bash
sudo ./generate-config.sh --force
sudo systemctl restart multi-ip-singbox
cat /etc/multi-ip-singbox/node-info.txt
```

## Optional environment variables

You can override defaults before running the installer:

```bash
export PRIMARY_IP="64.186.224.205"
export SECONDARY_IP="154.26.181.3"
export CONFIG_PATH="/etc/sing-box/config.json"
export INFO_PATH="/etc/multi-ip-singbox/node-info.txt"
sudo -E ./install.sh
```

## Firewall

If `ufw` is active, the installer automatically opens the generated TCP ports.

## Important notes

- This project assumes both IPv4 addresses are already configured on the server.
- Test the secondary IP before install:

```bash
curl --interface 154.26.181.3 ifconfig.me
```

- If you later edit config manually, restart the service:

```bash
sudo systemctl restart multi-ip-singbox
```

## Remove

```bash
sudo ./uninstall.sh
```
