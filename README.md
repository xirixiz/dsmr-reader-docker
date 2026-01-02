---

<font size="-1">

[![Docker Pulls](https://img.shields.io/docker/pulls/xirixiz/dsmr-reader-docker.svg?logo=docker)](https://hub.docker.com/r/xirixiz/dsmr-reader-docker/tags)
[![Docker Stars](https://img.shields.io/docker/stars/xirixiz/dsmr-reader-docker.svg?logo=docker)](https://hub.docker.com/r/xirixiz/dsmr-reader-docker)
[![GitHub Build Status](https://github.com/xirixiz/dsmr-reader-docker/actions/workflows/build_release.yml/badge.svg?logo=github)](https://github.com/xirixiz/dsmr-reader-docker/actions)
[![GitHub Stars](https://img.shields.io/github/stars/xirixiz/dsmr-reader-docker.svg?logo=github)](https://github.com/xirixiz/dsmr-reader-docker/)
[![Donate](https://img.shields.io/badge/donate-paypal-yellowgreen.svg?logo=paypal)](https://www.paypal.com/donate/?business=9M4P6DGT7U7VU&no_recurring=0&item_name=Open+source+project+development.&currency_code=EUR)
<br><br>
[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/xirixiz)

### DSMR-reader - Docker

*DSMR-protocol reader, telegram data storage, and energy consumption visualizer.
Can be used for reading the smart meter DSMR (Dutch Smart Meter Requirements) P1 port yourself at your home.
You will need a cable and hardware that can run Docker.
**Free for non-commercial use**.*

---

#### Table of Contents
- [General Info](#general-info)
- [Contribution](#contribution)
- [Screenshots](#screenshots)
- [Technologies](#technologies)
- [Architectures](#Architectures)
- [Image versioning & tags](#Image-versioning--tags)
- [Setup / Parameters](#setup--parameters)
  - [Public Access Warning](#public-access-warning)
  - [Settings](#settings)
  - [Nginx Related](#nginx-related)
  - [DSMR Related](#dsmr-related)
  - [DB Related](#db-related)
  - [DSMR Datalogger Related](#dsmr-datalogger-related)
  - [Run with Docker Compose](#run-with-docker-compose)
  - [Run with Docker Run](#run-with-docker-run)
  - [Environment Variables from Files (Docker Secrets)](#environment-variables-from-files-docker-secrets)
- [DSMR-Reader - Docker and Homewizard P1 Meter Integration](#dsmr-reader---docker-and-homewizard-p1-meter-integration)
  - [Prerequisites](#prerequisites)
  - [Plugin Preparation](#plugin-preparation)
  - [Docker Setup](#docker-setup)
  - [Original Post](#original-post)
- [Features](#features)
- [Issues](#issues)
- [Inspiration](#inspiration)
- [Contact](#contact)

---

#### General Info
This project provides the containers for DSMR-reader installations.

#### Contribution
Special thanks to the following persons for their great contribution(s):
- [@dennissiemensma](https://github.com/dsmrreader)
- [@bjw-s](https://github.com/bjw-s)
- [@Caroga](https://github.com/Caroga)
- [mchangsp](https://github.com/mchangsp)

---

#### Screenshots
![Example screenshot](./img/screenshot.png)

---

#### Technologies
```text
* Docker >= 20.x
* Python 3.x
* Postgres >= 13.x, max 16.x
* MySQL ??.?? (untested by me)
```

---

#### Architectures
This is a multi-arch image and will also run on a Raspberry Pi or other Docker-enabled ARMv7/8 devices.

| Image Tag   | Architectures           | Image OS     |
| :---------- | :---------------------- | :------------|
| latest      | amd64, arm32v7, arm64v8 | Debian Linux |
| development | amd64, arm32v7, arm64v8 | Debian Linux |

Docker tags/releases can be found [here](https://hub.docker.com/r/xirixiz/dsmr-reader-docker/tags?page=1&ordering=last_updated).

---

#### Image versioning & tags

This image follows a **predictable, immutable versioning scheme** so you can safely pin versions or follow rolling updates.

##### Stable releases (`main` branch)

Each stable DSMR Reader release produces **one immutable build**, identified by a build suffix:
```text
<DSMR_VERSION>-build-<YYYYMMDD>.<run>
Example: 6.2.0-build-20260102.44
```

On top of that, the following **floating tags** are updated to point to the latest compatible build:

| Tag      | Meaning                   |
| -------- | --------------------------|
| `6.2.0`  | Exact DSMR Reader version |
| `6.2`    | Latest `6.2.x` release    |
| `6`      | Latest `6.x.x` release    |
| `latest` | Latest stable release     |

This means:
- **Exact tags** (`6.2.0`) are immutable and never change
- **Minor tags** (`6.2`) move forward within the same minor series
- **Major tags** (`6`) move forward within the same major series
- `latest` always points to the newest stable release

##### Development builds (`development` branch)

The `development` branch always publishes **one rolling tag**: ```development```

This tag is **intentionally overwritten** on every build and should only be used for testing or development purposes.

##### Recommended usage

- **Production (safe & reproducible)**
xirixiz/dsmr-reader-docker:6.2.0

- **Production (auto-updating within minor version)**
xirixiz/dsmr-reader-docker:6.2

- **Production (auto-updating within major version)**
xirixiz/dsmr-reader-docker:6

- **Always latest stable**
xirixiz/dsmr-reader-docker:latest

- **Development / testing only**
xirixiz/dsmr-reader-docker:development

##### Image metadata (labels)

All images include **OCI-compliant metadata labels** for traceability.

Inspect them with for example: ```docker inspect xirixiz/dsmr-reader-docker:latest | jq '.[0].Config.Labels'```

Important labels:

- `org.opencontainers.image.version`
  Full immutable image version
  *(e.g. `6.2.0-build-20260102.44`)*

- `org.opencontainers.image.revision`
  Git commit SHA used for the build

- `io.github.dsmrreader.upstream.version`
  DSMR Reader upstream version

- `io.github.dsmrreader.docker.release`
  Docker build release identifier

- `io.github.dsmrreader.branch`
  Git branch used for the build

#### Setup / Parameters

##### Public Access Warning
Exposing your DSMR-reader installation to the Internet?
Consider additionally using HTTP Auth (see below) or enabling *"Force password login everywhere"* in the Frontend settings in DSMR-reader, to prevent public access.

##### Settings
For DSMR Reader specific environment settings, please refer to: [DSMR-reader env settings docs](https://dsmr-reader.readthedocs.io/en/v6/reference/environment-variables/)

It's possible to set the following settings as environment variables, for example:
```properties
# Required (defaults are shown as value):
- DJANGO_TIME_ZONE=Europe/Amsterdam
- VIRTUAL_HOST=localhost
# It's possible to map a UID/GID with a user/group from your local system.
# This will not change the username, only match IDs to prevent issues with access rights!
- DUID=803
- DGID=803
```

##### Nginx Related
```properties
# Default inside the container nginx is running on port 80.
# In some cases (host network f.e.), some people requested to be able to change the default listen port.
# However, in most cases this setting isn't being used.
NGINX_LISTEN_PORT=80
```

```properties
# Default nginx generated access logs.
# In some cases you want to disable this, because e.g., you use a reverse proxy which also generates access logs
ENABLE_NGINX_ACCESS_LOGS=false
```

```properties
# Enables port 443 for nginx
# /etc/ssl/private/fullchain.pem and /etc/ssl/private/privkey.pem are required to be mounted!
ENABLE_NGINX_SSL=false
```

```properties
# ENABLE HSTS on SSL: https://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security
ENABLE_NGINX_ENABLE_HSTS=false
```

```properties
# Redirect HTTP traffic to HTTPS
ENABLE_NGINX_SSL_REDIRECT=false
```

Nginx HTTP Auth:
```properties
ENABLE_HTTP_AUTH=false
HTTP_AUTH_USERNAME=
HTTP_AUTH_PASSWORD=
```

*It's not possible to combine the following settings!!!:*
```properties
ENABLE_NGINX_SSL="false"
NGINX_LISTEN_PORT
```

##### DSMR Related (defaults are shown as value):
```properties
# Webinterface user:
DSMRREADER_ADMIN_USER=admin
# Webinterface user password:
DSMRREADER_ADMIN_PASSWORD=your-personal-password
# Loglevel. Valid values are: "DEBUG", "WARNING", "ERROR". Default: "ERROR"
DSMRREADER_LOGLEVEL=ERROR
# Secret key for encryption:
DJANGO_SECRET_KEY=dsmrreader
# Ignore database size notifications:
DSMRREADER_SUPPRESS_STORAGE_SIZE_WARNINGS=true
# Plugins (custom) setup:
DSMRREADER_PLUGINS=dsmr_plugins.modules.plugin_name1,dsmr_plugins.modules.plugin_name2
# Enable IFrame support (e.g., for use in HASS).
ENABLE_IFRAME=false
```

##### DB Related (defaults are shown as value):
```properties
# Optional. Vacuum clean Postgres on startup:
ENABLE_VACUUM_DB_ON_STARTUP=false
# Required. Defaults are set to:
DJANGO_DATABASE_ENGINE=django.db.backends.postgresql
DJANGO_DATABASE_NAME=dsmrreader
DJANGO_DATABASE_USER=dsmrreader
DJANGO_DATABASE_PASSWORD=dsmrreader
DJANGO_DATABASE_HOST=dsmrdb
DJANGO_DATABASE_PORT=5432
DJANGO_DATABASE_CONN_MAX_AGE=60
```

##### DSMR Datalogger Related
When you are connecting to P1 via a network socket, you need to run DSMR Reader in standalone mode.
Ignore the errors about `/dev/ttyUSB*` and head over to the DSMR Reader datalogger configuration in the admin panel and configure the setting so it matches your environment. More info: [Issue #303](https://github.com/xirixiz/dsmr-reader-docker/issues/303#issuecomment-1345383612)

- `DSMRREADER_OPERATION_MODE` - Run DSMR Reader in one of the following modes (default is standalone with the serial flavor):
  - `standalone` - Run all processes, including backend, GUI, and datalogger. There are two flavors:
    - `standalone - serial` - Use a serial connection for the datalogger.
    - `standalone - ipv4` - Use a network socket for the datalogger.
  - `api_server` - Run all processes, except the datalogger process. A remote datalogger is required to collect DSMR Reader telegrams.
  - `api_client` - Only start the datalogger client, which sends the P1 telegrams to the `api_server`. It is required to set up `DATALOGGER_API_*` environment variables.

![Configuration Image 1](https://user-images.githubusercontent.com/11210639/207313372-6bffa581-8c3e-4b9f-9ef2-91b6e6b2b3c4.png)
![Configuration Image 2](https://user-images.githubusercontent.com/11210639/207313462-94a2a545-87b1-43cc-a9de-eff250a38d11.png)
![Configuration Image 3](https://user-images.githubusercontent.com/11210639/207313567-f4068dba-a352-4628-b873-d824e0724c54.png)

##### DSMR Reader Datalogger - Standalone - Serial (default)
More info: [DSMR-reader remote datalogger installation docs](https://dsmr-reader.readthedocs.io/nl/v5/how-to/installation/remote-datalogger.html#a-serial-port-env)

The default startup values for DSMR Reader standalone are:
```properties
DSMRREADER_REMOTE_DATALOGGER_INPUT_METHOD=serial
DSMRREADER_REMOTE_DATALOGGER_SERIAL_PORT=/dev/ttyUSB0

# DSMR meter version 4/5
DSMRREADER_REMOTE_DATALOGGER_SERIAL_BAUDRATE=115200
DSMRREADER_REMOTE_DATALOGGER_SERIAL_BYTESIZE=8
DSMRREADER_REMOTE_DATALOGGER_SERIAL_PARITY=N
```

Some meters running on an older version can be set with the following values:
```properties
# DSMR meter version 2/3 settings
DSMRREADER_REMOTE_DATALOGGER_SERIAL_BAUDRATE=9600
DSMRREADER_REMOTE_DATALOGGER_SERIAL_BYTESIZE=7
DSMRREADER_REMOTE_DATALOGGER_SERIAL_PARITY=E
```

##### DSMR Reader Datalogger - Standalone - IPv4
More info: [DSMR-reader remote datalogger installation docs](https://dsmr-reader.readthedocs.io/nl/v5/how-to/installation/remote-datalogger.html#b-network-socket-env)

Instead of a serial connection, it's also possible to use a network socket. Define the following variables:
```properties
DSMRREADER_REMOTE_DATALOGGER_INPUT_METHOD=ipv4
DSMRREADER_REMOTE_DATALOGGER_NETWORK_HOST=127.0.0.1 # default
DSMRREADER_REMOTE_DATALOGGER_NETWORK_PORT=2000 # default
```

##### Remote DSMR Datalogger - API Client
More info: [DSMR-reader remote datalogger installation docs](https://dsmr-reader.readthedocs.io/nl/v5/how-to/installation/remote-datalogger.html#api-config-env)
```properties
# Required. Instructs dsmr reader to start in api_client mode
DSMRREADER_OPERATION_MODE=api_client
# Required. Destination(s) of the DSMR Reader (Docker) host(s)
DSMRREADER_REMOTE_DATALOGGER_API_HOSTS=x
# Required. Add the API keys of the DSMR Reader (Docker) destination host(s)
DSMRREADER_REMOTE_DATALOGGER_API_KEYS=x
```

##### Remote DSMR Datalogger - API Server
More info: [DSMR-reader remote datalogger installation docs](https://dsmr-reader.readthedocs.io/nl/v5/how-to/installation/remote-datalogger.html#api-config-env)

The configured `api_client` will push data to the `api_server`. The only difference between `standalone` and `api_server` is that the datalogger process isn't running.
```properties
# Required. Instructs dsmr reader to start in api_server mode, which means no datalogger process.
# All telegrams are coming in through the API
DSMRREADER_OPERATION_MODE=api_server
```

##### Remote DSMR Datalogger - Optional Settings
More info: [DSMR-reader remote datalogger installation docs](https://dsmr-reader.readthedocs.io/nl/v5/how-to/installation/remote-datalogger.html#other-settings-env)
```properties
DSMRREADER_REMOTE_DATALOGGER_TIMEOUT=x
DSMRREADER_REMOTE_DATALOGGER_SLEEP=x
DSMRREADER_REMOTE_DATALOGGER_DEBUG_LOGGING=false
```

##### Run with Docker Compose
An example `docker-compose.yaml` file can be found [here](https://raw.githubusercontent.com/xirixiz/dsmr-reader-docker/main/examples/docker-compose.example.yaml).

Modify the `docker-compose` file with parameters that suit your environment, then run:
```bash
docker-compose up -d
```
After starting the containers with Docker Compose, the dashboard is reachable at:
```text
http://<hostname>:7777
```
Don't forget to modify the default DSMR version (default is DSMR v4) after starting the containers:
```text
http://<hostname>:7777/admin/dsmr_datalogger/dataloggersettings/
```

##### Run with Docker Run
**Note:** The example below only runs DSMR. You need to run a Postgres Docker container or traditional Postgres environment as well, since a database is needed.

```bash
docker run -d \
  --name dsmr \
  --restart always \
  -p 7777:80 \
  -p 7779:443 \
  -e DJANGO_TIME_ZONE=Europe/Amsterdam \
  -e DJANGO_DATABASE_HOST=x.x.x.x \
  -e DJANGO_DATABASE_USER=dsmrreader \
  -e DJANGO_DATABASE_PASSWORD=dsmrreader \
  -e VIRTUAL_HOST=localhost \
  --no-healthcheck \
  --device /dev/ttyUSB0:/dev/ttyUSB0 \
  xirixiz/dsmr-reader-docker
```

The `--no-healthcheck` argument should only be used when the containers function without presenting the DSMR Reader web interface, for example in datalogger sender mode. By default, this argument should not be used!

##### Environment Variables from Files (Docker Secrets)
You can set any environment variable from a file by using a special prepend `FILE__`.

**Example:**
```yaml
services:
  some_service:
    image: some_image
    environment:
      FILE__SECRET: /run/secrets/a_secret_file
    secrets:
      - a_secret_file

secrets:
  a_secret_file:
    file: somedir/my_secret.txt
```

This setup mounts `my_secret.txt` as `/run/secrets/a_secret_file`. The secrets section under the service authorizes the service to use the `a_secret_file` secret. The environment variable `FILE__SECRET` tells the service what file to read to set/get the value of the environment variable `SECRET`.

Internal secrets:
```yaml
secrets:
  a_secret_file:
    file: ./secrets/a_secret_file.txt  # Define the path to your secret file
```

External secrets (for example Docker Swarm):
```yaml
secrets:
  a_secret_file:
    external: true
```

---

#### DSMR-Reader - Docker and Homewizard P1 Meter Integration

This guide explains how to install and configure a DSMR Reader plugin to read Homewizard P1 telegrams and inject them into DSMR Reader.

##### Prerequisites
- A working instance of [DSMR Reader in Docker](https://github.com/xirixiz/dsmr-reader-docker)
- A working Homewizard P1 meter with Local API enabled
- The Homewizard P1 meter IP address

##### Plugin Preparation

**Assumption:**
Your `docker-compose.yaml` file is in the folder `/home/pi/dsmr`

**On your Docker host:**

1. Create a folder `/home/pi/dsmr/plugins`
2. Inside the folder `/home/pi/dsmr/plugins`, create a file `homewizard_p1.py` with the following contents (replace `1.2.3.4` with the Homewizard P1 meter IP address):

    ```python
    import requests
    from django.dispatch import receiver
    from dsmr_backend.signals import backend_called
    import dsmr_datalogger.services.datalogger

    HOMEWIZARD_ENDPOINT = 'http://1.2.3.4:80/api/v1/telegram'
    HOMEWIZARD_TIMEOUT = 5

    @receiver(backend_called)
    def handle_backend_called(**kwargs):
        response = requests.get(HOMEWIZARD_ENDPOINT, timeout=HOMEWIZARD_TIMEOUT)

        if response.status_code != 200:
            print(' [!] HomeWizard plugin: v1 telegram endpoint failed (HTTP {}): {}'.format(response.status_code, response.text))
            return

        dsmr_datalogger.services.datalogger.telegram_to_reading(data=response.text)
    ```

##### Docker Setup

1. Navigate to folder `/home/pi/dsmr`
2. Edit your `docker-compose.yaml` file
3. Add the following definition to the `volumes:` section:

    ```yaml
    - ./plugins/homewizard_p1.py:/app/dsmr_plugins/modules/homewizard_p1.py
    ```

4. Add the following definitions to the `environment:` section:

    ```yaml
    - DSMRREADER_OPERATION_MODE=api_server
    - DSMRREADER_PLUGINS=dsmr_plugins.modules.homewizard_p1
    ```

5. Save the `docker-compose.yaml` file
6. To stop DSMR Reader, run:

    ```bash
    docker-compose down
    ```

7. To start DSMR Reader, run:

    ```bash
    docker-compose up -d
    ```

##### Original Post
The original instructions are (partly in Dutch) on [GitHub](https://github.com/xirixiz/dsmr-reader-docker/issues/301). The Python source code in the original post was missing an import statement. The instructions have been grouped together and translated into English.

For an alternative solution using Home Assistant automations, see [this guide](https://community.home-assistant.io/t/dsmr-reader-docker-and-homewizard-p1-meter-integration/747265).

---

#### Features

##### DSMR Reader - Database Cleanup/Vacuum
You might receive a notification that the database is growing, like in [this issue](https://github.com/dsmrreader/dsmr-reader/issues/1165).

Clean up the Docker database by running the following command from the application container:
```bash
docker exec -ti dsmr bash -c '/app/cleandb.sh'
```

Or, to run verbose:
```bash
docker exec -ti dsmr bash -c '/app/cleandb.sh -v'
```

##### DSMR Reader - Plugins
DSMR Reader plugins ([documentation](https://dsmr-reader.readthedocs.io/en/latest/plugins.html)) can be added by adding the plugin with a volume mapping and using it in the environmental variable to load it.

```yaml
volumes:
  - ./modules/forward_telegram_to_api.py:/app/dsmr_plugins/modules/forward_telegram_to_api.py
environment:
  - DSMRREADER_PLUGINS=dsmr_plugins.modules.forward_telegram_to_api
```

##### Backup and Restore Mechanism 1
`dsmrdb` in `docker-compose` is configured to use a Docker volume. So when the application and Docker container have been removed, the Postgres data still persists.

You can easily create a backup. Values depend on Docker/docker-compose user and database variables:
```bash
docker-compose stop dsmr
docker exec -t dsmrdb pg_dumpall -c -U dsmrreader > dsmrreader.sql
docker-compose start dsmr
```

It's also possible to gzip:
```bash
docker exec -t dsmrdb pg_dumpall -c -U dsmrreader | /bin/gzip > dsmrreader.sql.gz
```

Or drop the database and restore a backup. Values depend on Docker/docker-compose user and database variables:
```bash
docker-compose stop dsmr
docker exec -t dsmrdb dropdb dsmrreader -U dsmrreader
docker exec -t dsmrdb createdb -O dsmrreader dsmrreader -U dsmrreader
cat dsmrreader.sql | docker exec -i dsmrdb psql -U dsmrreader
docker-compose start dsmr
```

##### Backup and Restore Mechanism 2
You can also use Docker's own volume backup and restore mechanism.

**Backup:**
```bash
docker run -it --rm -v dsmrdb:/volume -v /tmp:/backup alpine \
  tar -cjf /backup/dsmrdb.tar.bz2 -C /volume ./
```

**Restore:**
```bash
docker run -it --rm -v dsmrdb:/volume -v /tmp:/backup alpine \
  sh -c "rm -rf /volume/* /volume/..?* /volume/.[!.]* ; tar -C /volume/ -xjf /backup/dsmrdb.tar.bz2"
```

##### Backup Mechanism 3
*Note:* This backup is done via the `dsmr` container, not via the `dsmrdb` container!

**Backup:**
```bash
docker exec -ti dsmr bash -c 'PGPASSWORD=${DJANGO_DATABASE_PASSWORD} /usr/bin/pg_dump \
  -h "${DJANGO_DATABASE_HOST}" \
  -p "${DJANGO_DATABASE_PORT}" \
  -d "${DJANGO_DATABASE_NAME}" \
  -U "${DJANGO_DATABASE_USER}"'
```

##### Postgres Upgrade (Docker)
```text
- Stop the DSMR Reader container ONLY
- Backup the dsmrdb database (see "Backup and restore mechanism" in the README.md)
- Validate the dsmrdb backup!
- Consider "vacuuming" the database following "DSMR Reader - Database cleanup/vacuum" in the README.md.
- Stop and remove the dsmrdb container
- Rename the db folder that is mounted in the Docker container, containing the database data, to something else (.old, etc.)
- Create a new db folder with the original mount name
- Update `docker-compose` or your Docker run command with the new Postgres version
- Ensure the client package is compatible with the Postgres version you're using. Check the DSMR image for supported versions.
- Start `dsmrdb` (it's an empty but valid Postgres DB now).
- Restore the database backup created in step 2 (see "Backup and restore mechanism" in the README.md)
- Restart the `dsmrdb` container
- Start the `dsmr` container
```

##### UID/GID
When using volumes (`-v` or `--volume` flags), permissions issues can occur between the host OS and the container. To avoid this, specify a user ID `DUID` and group ID `DGID` from the local system in the Docker container. Ensure the owner of the directory has all permissions on the volume you'd like to mount into the Docker container.

Identify a UID or GID by executing:
```bash
id xirixiz
uid=1000(xirixiz) gid=1000(xirixiz) groups=1000(xirixiz) 1001(docker)
```

---

#### Issues

##### MySQL Backend - Issue with DSMR Running on Top of MySQL
**Problem:** Configured timezone info tables result in "Data processing is lagging behind" messages on the web interface and only leading information in the logs if set to DEBUG: "Missing consumption data for:"

**Solution:**
Drill down to find the issue: [dsmrreader/dsmr-reader#909](https://github.com/dsmrreader/dsmr-reader/issues/909)

Resolve by installing timezone info tables in MySQL: [MySQL Timezone Documentation](https://dev.mysql.com/doc/refman/8.0/en/mysql-tzinfo-to-sql.html)

##### Raspberry Pi
**Issue:** Caused by the upgrade from Alpine 3.12 to 3.13. Alpine 3.13 requires:
```
- Docker 19.03.9 or newer
- libseccomp 2.4.2 or newer
```
The `libseccomp` package hasn't been updated for Debian stable yet. Therefore, this image won't run on any Debian (or Raspbian) stable host.

**Fix:**
```bash
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 04EE7237B7D453EC 648ACFD622F3D138
echo 'deb http://httpredir.debian.org/debian buster-backports main contrib non-free' | sudo tee -a /etc/apt/sources.list.d/debian-backports.list
sudo apt update
sudo apt install libseccomp2 -t buster-backports
```

##### Incorrect Timestamps
Mounting `/etc/localtime:/etc/localtime` often results in incorrect timestamps in DSMR Reader (+/- 1 hour). Removing the mount usually solves the problem.

##### Synology
For Synology or other NAS appliances, an additional driver is required:
- [synokernel-usbserial](https://synocommunity.com/package/synokernel-usbserial)
- Validate your USB devices with ```lsusb -cui```
- For the Docker container to be able to access the serial device, you need to set its permissions correctly. The easiest way to do this is: ```sudo chmod 666 /dev/tty<your_usb_device>```

**Additional Links:**
- [Reddit Discussion](https://www.reddit.com/r/synology/comments/y92eyu/usb_serial_drivers_cp210x_for_dsm_62/)

---

#### Inspiration
Project inspired by the hard work and effort of [@dennissiemensma](https://github.com/dsmrreader).

---

#### Contact
Created by [@xirixiz](https://github.com/xirixiz) - feel free to contact me!

</font>

---
