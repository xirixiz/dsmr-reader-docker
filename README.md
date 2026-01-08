# DSMR-reader - Docker

[![Docker Pulls](https://img.shields.io/docker/pulls/xirixiz/dsmr-reader-docker.svg?logo=docker)](https://hub.docker.com/r/xirixiz/dsmr-reader-docker/tags)
[![Docker Stars](https://img.shields.io/docker/stars/xirixiz/dsmr-reader-docker.svg?logo=docker)](https://hub.docker.com/r/xirixiz/dsmr-reader-docker)
[![GitHub Build Status](https://github.com/xirixiz/dsmr-reader-docker/actions/workflows/build_release.yml/badge.svg?logo=github)](https://github.com/xirixiz/dsmr-reader-docker/actions)
[![GitHub Stars](https://img.shields.io/github/stars/xirixiz/dsmr-reader-docker.svg?logo=github)](https://github.com/xirixiz/dsmr-reader-docker/)
[![Donate](https://img.shields.io/badge/donate-paypal-yellowgreen.svg?logo=paypal)](https://www.paypal.com/donate/?business=9M4P6DGT7U7VU&no_recurring=0&item_name=Open+source+project+development.&currency_code=EUR)

Docker container for [DSMR Reader](https://github.com/dsmrreader/dsmr-reader) - read your smart meter P1 port and visualize energy consumption.

**Built with s6-overlay v3 for robust container lifecycle management.**

---

## Quick Start

Create `docker-compose.yaml`:

```yaml
version: '3.8'

volumes:
  dsmrdb_data:

services:
  dsmrdb:
    image: postgres:17-alpine
    restart: always
    volumes:
      - dsmrdb_data:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: dsmrreader
      POSTGRES_PASSWORD: dsmrreader
      POSTGRES_DB: dsmrreader

  dsmr:
    image: xirixiz/dsmr-reader-docker:latest
    restart: always
    depends_on:
      - dsmrdb
    ports:
      - "80:80"
    devices:
      - /dev/ttyUSB0:/dev/ttyUSB0
    environment:
      DJANGO_DATABASE_HOST: dsmrdb
      DJANGO_DATABASE_NAME: dsmrreader
      DJANGO_DATABASE_USER: dsmrreader
      DJANGO_DATABASE_PASSWORD: dsmrreader
      DJANGO_TIME_ZONE: Europe/Amsterdam
      DJANGO_SECRET_KEY: change-me-to-random-string
      DSMRREADER_ADMIN_USER: admin
      DSMRREADER_ADMIN_PASSWORD: admin
```

Start it:
```bash
docker-compose up -d
```

Access the web interface at `http://localhost` (login: `admin` / `admin`)

---

## Documentation

### Getting Started
- **[Installation Guide](docs/INSTALLATION.md)** - Detailed setup instructions
- **[Configuration Reference](docs/CONFIGURATION.md)** - All environment variables explained
- **[Host Device Setup](docs/HOST_DEVICE_SETUP.md)** - Setup host device help for telegram readings (f.e. /dev/ttyUSB0)
- **[Examples](examples/)** - Docker Compose examples for different scenarios

### Advanced Usage
- **[Run Modes](docs/RUN_MODES.md)** - Standalone, server, and remote datalogger modes
- **[Advanced Setup](docs/ADVANCED_SETUP.md)** - SSL, authentication, network smart meters
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions

### Integrations
- **[HomeWizard P1 Integration](docs/HOMEY_INTEGRATION.md)** - Network-based smart meter reading

---

## Key Features

- 🚀 **s6-overlay v3** - Robust process supervision
- 🏗️ **Multi-arch** - amd64, arm32v7, arm64v8
- 🔄 **Flexible modes** - Standalone, server, or remote datalogger
- 📊 **PostgreSQL** - Reliable data storage
- 🔌 **Serial or network** - Connect via USB or TCP/IP

---

## Need Help?

- **[Documentation](docs/)** - Comprehensive guides
- **[Issues](https://github.com/xirixiz/dsmr-reader-docker/issues)** - Report bugs
- **[Discussions](https://github.com/xirixiz/dsmr-reader-docker/discussions)** - Ask questions
- **[DSMR Reader Docs](https://dsmr-reader.readthedocs.io/en/v6/)** - Upstream documentation

---

**Created by [@xirixiz](https://github.com/xirixiz) | Powered by [DSMR Reader](https://github.com/dsmrreader/dsmr-reader)**