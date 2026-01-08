# USB Serial Device Symlink Creator

**File:** `container_host_scripts/host_dev_setup.sh`

## Overview

This script creates a stable symlink (e.g., `/dev/dsmr_p1`) for USB serial devices that would normally appear as `/dev/ttyUSB0`, `/dev/ttyACM0`, etc. This solves the problem of device names changing when you unplug/replug devices or reboot your system.

## The Problem

USB serial devices get dynamic names:
```bash
# Today
/dev/ttyUSB0  ← Your P1 cable

# After reboot or unplugging another USB device
/dev/ttyUSB1  ← Your P1 cable moved!
```

This breaks Docker configurations that reference `/dev/ttyUSB0`.

## The Solution

Create a stable symlink based on the device's hardware identifiers:
```bash
/dev/dsmr_p1 → /dev/ttyUSB0  (always points to your P1 cable)
```

Then use `/dev/dsmr_p1` in your Docker configuration instead of `/dev/ttyUSB0`.

---

## What the Script Does

1. **Detects** USB device hardware identifiers (Vendor ID, Product ID, Serial Number)
2. **Creates** a udev rule that matches your specific device
3. **Sets up** a stable symlink (e.g., `/dev/dsmr_p1`)
4. **Configures** proper permissions (default: 0660, group: dialout)
5. **Reloads** udev to activate the rule immediately

---

## Requirements

- Root/sudo access
- USB serial device plugged in
- Linux system with udev (Ubuntu, Debian, Raspbian, etc.)

---

## Basic Usage

### Quick Start (Auto-detect)

Plug in your P1 cable, then run:

```bash
sudo ./host_dev_setup.sh
```

This will:
- Auto-detect the first USB serial device found
- Create symlink `/dev/dsmr_p1`
- Use permissions `0660` and group `dialout`

### Specify Device

If you have multiple USB serial devices:

```bash
sudo DEV=/dev/ttyUSB0 ./host_dev_setup.sh
```

### Custom Symlink Name

```bash
sudo NAME=p1_meter DEV=/dev/ttyUSB0 ./host_dev_setup.sh
```

This creates `/dev/p1_meter` instead of `/dev/dsmr_p1`.

### Dry Run (Preview)

See what would be done without making changes:

```bash
sudo DRYRUN=1 DEV=/dev/ttyUSB0 ./host_dev_setup.sh
```

---

## Configuration Options

All options are set via environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `NAME` | `dsmr_p1` | Symlink name (will be `/dev/$NAME`) |
| `DEV` | Auto-detect | Device to create rule for (e.g., `/dev/ttyUSB0`) |
| `GROUP` | `dialout` | Group ownership of the symlink |
| `MODE` | `0660` | Permission mode (0660 = rw-rw----) |
| `RULE_FILE_NAME` | `99-serial-symlink.rules` | Name of the udev rules file |
| `DRYRUN` | `0` | Set to `1` for dry-run mode |

---

## Examples

### Example 1: Basic Setup for DSMR P1 Cable

```bash
# Auto-detect device
sudo ./host_dev_setup.sh
```

**Result:**
```
Detected device: /dev/ttyUSB0
  Vendor:  067b
  Product: 2303
  Serial:  <none>

Writing udev rule to /etc/udev/rules.d/99-serial-symlink.rules
Reloading udev rules
Success: /dev/dsmr_p1 exists
lrwxrwxrwx 1 root root 7 Jan  8 10:30 /dev/dsmr_p1 -> ttyUSB0
```

### Example 2: Multiple Devices (Use Serial Number)

If you have multiple identical USB adapters, the script automatically uses the serial number to differentiate:

```bash
# First device
sudo NAME=meter1 DEV=/dev/ttyUSB0 ./host_dev_setup.sh

# Second device (same vendor/product, different serial)
sudo NAME=meter2 DEV=/dev/ttyUSB1 ./host_dev_setup.sh
```

**Result:**
```
/dev/meter1 → First P1 cable (serial: ABC123)
/dev/meter2 → Second P1 cable (serial: DEF456)
```

### Example 3: Custom Permissions

Make device world-readable (not recommended for production):

```bash
sudo MODE=0666 GROUP=users DEV=/dev/ttyUSB0 ./host_dev_setup.sh
```

### Example 4: Preview Before Running

```bash
sudo DRYRUN=1 DEV=/dev/ttyUSB0 ./host_dev_setup.sh
```

**Output:**
```
=== DRY-RUN MODE - No changes will be made ===

Detected device: /dev/ttyUSB0
  Vendor:  067b
  Product: 2303
  Serial:

Would write udev rule to: /etc/udev/rules.d/99-serial-symlink.rules
Rule content:
  SUBSYSTEM=="tty", ATTRS{idVendor}=="067b", ATTRS{idProduct}=="2303", SYMLINK+="dsmr_p1", MODE="0660", GROUP="dialout"

Would reload udev rules with:
  udevadm control --reload-rules
  udevadm trigger

Expected result: /dev/dsmr_p1 -> /dev/ttyUSB0
```

---

## Using the Symlink in Docker

After running the script, update your `docker-compose.yaml`:

### Before (Unstable)

```yaml
services:
  dsmr:
    devices:
      - /dev/ttyUSB0:/dev/ttyUSB0  # ❌ Can change!
    environment:
      DSMRREADER_REMOTE_DATALOGGER_SERIAL_DEVICE: /dev/ttyUSB0
```

### After (Stable)

```yaml
services:
  dsmr:
    devices:
      - /dev/dsmr_p1:/dev/dsmr_p1  # ✅ Stable symlink
    environment:
      DSMRREADER_REMOTE_DATALOGGER_SERIAL_DEVICE: /dev/dsmr_p1
```

---

## How It Works

### 1. Detection

The script uses `udevadm info` to extract device identifiers:

```bash
udevadm info -a -n /dev/ttyUSB0
```

Extracts:
- **Vendor ID** (e.g., `067b` for Prolific)
- **Product ID** (e.g., `2303` for PL2303)
- **Serial Number** (if available)

### 2. Rule Creation

Creates a udev rule file in `/etc/udev/rules.d/`:

**Without serial number:**
```
SUBSYSTEM=="tty", ATTRS{idVendor}=="067b", ATTRS{idProduct}=="2303", SYMLINK+="dsmr_p1", MODE="0660", GROUP="dialout"
```

**With serial number:**
```
SUBSYSTEM=="tty", ATTRS{idVendor}=="067b", ATTRS{idProduct}=="2303", ATTRS{serial}=="ABC123", SYMLINK+="dsmr_p1", MODE="0660", GROUP="dialout"
```

### 3. Activation

Reloads udev rules and triggers device recognition:
```bash
udevadm control --reload-rules
udevadm trigger
```

---

## Verification

### Check Symlink Exists

```bash
ls -l /dev/dsmr_p1
```

**Expected output:**
```
lrwxrwxrwx 1 root root 7 Jan  8 10:30 /dev/dsmr_p1 -> ttyUSB0
```

### Check Permissions

```bash
ls -l /dev/dsmr_p1
```

Should show group `dialout` and permissions `crw-rw----`.

### Test Access

```bash
# As user in dialout group
cat /dev/dsmr_p1
# Should show P1 telegram data
# Press Ctrl+C to stop
```

---

## Troubleshooting

### Symlink Not Created

**Check rule file exists:**
```bash
cat /etc/udev/rules.d/99-serial-symlink.rules
```

**Manually reload udev:**
```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```

**Unplug and replug the device:**
```bash
# Unplug USB cable
# Wait 2 seconds
# Plug back in
ls -l /dev/dsmr_p1
```

### Permission Denied

**Add user to dialout group:**
```bash
sudo usermod -aG dialout $USER
# Log out and back in
```

**Verify group membership:**
```bash
groups | grep dialout
```

### Multiple Rules Conflict

**Remove old rules:**
```bash
sudo rm /etc/udev/rules.d/99-dsmr-*.rules
sudo udevadm control --reload-rules
```

**Re-run script:**
```bash
sudo ./host_dev_setup.sh
```

### Script Can't Find Device

**List available devices:**
```bash
ls -l /dev/ttyUSB* /dev/ttyACM*
```

**Manually specify device:**
```bash
sudo DEV=/dev/ttyACM0 ./host_dev_setup.sh
```

### Wrong Device Detected

**Specify exact device:**
```bash
sudo DEV=/dev/ttyUSB1 ./host_dev_setup.sh
```

**Check device information:**
```bash
udevadm info -a -n /dev/ttyUSB1 | grep -E 'idVendor|idProduct|serial'
```

---

## Common Device Identifiers

### Prolific PL2303 (Common P1 Cable)
- Vendor: `067b`
- Product: `2303`

### FTDI FT232 (USB Serial Adapter)
- Vendor: `0403`
- Product: `6001`

### Silicon Labs CP210x
- Vendor: `10c4`
- Product: `ea60`

### Check Your Device

```bash
lsusb
```

**Example output:**
```
Bus 001 Device 005: ID 067b:2303 Prolific Technology, Inc. PL2303 Serial Port
                       ^^^^:^^^^
                       |    └─ Product ID
                       └─ Vendor ID
```

---

## Advanced Usage

### Multiple Devices with Custom Names

```bash
# Meter 1 (House)
sudo NAME=meter_house DEV=/dev/ttyUSB0 ./host_dev_setup.sh

# Meter 2 (Garage)
sudo NAME=meter_garage DEV=/dev/ttyUSB1 ./host_dev_setup.sh

# Meter 3 (Solar)
sudo NAME=meter_solar DEV=/dev/ttyUSB2 ./host_dev_setup.sh
```

**Docker configuration:**
```yaml
services:
  dsmr-house:
    devices:
      - /dev/meter_house:/dev/meter_house
    environment:
      DSMRREADER_REMOTE_DATALOGGER_SERIAL_DEVICE: /dev/meter_house

  dsmr-garage:
    devices:
      - /dev/meter_garage:/dev/meter_garage
    environment:
      DSMRREADER_REMOTE_DATALOGGER_SERIAL_DEVICE: /dev/meter_garage

  dsmr-solar:
    devices:
      - /dev/meter_solar:/dev/meter_solar
    environment:
      DSMRREADER_REMOTE_DATALOGGER_SERIAL_DEVICE: /dev/meter_solar
```

### Custom Rule File Name

```bash
sudo RULE_FILE_NAME=10-dsmr-meter.rules DEV=/dev/ttyUSB0 ./host_dev_setup.sh
```

Rule files are processed in numerical order (`10-`, `99-`, etc).

---

## Removal

### Remove Symlink and Rule

```bash
# Remove rule file
sudo rm /etc/udev/rules.d/99-serial-symlink.rules

# Reload udev
sudo udevadm control --reload-rules
sudo udevadm trigger

# Verify symlink is gone
ls -l /dev/dsmr_p1
```

---

## Integration with Docker Compose

### Complete Example

**1. Run script:**
```bash
sudo ./host_dev_setup.sh
```

**2. Update docker-compose.yaml:**
```yaml
version: '3.8'

services:
  dsmr:
    image: xirixiz/dsmr-reader-docker:latest
    devices:
      - /dev/dsmr_p1:/dev/dsmr_p1
    environment:
      CONTAINER_RUN_MODE: standalone
      DSMRREADER_REMOTE_DATALOGGER_SERIAL_DEVICE: /dev/dsmr_p1
      DSMRREADER_REMOTE_DATALOGGER_SERIAL_BAUDRATE: 115200
      DSMRREADER_REMOTE_DATALOGGER_SERIAL_BYTESIZE: 8
      # ... other configuration ...
```

**3. Start container:**
```bash
docker-compose up -d
```

**4. Verify it works:**
```bash
docker-compose logs dsmr | grep -i telegram
```

---

## Comparison with Manual Udev Rules

### Manual Method (Complex)

```bash
# 1. Detect IDs manually
udevadm info -a -n /dev/ttyUSB0 | grep -E 'idVendor|idProduct'

# 2. Create rule file manually
sudo nano /etc/udev/rules.d/99-dsmr.rules

# 3. Write rule (easy to make mistakes!)
SUBSYSTEM=="tty", ATTRS{idVendor}=="067b", ATTRS{idProduct}=="2303", SYMLINK+="dsmr_p1", MODE="0660", GROUP="dialout"

# 4. Reload udev manually
sudo udevadm control --reload-rules
sudo udevadm trigger

# 5. Test and debug
```

### Script Method (Simple)

```bash
sudo ./host_dev_setup.sh
```

Done! ✅

---

## Platform-Specific Notes

### Raspberry Pi

Works out of the box. No special configuration needed.

### Ubuntu/Debian

Standard usage as documented.

### Synology NAS

May need `synokernel-usbserial` driver first. See [Troubleshooting Guide](../docs/TROUBLESHOOTING.md#synology-nas).

### WSL2

USB devices not supported natively in WSL2. Use Windows Docker Desktop instead.

---

## Best Practices

1. **Run dry-run first** - Always preview with `DRYRUN=1`
2. **Use descriptive names** - `meter_house` is better than `p1`
3. **Document your setup** - Note which device is which
4. **Keep rule files organized** - One rule per file with descriptive names
5. **Test after creation** - Verify symlink works before updating Docker

---

## Security Considerations

### Default Permissions (0660)

- Owner: root (read/write)
- Group: dialout (read/write)
- Others: no access

**This is secure and appropriate for most use cases.**

### World-Readable (0666) ⚠️

```bash
sudo MODE=0666 ./host_dev_setup.sh
```

**Not recommended** - any user can access the device.

### Custom Group

```bash
sudo GROUP=mygroup ./host_dev_setup.sh
```

Ensure users are in `mygroup` to access the device.

---

## FAQ

**Q: Will the symlink persist after reboot?**
A: Yes, the udev rule ensures the symlink is recreated on every boot.

**Q: What if I have two identical USB adapters?**
A: If they have different serial numbers, the script handles it automatically. If not, they'll both match the same rule (symlink points to whichever is detected first).

**Q: Can I change the symlink name later?**
A: Yes, just re-run the script with a different `NAME` value. The old rule will be overwritten.

**Q: Does this work with USB hubs?**
A: Yes, works fine with USB hubs.

**Q: Can I use this for non-DSMR devices?**
A: Yes! Works with any USB serial device (Arduino, Zigbee sticks, etc).

---

## See Also

- [Main README](../README.md) - Quick start guide
- [Configuration Reference](../docs/CONFIGURATION.md) - Environment variables
- [Troubleshooting](../docs/TROUBLESHOOTING.md) - Serial device issues
- [Run Modes](../docs/RUN_MODES.md) - Different operational modes

---

**Created by [@xirixiz](https://github.com/xirixiz)**

**Last Updated:** January 2026