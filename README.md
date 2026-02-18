# DSMR-reader - Docker

[![Docker Pulls](https://img.shields.io/docker/pulls/xirixiz/dsmr-reader-docker.svg?logo=docker)](https://hub.docker.com/r/xirixiz/dsmr-reader-docker/tags)
[![Docker Stars](https://img.shields.io/docker/stars/xirixiz/dsmr-reader-docker.svg?logo=docker)](https://hub.docker.com/r/xirixiz/dsmr-reader-docker)
[![GitHub Build Status](https://github.com/xirixiz/dsmr-reader-docker/actions/workflows/build_release.yml/badge.svg?logo=github)](https://github.com/xirixiz/dsmr-reader-docker/actions)
[![GitHub Stars](https://img.shields.io/github/stars/xirixiz/dsmr-reader-docker.svg?logo=github)](https://github.com/xirixiz/dsmr-reader-docker/)
[![Donate](https://img.shields.io/badge/donate-paypal-yellowgreen.svg?logo=paypal)](https://www.paypal.com/donate/?business=9M4P6DGT7U7VU&no_recurring=0&item_name=Open+source+project+development.&currency_code=EUR)

Docker container for [DSMR Reader](https://github.com/dsmrreader/dsmr-reader) - read your smart meter P1 port and visualize energy consumption.

**Built with s6-overlay v3 for robust container lifecycle management.**

---

## Links

* [GitHub issues for this image](https://github.com/xirixiz/dsmr-reader-docker/issues)
* [GitHub discussions for this image](https://github.com/xirixiz/dsmr-reader-docker/discussions)
* [Upstream DSMR Reader documentation](https://dsmr-reader.readthedocs.io/)
* [Upstream DSMR Reader issues](https://github.com/dsmrreader/dsmr-reader/issues)
* [Upstream DSMR Reader discussions](https://github.com/dsmrreader/dsmr-reader/discussions)

---

## ⚠️ Breaking changes in v6 (at a glance)

If you are upgrading from v5, review the following:

- Docker variables now use the `CONTAINER_` prefix
- Default container UID/GID changed to `1000:1000`
- Legacy timezone mounts and TZ variables should be removed

✅ New installations normally require no changes.

---

Project inspired by the hard work and effort of Dennis Siemensma [@dennissiemensma](https://github.com/dennissiemensma).

Originally created by Bram van Dartel [@xirixiz](https://github.com/xirixiz) | Powered by [DSMR Reader](https://github.com/dsmrreader/dsmr-reader)
