# DSMR-reader - Docker

[![Docker Pulls](https://img.shields.io/docker/pulls/xirixiz/dsmr-reader-docker.svg?logo=docker)](https://hub.docker.com/r/xirixiz/dsmr-reader-docker/tags)
[![Docker Stars](https://img.shields.io/docker/stars/xirixiz/dsmr-reader-docker.svg?logo=docker)](https://hub.docker.com/r/xirixiz/dsmr-reader-docker)
[![GitHub Build Status](https://github.com/xirixiz/dsmr-reader-docker/actions/workflows/build_release.yml/badge.svg?logo=github)](https://github.com/xirixiz/dsmr-reader-docker/actions)
[![GitHub Stars](https://img.shields.io/github/stars/xirixiz/dsmr-reader-docker.svg?logo=github)](https://github.com/xirixiz/dsmr-reader-docker/)
[![Donate](https://img.shields.io/badge/donate-paypal-yellowgreen.svg?logo=paypal)](https://www.paypal.com/donate/?business=9M4P6DGT7U7VU&no_recurring=0&item_name=Open+source+project+development.&currency_code=EUR)

*DSMR-protocol reader for collecting smart meter telegrams, storing data, and visualizing energy consumption.
Designed for reading the DSMR (Dutch Smart Meter Requirements) P1 port at home.
Requires compatible hardware and Docker.
**Free for non-commercial use**.*

---

## Table of Contents
- [DSMR-reader - Docker](#dsmr-reader---docker)
  - [Table of Contents](#table-of-contents)
  - [General Info](#general-info)
  - [Contribution](#contribution)
  - [Screenshots](#screenshots)
  - [Required Technologies](#required-technologies)
  - [Architectures](#architectures)
  - [Image versioning \& tags](#image-versioning--tags)
    - [Stable Releases (`main` branch)](#stable-releases-main-branch)
    - [Development Builds (`development` branch)](#development-builds-development-branch)
    - [Recommended Usage](#recommended-usage)
    - [Image Metadata](#image-metadata)
  - [Setup / Parameters](#setup--parameters)
  - [Issues](#issues)
    - [FAQ: Timestamps are off by one hour](#faq-timestamps-are-off-by-one-hour)
  - [Inspiration](#inspiration)
  - [Contact](#contact)

---

## General Info
This project provides container inages for DSMR Reader installations.

---

## Contribution
Special thanks to:
- [@dennissiemensma](https://github.com/dsmrreader) - King DSMR Reader
- [@bjw-s](https://github.com/bjw-s)
- [@Caroga](https://github.com/Caroga)
- [@mchangsp](https://github.com/mchangsp)

---

## Screenshots
![Example screenshot](./img/screenshot.png)

---

## Required Technologies
```
Docker or Podman
DMSR Reader Container image (this project)
PostgreSQL Container Image
```

---

## Architectures
Multi-architecture image supporting amd64, arm32v7, and arm64v8.

---

## Image versioning & tags
See Docker Hub for full tag list: [Docker HUB tags](https://hub.docker.com/r/xirixiz/dsmr-reader-docker/tags)
Predictable, immutable versioning for safe version pinning or rolling updates.

### Stable Releases (`main` branch)

Each stable release produces **one immutable build**:
```text
<DSMR_VERSION>-build-<YYYYMMDD>.<run>
Example: 6.2.0-build-20260102.44
```

**Floating tags** (auto-updated):

| Tag      | Tracks                    |
|----------|---------------------------|
| `6.2.0`  | Exact version (immutable) |
| `6.2`    | Latest `6.2.x`            |
| `6`      | Latest `6.x.x`            |
| `latest` | Newest stable             |

### Development Builds (`development` branch)

Rolling tag: `development` (overwritten on every build, testing only)

### Recommended Usage
```bash
# Production - pinned version
xirixiz/dsmr-reader-docker:6.2.0

# Production - auto-update minor versions
xirixiz/dsmr-reader-docker:6.2

# Production - auto-update major versions
xirixiz/dsmr-reader-docker:6

# Always latest stable
xirixiz/dsmr-reader-docker:latest

# Testing only
xirixiz/dsmr-reader-docker:development
```

### Image Metadata

OCI-compliant labels for traceability:
```bash
docker inspect xirixiz/dsmr-reader-docker:latest | jq '.[0].Config.Labels'
```

Key labels:
- `io.github.dsmrreader.upstream.version` — DSMR Reader version
- `io.github.dsmrreader.docker.release` - Full immutable version
- `org.opencontainers.image.revision` — Git commit SHA

---

## Setup / Parameters
Refer to upstream [DSMR Reader documentation](https://dsmr-reader.readthedocs.io/en/v6/) for environment variables.

---

## Issues

### FAQ: Timestamps are off by one hour

Do **not** mount `/etc/localtime:/etc/localtime` into the DSMR Reader container.
This commonly causes timezone offsets (±1 hour), especially when using PostgreSQL.

**Solution:**
Remove the mount and configure the timezone using `DJANGO_TIME_ZONE`.

---

## Inspiration
Inspired by the work of [@dennissiemensma](https://github.com/dsmrreader).

---

## Contact
Created by [@xirixiz](https://github.com/xirixiz)
