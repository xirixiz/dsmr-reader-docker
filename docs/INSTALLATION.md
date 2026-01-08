# Installation Guide

Complete installation instructions for DSMR Reader Docker.

---

## Prerequisites

### Required
- Docker 20.x or newer (or Podman)
- Docker Compose 1.27.0 or newer
- 2GB RAM minimum (4GB recommended)
- 10GB disk space minimum
- USB serial port or network-connected smart meter

### Operating Systems
- Linux (Ubuntu, Debian, Raspbian, etc.)
- macOS (Intel or Apple Silicon)
- Windows (via WSL2 or Docker Desktop)

---

## Quick Installation

### Step 1: Install Docker

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install docker.io docker-compose
sudo systemctl enable docker
sudo systemctl start docker
```

**Other platforms:** See [Docker installation docs](https://docs.docker.com/engine/install/)

### Step 2: Configure User Permissions

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Add user to dialout group (for serial access)
sudo usermod -aG dialout $USER

# Log out and back in for groups to take effect
```

### Step 3: Create Project Directory

```bash
mkdir ~/dsmr-reader
cd ~/dsmr-reader
```

### Step 4: Create docker-compose.yaml

Create `docker-compose.yaml` with this content:

```yaml
version: '3.8'

volumes:
  dsmrdb_data:

services:
  dsmrdb:
    image: postgres:17-alpine
    container_name: dsmrdb
    restart: always
    volumes:
      - dsmrdb_data:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: dsmrreader
      POSTGRES_PASSWORD: dsmrreader
      POSTGRES_DB: dsmrreader

  dsmr:
    image: xirixiz/dsmr-reader-docker:latest
    container_name: dsmr
    restart: always
    depends_on:
      - dsmrdb
    ports:
      - "80:80"
    devices:
      - /dev/ttyUSB0:/dev/ttyUSB0
    environment:
      # Database
      DJANGO_DATABASE_HOST: dsmrdb
      DJANGO_DATABASE_NAME: dsmrreader
      DJANGO_DATABASE_USER: dsmrreader
      DJANGO_DATABASE_PASSWORD: dsmrreader

      # Application
      DJANGO_TIME_ZONE: Europe/Amsterdam
      DJANGO_SECRET_KEY: change-me-to-random-string
      DSMRREADER_ADMIN_USER: admin
      DSMRREADER_ADMIN_PASSWORD: admin
```

### Step 5: Start Services

```bash
docker-compose up -d
```

### Step 6: Access Web Interface

Open browser to: `http://localhost`

Login with:
- Username: `admin`
- Password: `admin`

### Step 7: Configure DSMR Version

1. Navigate to: Configuration → Datalogger
2. Set your DSMR version (4.x or 5.x)
3. Save changes

---

## Detailed Setup

### Serial Device Setup

#### Find Your Device

```bash
# List USB serial devices
ls -l /dev/ttyUSB* /dev/ttyACM*

# Monitor device detection
dmesg | tail -20
```

#### Create Stable Symlink (Recommended)

Use the symlink script for stable device names:

```bash
# Download script
wget https://raw.githubusercontent.com/xirixiz/dsmr-reader-docker/development/container_host_scripts/host_dev_preparation.sh

# Make executable
chmod +x host_dev_preparation.sh

# Create symlink
sudo ./host_dev_preparation.sh

# This creates /dev/dsmr_p1 → /dev/ttyUSB0
```

Update your docker-compose.yaml:
```yaml
devices:
  - /dev/dsmr_p1:/dev/dsmr_p1
```

See [USB Symlink Documentation](../container_host_scripts/README.md) for details.

#### Manual Permissions (Alternative)

```bash
# Temporary fix
sudo chmod 666 /dev/ttyUSB0

# Permanent fix - add user to dialout group
sudo usermod -aG dialout $USER
# Log out and back in
```

---

## Network Smart Meter Setup

For network-connected smart meters (HomeWizard P1, ser2net, etc):

```yaml
services:
  dsmr:
    image: xirixiz/dsmr-reader-docker:latest
    environment:
      DSMRREADER_REMOTE_DATALOGGER_INPUT_METHOD: ipv4
      DSMRREADER_REMOTE_DATALOGGER_NETWORK_HOST: 192.168.1.100
      DSMRREADER_REMOTE_DATALOGGER_NETWORK_PORT: 23
      # ... other configuration ...
```

See [HomeWizard Integration](HOMEY_INTEGRATION.md) for detailed setup.

---

## Configuration Options

### Generate Secure Secret Key

```bash
# Generate random secret key
python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'
```

Use this in `DJANGO_SECRET_KEY`.

### Set Timezone

Find your timezone:
```bash
timedatectl list-timezones | grep -i europe
```

Common timezones:
- `Europe/Amsterdam`
- `Europe/Brussels`
- `Europe/Berlin`
- `America/New_York`
- `America/Los_Angeles`

### Change Default Password

After first login:
1. Navigate to: Settings → Users
2. Click on admin user
3. Change password
4. Save

Or via environment variable:
```yaml
environment:
  DSMRREADER_ADMIN_PASSWORD: your-secure-password
```

---

## Platform-Specific Installation

### Raspberry Pi

**Prerequisites:**
```bash
# Update system
sudo apt-get update
sudo apt-get upgrade

# Install dependencies
sudo apt-get install docker.io docker-compose git
```

**Recommended settings:**
```yaml
services:
  dsmr:
    # Use specific version for stability
    image: xirixiz/dsmr-reader-docker:6.2.0

    # Limit resources on Raspberry Pi 3 or older
    mem_limit: 512m
    cpus: 1.0
```

**Storage consideration:**
- Use external USB drive for database volume
- SD cards wear out with database writes

### Synology NAS

**Install Docker package:**
1. Open Package Center
2. Install "Docker" package
3. Install "Container Manager"

**USB Serial driver:**
Install `synokernel-usbserial` from Community Package Center

**Create stack via Container Manager:**
- Copy docker-compose.yaml content
- Adjust paths for Synology structure

**Serial device path:**
```bash
# Find device
ls -l /dev/ttyUSB*

# Set permissions
sudo chmod 666 /dev/ttyUSB0
```

### Windows (Docker Desktop)

**Prerequisites:**
- Windows 10/11 Pro, Enterprise, or Education
- WSL2 enabled
- Docker Desktop for Windows

**Installation:**
1. Install Docker Desktop
2. Enable WSL2 backend
3. Create project in WSL2 Linux distribution

**Serial device access:**
- Direct USB passthrough not supported in WSL2
- Options:
  1. Use network smart meter (HomeWizard)
  2. Use USB/IP forwarding
  3. Run on native Linux instead

### macOS

**Prerequisites:**
```bash
# Install Docker Desktop for Mac
# Download from: https://www.docker.com/products/docker-desktop

# Or via Homebrew
brew install --cask docker
```

**Serial device:**
```bash
# macOS devices appear as:
/dev/cu.usbserial-*
/dev/tty.usbserial-*

# Use cu.* devices
ls -l /dev/cu.*
```

**docker-compose.yaml:**
```yaml
devices:
  - /dev/cu.usbserial-AB0IXYZ:/dev/ttyUSB0
```

---

## Post-Installation

### Verify Installation

**Check containers are running:**
```bash
docker-compose ps
```

Expected output:
```
NAME      IMAGE                              STATUS
dsmr      xirixiz/dsmr-reader-docker:latest  Up
dsmrdb    postgres:17-alpine                 Up
```

**Check logs:**
```bash
docker-compose logs dsmr | tail -50
```

Should see:
- No errors
- "Server started" messages
- Telegram processing messages

**Test web interface:**
```bash
curl http://localhost/healthcheck
```

Should return HTML page.

### Configure Smart Meter

1. Access web interface: `http://localhost`
2. Login with admin credentials
3. Navigate to: Configuration → Datalogger
4. Configure:
   - DSMR version (4.x or 5.x)
   - Serial port: `/dev/ttyUSB0` or `/dev/dsmr_p1`
   - Baud rate: `115200` (DSMR 4/5) or `9600` (DSMR 2/3)
5. Save changes
6. Restart container: `docker-compose restart dsmr`

### Verify Data Collection

**Check dashboard:**
- Navigate to Dashboard
- Should see graphs within 10 seconds
- Data updates every 10 seconds

**Check database:**
```bash
docker exec dsmrdb psql -U dsmrreader -d dsmrreader -c "SELECT COUNT(*) FROM dsmr_reading_dsmrreading;"
```

Should show increasing count.

---

## Upgrade

### Backup First

**Database backup:**
```bash
docker exec dsmrdb pg_dump -U dsmrreader dsmrreader > backup_$(date +%Y%m%d).sql
```

**Configuration backup:**
```bash
cp docker-compose.yaml docker-compose.yaml.backup
```

### Pull New Image

```bash
# Stop services
docker-compose down

# Pull latest image
docker-compose pull

# Start services
docker-compose up -d

# Check logs
docker-compose logs -f
```

### Upgrade to Specific Version

```yaml
services:
  dsmr:
    image: xirixiz/dsmr-reader-docker:6.2.0  # Specific version
```

Then:
```bash
docker-compose down
docker-compose pull
docker-compose up -d
```

---

## Uninstallation

### Remove Containers and Volumes

```bash
# Stop and remove containers
docker-compose down

# Remove with volumes (deletes all data!)
docker-compose down -v

# Remove images
docker rmi xirixiz/dsmr-reader-docker:latest
docker rmi postgres:17-alpine
```

### Remove Project Files

```bash
cd ~
rm -rf dsmr-reader
```

### Remove User Permissions

```bash
# Remove from docker group
sudo gpasswd -d $USER docker

# Remove from dialout group
sudo gpasswd -d $USER dialout
```

---

## Troubleshooting Installation

### Docker Won't Start

**Check Docker is running:**
```bash
sudo systemctl status docker
```

**Start Docker:**
```bash
sudo systemctl start docker
```

### Permission Denied

**Not in docker group:**
```bash
# Add user
sudo usermod -aG docker $USER

# Log out and back in
# Verify
groups | grep docker
```

### Port Already in Use

**Change port in docker-compose.yaml:**
```yaml
ports:
  - "8080:80"  # Use port 8080 instead of 80
```

### Container Won't Start

**Check logs:**
```bash
docker-compose logs dsmr
docker-compose logs dsmrdb
```

**Enable debug mode:**
```yaml
environment:
  CONTAINER_ENABLE_DEBUG: "true"
```

### Serial Device Not Found

**Check device exists:**
```bash
ls -l /dev/ttyUSB*
```

**Check permissions:**
```bash
ls -l /dev/ttyUSB0
groups | grep dialout
```

**Verify in container:**
```bash
docker exec dsmr ls -l /dev/ttyUSB0
```

---

## Need Help?

1. **Check this documentation** - Most answers are here
2. **Search issues** - [GitHub Issues](https://github.com/xirixiz/dsmr-reader-docker/issues)
3. **Ask community** - [GitHub Discussions](https://github.com/xirixiz/dsmr-reader-docker/discussions)
4. **Upstream docs** - [DSMR Reader Documentation](https://dsmr-reader.readthedocs.io/en/v6/)

---

**Maintained by [@xirixiz](https://github.com/xirixiz)**
