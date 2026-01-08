# DSMR-reader - Docker

[![Docker Pulls](https://img.shields.io/docker/pulls/xirixiz/dsmr-reader-docker.svg?logo=docker)](https://hub.docker.com/r/xirixiz/dsmr-reader-docker/tags)
[![Docker Stars](https://img.shields.io/docker/stars/xirixiz/dsmr-reader-docker.svg?logo=docker)](https://hub.docker.com/r/xirixiz/dsmr-reader-docker)
[![GitHub Build Status](https://github.com/xirixiz/dsmr-reader-docker/actions/workflows/build_release.yml/badge.svg?logo=github)](https://github.com/xirixiz/dsmr-reader-docker/actions)
[![GitHub Stars](https://img.shields.io/github/stars/xirixiz/dsmr-reader-docker.svg?logo=github)](https://github.com/xirixiz/dsmr-reader-docker/)
[![Donate](https://img.shields.io/badge/donate-paypal-yellowgreen.svg?logo=paypal)](https://www.paypal.com/donate/?business=9M4P6DGT7U7VU&no_recurring=0&item_name=Open+source+project+development.&currency_code=EUR)

*DSMR-protocol reader for collecting smart meter telegrams, storing data, and visualizing energy consumption.*

**Built with s6-overlay v3 for robust container lifecycle management.**

---

## Table of Contents
- [DSMR-reader - Docker](#dsmr-reader---docker)
  - [Table of Contents](#table-of-contents)
  - [General Info](#general-info)
  - [Features](#features)
  - [Required Technologies](#required-technologies)
  - [Architectures](#architectures)
  - [Image Versioning \& Tags](#image-versioning--tags)
    - [Stable Releases (`main` branch)](#stable-releases-main-branch)
    - [Development Builds (`development` branch)](#development-builds-development-branch)
    - [Recommended Usage](#recommended-usage)
  - [Run Modes](#run-modes)
  - [Quick Start](#quick-start)
    - [Standalone Mode (Default)](#standalone-mode-default)
  - [Environment Variables](#environment-variables)
    - [Container Configuration](#container-configuration)
    - [Database Configuration](#database-configuration)
    - [Application Configuration](#application-configuration)
    - [Remote Datalogger Configuration](#remote-datalogger-configuration)
      - [API Configuration](#api-configuration)
      - [Input Method Configuration](#input-method-configuration)
  - [Advanced Setup](#advanced-setup)
    - [Server Remote Datalogger Mode](#server-remote-datalogger-mode)
    - [Remote Datalogger Mode](#remote-datalogger-mode)
    - [Using Network Smart Meters](#using-network-smart-meters)
    - [SSL/TLS Configuration](#ssltls-configuration)
    - [HTTP Basic Authentication](#http-basic-authentication)
    - [Client Certificate Authentication](#client-certificate-authentication)
    - [Database Maintenance](#database-maintenance)
  - [Troubleshooting](#troubleshooting)
    - [Timestamps are off by one hour](#timestamps-are-off-by-one-hour)
    - [Serial device not accessible](#serial-device-not-accessible)
    - [Database connection issues](#database-connection-issues)
    - [Service won't start](#service-wont-start)
    - [Web interface not accessible](#web-interface-not-accessible)
    - [SSL certificate errors](#ssl-certificate-errors)
    - [Performance issues](#performance-issues)
  - [Contributing](#contributing)
  - [Support](#support)

---

## General Info

This project provides Docker container images for [DSMR Reader](https://github.com/dsmrreader/dsmr-reader) installations. DSMR Reader is designed for reading the DSMR (Dutch Smart Meter Requirements) P1 port and visualizing energy consumption data.

---

## Features

- 🚀 **s6-overlay v3** - Advanced process supervision and initialization
- 🏗️ **Multi-architecture** - Supports amd64, arm32v7, and arm64v8
- 🔄 **Multiple run modes** - Standalone, Server Remote Datalogger, and Remote Datalogger
- 📊 **PostgreSQL backend** - Reliable data storage
- 🎨 **Web interface** - Beautiful dashboards via nginx + Gunicorn
- 🔌 **Flexible input** - Serial or network smart meter connections
- 🐳 **Docker native** - Easy deployment with Docker Compose

---

## Required Technologies
```
Docker or Podman
PostgreSQL 15+ (recommended: PostgreSQL 17)
Smart meter with P1 port (DSMR 4.0+ recommended)
```

---

## Architectures

Multi-architecture images supporting:
- `linux/amd64` (x86_64)
- `linux/arm/v7` (armhf)
- `linux/arm64` (aarch64)

---

## Image Versioning & Tags

See [Docker Hub](https://hub.docker.com/r/xirixiz/dsmr-reader-docker/tags) for the full tag list.

### Stable Releases (`main` branch)

Each stable release produces **one immutable build**:
```text
<DSMR_VERSION>-build-<YYYYMMDD>.<run>
Example: 6.2.0-build-20260108.1
```

**Floating tags** (auto-updated):

| Tag      | Tracks                    |
|----------|---------------------------|
| `6.2.0`  | Exact version (immutable) |
| `6.2`    | Latest `6.2.x`            |
| `6`      | Latest `6.x.x`            |
| `latest` | Newest stable             |

### Development Builds (`development` branch)

Rolling tag: `development` (overwritten on every build, **testing only**)

### Recommended Usage
```bash
# Production - pinned version (recommended)
xirixiz/dsmr-reader-docker:6.2.0

# Production - auto-update minor versions
xirixiz/dsmr-reader-docker:6.2

# Always latest stable
xirixiz/dsmr-reader-docker:latest

# Testing only
xirixiz/dsmr-reader-docker:development
```

---

## Run Modes

The container supports three operational modes:

| Mode | Smart Meter Input | Database | Web UI | Use Case |
|------|-------------------|----------|--------|----------|
| **`standalone`** (default) | ✅ Local | ✅ Yes | ✅ Yes | All-in-one setup |
| **`server_remote_datalogger`** | ❌ Remote only | ✅ Yes | ✅ Yes | Central server receiving from Remote Dataloggers |
| **`remote_datalogger`** | ✅ Local | ❌ No (forwards) | ❌ No | Remote location forwarding to Server Remote Datalogger |

Set via `CONTAINER_RUN_MODE` environment variable.

---

## Quick Start

### Standalone Mode (Default)

Complete setup with database and web interface:
```yaml
version: '3.8'

volumes:
  dsmrdb_data:
  dsmr_backups:

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
    volumes:
      - dsmr_backups:/app/backups
      - /dev/ttyUSB0:/dev/ttyUSB0  # Adjust to your smart meter device
    devices:
      - /dev/ttyUSB0
    environment:
      # Container configuration
      CONTAINER_RUN_MODE: standalone

      # Database configuration
      DJANGO_DATABASE_HOST: dsmrdb
      DJANGO_DATABASE_PORT: 5432
      DJANGO_DATABASE_NAME: dsmrreader
      DJANGO_DATABASE_USER: dsmrreader
      DJANGO_DATABASE_PASSWORD: dsmrreader

      # Application configuration
      DJANGO_TIME_ZONE: Europe/Amsterdam
      DJANGO_SECRET_KEY: your-secret-key-here-change-me
      DSMRREADER_ADMIN_USER: admin
      DSMRREADER_ADMIN_PASSWORD: admin
```

Start the stack:
```bash
docker-compose up -d
```

Access the web interface at `http://localhost` with credentials `admin:admin`.

---

## Environment Variables

### Container Configuration

Container-specific settings that control the behavior of the Docker container:

| Variable | Default | Description |
|----------|---------|-------------|
| `CONTAINER_RUN_MODE` | `standalone` | Operation mode: `standalone`, `server_remote_datalogger`, or `remote_datalogger` |
| `CONTAINER_ENABLE_DEBUG` | `false` | Enable verbose debug output in container initialization scripts |
| `CONTAINER_ENABLE_NGINX_ACCESS_LOGS` | `false` | Enable nginx access logs (useful for debugging, increases disk I/O) |
| `CONTAINER_ENABLE_NGINX_SSL` | `false` | Enable SSL/TLS in nginx (requires SSL certificates mounted) |
| `CONTAINER_ENABLE_HTTP_AUTH` | `false` | Enable HTTP basic authentication for web interface |
| `CONTAINER_ENABLE_CLIENTCERT_AUTH` | `false` | Enable client certificate authentication (mutual TLS) |
| `CONTAINER_ENABLE_IFRAME` | `false` | Allow embedding the web interface in iframes |
| `CONTAINER_ENABLE_VACUUM_DB_AT_STARTUP` | `false` | Run PostgreSQL vacuum on container startup (cleanup/optimize database) |

**Examples:**

Enable debug mode:
```yaml
environment:
  CONTAINER_ENABLE_DEBUG: "true"
```

Enable SSL with custom certificates:
```yaml
volumes:
  - ./certs/certificate.crt:/etc/nginx/ssl/certificate.crt:ro
  - ./certs/private.key:/etc/nginx/ssl/private.key:ro
environment:
  CONTAINER_ENABLE_NGINX_SSL: "true"
```

Enable HTTP basic authentication:
```yaml
volumes:
  - ./htpasswd:/etc/nginx/.htpasswd:ro
environment:
  CONTAINER_ENABLE_HTTP_AUTH: "true"
```

Enable iframe embedding (for dashboards):
```yaml
environment:
  CONTAINER_ENABLE_IFRAME: "true"
```

### Database Configuration

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DJANGO_DATABASE_HOST` | Yes | - | PostgreSQL hostname |
| `DJANGO_DATABASE_PORT` | No | `5432` | PostgreSQL port |
| `DJANGO_DATABASE_NAME` | Yes | - | Database name |
| `DJANGO_DATABASE_USER` | Yes | - | Database username |
| `DJANGO_DATABASE_PASSWORD` | Yes | - | Database password |

### Application Configuration

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DJANGO_TIME_ZONE` | Yes | - | Timezone (e.g., `Europe/Amsterdam`) |
| `DJANGO_SECRET_KEY` | Yes | - | Django secret key (generate a secure random string) |
| `DSMRREADER_ADMIN_USER` | Yes | - | Admin username for web interface |
| `DSMRREADER_ADMIN_PASSWORD` | Yes | - | Admin password for web interface |

**Additional DSMR Reader settings:** See [upstream documentation](https://dsmr-reader.readthedocs.io/en/v6/env_settings.html) for all available environment variables.

### Remote Datalogger Configuration

**Only required for `CONTAINER_RUN_MODE=remote_datalogger`:**

#### API Configuration

| Variable | Required | Description |
|----------|----------|-------------|
| `DSMRREADER_REMOTE_DATALOGGER_API_HOSTS` | Yes | Comma-separated Server Remote Datalogger URLs (e.g., `http://dsmr-server:8000`) |
| `DSMRREADER_REMOTE_DATALOGGER_API_KEYS` | Yes | Comma-separated API keys (must match server configuration) |

#### Input Method Configuration

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DSMRREADER_REMOTE_DATALOGGER_INPUT_METHOD` | No | `serial` | Input method: `serial` or `ipv4` |

**For `serial` input:**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DSMRREADER_REMOTE_DATALOGGER_SERIAL_DEVICE` | Yes | - | Serial device path (e.g., `/dev/ttyUSB0`) |
| `DSMRREADER_REMOTE_DATALOGGER_SERIAL_BAUDRATE` | Yes | - | Baud rate (e.g., `115200`) |
| `DSMRREADER_REMOTE_DATALOGGER_SERIAL_BYTESIZE` | Yes | - | Byte size (typically `8`) |

**For `ipv4` input:**

| Variable | Required | Description |
|----------|----------|-------------|
| `DSMRREADER_REMOTE_DATALOGGER_NETWORK_HOST` | Yes | Smart meter IP address or hostname |
| `DSMRREADER_REMOTE_DATALOGGER_NETWORK_PORT` | Yes | Smart meter TCP port |

---

## Advanced Setup

### Server Remote Datalogger Mode

Central server receiving data from Remote Dataloggers:
```yaml
services:
  dsmrdb:
    image: postgres:17-alpine
    # ... same as standalone ...

  dsmr-server:
    image: xirixiz/dsmr-reader-docker:latest
    container_name: dsmr-server
    restart: always
    depends_on:
      - dsmrdb
    ports:
      - "80:80"
    environment:
      CONTAINER_RUN_MODE: server_remote_datalogger
      # ... database config ...
      # ... application config ...
```

Configure API keys in the web interface: Settings → API → Create API key

### Remote Datalogger Mode

Remote location forwarding to Server Remote Datalogger:
```yaml
services:
  dsmr-remote:
    image: xirixiz/dsmr-reader-docker:latest
    container_name: dsmr-remote
    restart: always
    devices:
      - /dev/ttyUSB0
    environment:
      CONTAINER_RUN_MODE: remote_datalogger

      # API configuration
      DSMRREADER_REMOTE_DATALOGGER_API_HOSTS: http://dsmr-server
      DSMRREADER_REMOTE_DATALOGGER_API_KEYS: your-api-key-here

      # Serial configuration
      DSMRREADER_REMOTE_DATALOGGER_INPUT_METHOD: serial
      DSMRREADER_REMOTE_DATALOGGER_SERIAL_DEVICE: /dev/ttyUSB0
      DSMRREADER_REMOTE_DATALOGGER_SERIAL_BAUDRATE: 115200
      DSMRREADER_REMOTE_DATALOGGER_SERIAL_BYTESIZE: 8
```

### Using Network Smart Meters

For smart meters accessible via network (TCP):
```yaml
environment:
  DSMRREADER_REMOTE_DATALOGGER_INPUT_METHOD: ipv4
  DSMRREADER_REMOTE_DATALOGGER_NETWORK_HOST: 192.168.1.100
  DSMRREADER_REMOTE_DATALOGGER_NETWORK_PORT: 23
```

### SSL/TLS Configuration

Enable HTTPS with custom certificates:

1. **Generate or obtain SSL certificates:**
```bash
# Self-signed certificate (for testing)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout private.key -out certificate.crt \
  -subj "/CN=dsmr.local"
```

2. **Mount certificates and enable SSL:**
```yaml
services:
  dsmr:
    image: xirixiz/dsmr-reader-docker:latest
    ports:
      - "443:443"  # HTTPS port
      - "80:80"    # HTTP port (optional redirect)
    volumes:
      - ./certs/certificate.crt:/etc/nginx/ssl/certificate.crt:ro
      - ./certs/private.key:/etc/nginx/ssl/private.key:ro
    environment:
      CONTAINER_ENABLE_NGINX_SSL: "true"
```

### HTTP Basic Authentication

Protect the web interface with username/password:

1. **Create password file:**
```bash
# Install apache2-utils (Debian/Ubuntu) or httpd-tools (RHEL/CentOS)
htpasswd -c htpasswd dsmruser
# Enter password when prompted
```

2. **Mount password file and enable auth:**
```yaml
services:
  dsmr:
    image: xirixiz/dsmr-reader-docker:latest
    volumes:
      - ./htpasswd:/etc/nginx/.htpasswd:ro
    environment:
      CONTAINER_ENABLE_HTTP_AUTH: "true"
```

### Client Certificate Authentication

Mutual TLS authentication with client certificates:
```yaml
services:
  dsmr:
    image: xirixiz/dsmr-reader-docker:latest
    volumes:
      - ./certs/ca.crt:/etc/nginx/ssl/ca.crt:ro
      - ./certs/certificate.crt:/etc/nginx/ssl/certificate.crt:ro
      - ./certs/private.key:/etc/nginx/ssl/private.key:ro
    environment:
      CONTAINER_ENABLE_NGINX_SSL: "true"
      CONTAINER_ENABLE_CLIENTCERT_AUTH: "true"
```

### Database Maintenance

Enable automatic database vacuum on startup (useful for large databases):
```yaml
environment:
  CONTAINER_ENABLE_VACUUM_DB_AT_STARTUP: "true"
```

**Note:** This increases startup time but can improve database performance.

---

## Troubleshooting

### Timestamps are off by one hour

**Do NOT mount `/etc/localtime` into the container.** This causes timezone conflicts with PostgreSQL.

❌ **Wrong:**
```yaml
volumes:
  - /etc/localtime:/etc/localtime:ro
```

✅ **Correct:**
```yaml
environment:
  DJANGO_TIME_ZONE: Europe/Amsterdam
```

### Serial device not accessible

Ensure the device is passed to the container:
```yaml
devices:
  - /dev/ttyUSB0:/dev/ttyUSB0
```

Check permissions on the host:
```bash
ls -l /dev/ttyUSB0
# Should show: crw-rw---- 1 root dialout ...
```

### Database connection issues

Verify database is running and accessible:
```bash
docker-compose logs dsmrdb
```

Check database credentials match in both containers.

### Service won't start

Check logs for specific service:
```bash
docker-compose logs dsmr
```

Enable debug mode:
```yaml
environment:
  CONTAINER_ENABLE_DEBUG: "true"
```

Check container initialization:
```bash
docker exec dsmr s6-rc -a list
```

### Web interface not accessible

Verify nginx is running:
```bash
docker exec dsmr ps aux | grep nginx
```

Check port mapping:
```bash
docker-compose ps
```

Enable nginx access logs for debugging:
```yaml
environment:
  CONTAINER_ENABLE_NGINX_ACCESS_LOGS: "true"
```

Then check logs:
```bash
docker exec dsmr tail -f /var/log/nginx/access.log
```

### SSL certificate errors

Verify certificate files are mounted correctly:
```bash
docker exec dsmr ls -la /etc/nginx/ssl/
```

Check nginx SSL configuration:
```bash
docker exec dsmr nginx -t
```

### Performance issues

Enable database vacuum on startup:
```yaml
environment:
  CONTAINER_ENABLE_VACUUM_DB_AT_STARTUP: "true"
```

Check database size:
```bash
docker exec dsmrdb psql -U dsmrreader -d dsmrreader -c "SELECT pg_size_pretty(pg_database_size('dsmrreader'));"
```

---

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

Special thanks to:
- [@dennissiemensma](https://github.com/dsmrreader) - DSMR Reader creator
- [@bjw-s](https://github.com/bjw-s)
- [@Caroga](https://github.com/Caroga)
- [@mchangsp](https://github.com/mchangsp)

---

## Support

- **Documentation:** [DSMR Reader docs](https://dsmr-reader.readthedocs.io/en/v6/)
- **Issues:** [GitHub Issues](https://github.com/xirixiz/dsmr-reader-docker/issues)
- **Discussions:** [GitHub Discussions](https://github.com/xirixiz/dsmr-reader-docker/discussions)
- **Donate:** [PayPal](https://www.paypal.com/donate/?business=9M4P6DGT7U7VU&no_recurring=0&item_name=Open+source+project+development.&currency_code=EUR)

---

**Created by [@xirixiz](https://github.com/xirixiz)**

**Inspired by the work of [@dennissiemensma](https://github.com/dsmrreader)**