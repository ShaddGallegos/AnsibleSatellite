#!/usr/bin/env bash
set -euo pipefail

# Associate provisioning template with RHEL 9.7 OS and set global parameters using hammer.
# Run this on the Satellite server or a host with hammer configured (with server, org, location, and credentials).
#
# Usage:
#   export HAMMER_USERNAME=admin
#   export HAMMER_PASSWORD='...'
#   ./hammer_associate_and_params.sh \
#     --template "RHEL 9.7 x86_64 Post-Kickstart Default" \
#     --os-major 9 --os-minor 7 \
#     --admin-user admin --admin-pass 'ChangeMe!' \
#     --activation-keys '9:RHEL9-AK' \
#     --enable-updates true

TEMPLATE_NAME="RHEL 9.7 x86_64 Post-Kickstart Default"
OS_MAJOR=9
OS_MINOR=7
ADMIN_USER=admin
ADMIN_PASS='ChangeMe!'
ACTIVATION_KEYS='9:RHEL9-AK'
ENABLE_UPDATES=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --template) TEMPLATE_NAME="$2"; shift 2;;
    --os-major) OS_MAJOR="$2"; shift 2;;
    --os-minor) OS_MINOR="$2"; shift 2;;
    --admin-user) ADMIN_USER="$2"; shift 2;;
    --admin-pass) ADMIN_PASS="$2"; shift 2;;
    --activation-keys) ACTIVATION_KEYS="$2"; shift 2;;
    --enable-updates) ENABLE_UPDATES="$2"; shift 2;;
    *) echo "Unknown arg: $1"; exit 2;;
  esac
done

require() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing command: $1"; exit 1; }
}

require hammer

echo "Finding OS id for Red Hat major=${OS_MAJOR} minor=${OS_MINOR}..."
OS_ID=$(hammer --no-headers os list | awk -v maj="$OS_MAJOR" -v min="$OS_MINOR" '($1 ~ /^[0-9]+$/) { id=$1; name=""; major=""; minor="" } { if ($2!="") name=$2 } { if ($0 ~ /Major:/) { major=$2 } } { if ($0 ~ /Minor:/) { minor=$2 } } (major==maj && minor==min) { print id; exit }') || true

if [[ -z "$OS_ID" ]]; then
  echo "Exact minor not found; falling back to major ${OS_MAJOR}..."
  OS_ID=$(hammer --no-headers os list | awk -v maj="$OS_MAJOR" '($1 ~ /^[0-9]+$/) { id=$1; major="" } { if ($0 ~ /Major:/) { major=$2 } } (major==maj) { print id; exit }') || true
fi

if [[ -z "$OS_ID" ]]; then
  echo "ERROR: Could not find OS with major=$OS_MAJOR (minor=$OS_MINOR preferred)."; exit 1
fi

echo "Looking up template id for: $TEMPLATE_NAME"
TPL_ID=$(hammer --no-headers template list --search "name=\"$TEMPLATE_NAME\"" | awk 'NR==1{print $1}') || true
if [[ -z "$TPL_ID" ]]; then
  echo "ERROR: Template '$TEMPLATE_NAME' not found. Push it first."; exit 1
fi

echo "Associating template with OS (adding association)"
hammer os add-template --id "$OS_ID" --template-id "$TPL_ID" || true

echo "Setting default provision template for OS"
hammer os set-default-template --id "$OS_ID" --provisioning-template-id "$TPL_ID" --type provision

echo "Upserting global parameters"
hammer global-parameter set --name admin_user --value "$ADMIN_USER"
hammer global-parameter set --name admin_password --value "$ADMIN_PASS"
hammer global-parameter set --name activation_keys --value "$ACTIVATION_KEYS"
hammer global-parameter set --name ks_enable_updates --value "$ENABLE_UPDATES"

echo "Done. OS_ID=$OS_ID TPL_ID=$TPL_ID"
