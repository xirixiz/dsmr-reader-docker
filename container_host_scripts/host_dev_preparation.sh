#!/bin/sh
set -eu

# Creates a stable symlink for a USB serial tty device via udev
# Example result: /dev/dsmr_p1

# Detects a target tty device
# Extracts idVendor, idProduct, plus optional serial
# Writes one udev rule that creates a stable symlink such as /dev/dsmr_p1
# Reloads udev and triggers it

# Usage example:
# sudo NAME=dsmr_p1 DEV=/dev/ttyUSB0 GROUP=dialout ./host_dev_preparation.sh
# Dry-run mode:
# sudo DRYRUN=1 NAME=dsmr_p1 DEV=/dev/ttyUSB0 ./host_dev_preparation.sh

NAME="${NAME:-dsmr_p1}"
DEV="${DEV:-}"
GROUP="${GROUP:-dialout}"
MODE="${MODE:-0660}"
RULE_FILE_NAME="${RULE_FILE_NAME:-99-serial-symlink.rules}"
DRYRUN="${DRYRUN:-0}"

if [ "${DRYRUN}" = "1" ] || [ "${DRYRUN}" = "true" ]; then
  echo "=== DRY-RUN MODE - No changes will be made ==="
  echo
fi

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

need_cmd udevadm
need_cmd awk
need_cmd sed
need_cmd grep

pick_default_dev() {
  for d in /dev/ttyUSB* /dev/ttyACM* /dev/ttyAMA*; do
    [ -e "$d" ] || continue
    echo "$d"
    return 0
  done
  return 1
}

if [ -z "${DEV}" ]; then
  DEV="$(pick_default_dev || true)"
fi

if [ -z "${DEV}" ] || [ ! -e "${DEV}" ]; then
  echo "No device found. Set DEV=/dev/ttyUSB0 or similar." >&2
  exit 1
fi

# Grab vendor, product, serial from udev attributes
# We look for the first occurrences in the udevadm info output
INFO="$(udevadm info -a -n "${DEV}" 2>/dev/null || true)"

VENDOR="$(printf "%s\n" "${INFO}" | grep -m 1 'ATTRS{idVendor}==' | sed 's/.*==\"\([0-9a-fA-F]\+\)\".*/\1/')"
PRODUCT="$(printf "%s\n" "${INFO}" | grep -m 1 'ATTRS{idProduct}==' | sed 's/.*==\"\([0-9a-fA-F]\+\)\".*/\1/')"
SERIAL="$(printf "%s\n" "${INFO}" | grep -m 1 'ATTRS{serial}==' | sed 's/.*==\"\(.*\)\".*/\1/' || true)"

if [ -z "${VENDOR}" ] || [ -z "${PRODUCT}" ]; then
  echo "Could not detect idVendor or idProduct from ${DEV}" >&2
  exit 1
fi

echo "Detected device: ${DEV}"
echo "  Vendor:  ${VENDOR}"
echo "  Product: ${PRODUCT}"
echo "  Serial:  ${SERIAL:-<none>}"
echo

# Pick an install location that is common across distros
RULE_DIR=""
for d in /etc/udev/rules.d /lib/udev/rules.d /usr/lib/udev/rules.d; do
  if [ -d "$d" ]; then
    RULE_DIR="$d"
    break
  fi
done

if [ -z "${RULE_DIR}" ]; then
  echo "Could not find a udev rules directory" >&2
  exit 1
fi

RULE_PATH="${RULE_DIR}/${RULE_FILE_NAME}"

# Build rule
# If serial exists we include it to avoid matching the wrong adapter
if [ -n "${SERIAL}" ]; then
  RULE="SUBSYSTEM==\"tty\", ATTRS{idVendor}==\"${VENDOR}\", ATTRS{idProduct}==\"${PRODUCT}\", ATTRS{serial}==\"${SERIAL}\", SYMLINK+=\"${NAME}\", MODE=\"${MODE}\", GROUP=\"${GROUP}\""
else
  RULE="SUBSYSTEM==\"tty\", ATTRS{idVendor}==\"${VENDOR}\", ATTRS{idProduct}==\"${PRODUCT}\", SYMLINK+=\"${NAME}\", MODE=\"${MODE}\", GROUP=\"${GROUP}\""
fi

if [ "${DRYRUN}" = "1" ] || [ "${DRYRUN}" = "true" ]; then
  echo "Would write udev rule to: ${RULE_PATH}"
  echo "Rule content:"
  printf "  %s\n" "${RULE}"
  echo
  echo "Would reload udev rules with:"
  echo "  udevadm control --reload-rules"
  echo "  udevadm trigger"
  echo
  echo "Expected result: /dev/${NAME} -> ${DEV}"
else
  echo "Writing udev rule to ${RULE_PATH}"
  printf "%s\n" "${RULE}" | tee "${RULE_PATH}" >/dev/null

  # Reload and trigger
  echo "Reloading udev rules"
  udevadm control --reload-rules 2>/dev/null || true
  udevadm trigger 2>/dev/null || true

  # Show result
  sleep 1
  if [ -e "/dev/${NAME}" ]; then
    echo "Success: /dev/${NAME} exists"
    ls -l "/dev/${NAME}"
  else
    echo "Rule installed but /dev/${NAME} not present yet."
    echo "Unplug and replug the adapter, then check again."
  fi
fi