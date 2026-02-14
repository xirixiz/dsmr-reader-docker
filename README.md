# DSMR-reader - Docker

[![Docker Pulls](https://img.shields.io/docker/pulls/xirixiz/dsmr-reader-docker.svg?logo=docker)](https://hub.docker.com/r/xirixiz/dsmr-reader-docker/tags)
[![Docker Stars](https://img.shields.io/docker/stars/xirixiz/dsmr-reader-docker.svg?logo=docker)](https://hub.docker.com/r/xirixiz/dsmr-reader-docker)
[![GitHub Build Status](https://github.com/xirixiz/dsmr-reader-docker/actions/workflows/build_release.yml/badge.svg?logo=github)](https://github.com/xirixiz/dsmr-reader-docker/actions)
[![GitHub Stars](https://img.shields.io/github/stars/xirixiz/dsmr-reader-docker.svg?logo=github)](https://github.com/xirixiz/dsmr-reader-docker/)
[![Donate](https://img.shields.io/badge/donate-paypal-yellowgreen.svg?logo=paypal)](https://www.paypal.com/donate/?business=9M4P6DGT7U7VU&no_recurring=0&item_name=Open+source+project+development.&currency_code=EUR)

Docker container for [DSMR Reader](https://github.com/dsmrreader/dsmr-reader) - read your smart meter P1 port and visualize energy consumption.

**Built with s6-overlay v3 for robust container lifecycle management.**

---

## Need Help?

- **[DSMR Reader Docker Docs](https://xirixiz.github.io/dsmr-reader-docker-docs/)** - DSMR Reader Docker Documentation
- **[DSMR Reader Docs](https://dsmr-reader.readthedocs.io/en/v6/)** - DSMR Reader Upstream documentation
- **[Issues](https://github.com/xirixiz/dsmr-reader-docker/issues)** - Report bugs
- **[Discussions](https://github.com/xirixiz/dsmr-reader-docker/discussions)** - Ask questions

---

## Important notes (will be added to the [DSMR Reader Docker Docs](https://xirixiz.github.io/dsmr-reader-docker-docs/) later)

From **DSMR Reader Docker v6**, all **Docker-specific** environment variables use the `CONTAINER_` prefix to clearly separate them from DSMR Reader’s own settings. When migrating to v6, review your environment variables carefully, because DSMR Reader variables may also have changed between major versions.

### Docker-specific variables (`CONTAINER_*`)
- `CONTAINER_RUN_MODE`
- `CONTAINER_ENABLE_DEBUG`
- `CONTAINER_ENABLE_NGINX_ACCESS_LOGS`
- `CONTAINER_ENABLE_NGINX_SSL`
- `CONTAINER_ENABLE_HTTP_AUTH`
- `CONTAINER_ENABLE_CLIENTCERT_AUTH`
- `CONTAINER_ENABLE_IFRAME`
- `CONTAINER_ENABLE_VACUUM_DB_AT_STARTUP`

---

## Timezone configuration changes

### Do not use these volume mounts anymore
Remove these if you have them:

- `/etc/localtime:/etc/localtime`
- `/etc/timezone:/etc/timezone`

### Remove these environment variables
Remove these if defined:

- `TZ=Europe/Amsterdam`
- `PG_TZ=Europe/Amsterdam`

### Keep or add this if really needed
Use Django’s timezone setting:

- `DJANGO_TIME_ZONE=Europe/Amsterdam`

---

Project inspired by the hard work and effort of Dennis Siemensma [@dennissiemensma](https://github.com/dennissiemensma).

Originally created by Bram van Dartel [@xirixiz](https://github.com/xirixiz) | Powered by [DSMR Reader](https://github.com/dsmrreader/dsmr-reader)
