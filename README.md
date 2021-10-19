<font size="-1">

[![DockerPulls](https://img.shields.io/docker/pulls/xirixiz/dsmr-reader-docker.svg)](https://img.shields.io/docker/pulls/xirixiz/dsmr-reader-docker/)
[![BuyMeCoffee][buymecoffeebadge]][buymecoffee]

[buymecoffee]: https://www.buymeacoffee.com/xirixiz
[buymecoffeebadge]: https://camo.githubusercontent.com/cd005dca0ef55d7725912ec03a936d3a7c8de5b5/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f6275792532306d6525323061253230636f666665652d646f6e6174652d79656c6c6f772e737667

### DSMR-reader - Docker
*DSMR-protocol reader, telegram data storage and energy consumption visualizer.
Can be used for reading the smart meter DSMR (Dutch Smart Meter Requirements) P1 port yourself at your home.
You will need a cable and hardware that can run Docker.
**Free for non-commercial use**.*

***
#### Table of contents
- [DSMR-reader - Docker](#dsmr-reader---docker)
  - [Table of contents](#table-of-contents)
  - [General info](#general-info)
  - [Screenshots](#screenshots)
  - [Technologies](#technologies)
  - [Releases](#releases)
    - [Stable releases](#stable-releases)
    - [Development releases](#development-releases)
  - [Setup](#setup)
  - [Features](#features)
  - [Issues](#issues)
  - [Inspiration](#inspiration)
  - [Contact](#contact)

***
#### General info
The purpose of this project is to provide a simplified installation of DSMR-reader using all the benefits of Docker.

***
#### Screenshots
![Example screenshot](./img/screenshot.png)

***
#### Technologies
```text
* Docker >= 19.x
* Python 3.x
* Posgres 12.x
* Posgres 13.x
* MySQL ??.?? (untested by me)
```

***
#### Releases

Docker tags/releases can be found here: https://hub.docker.com/r/xirixiz/dsmr-reader-docker/tags?page=1&ordering=last_updated

##### Stable releases
```text
latest-<version>-arm32v7
latest-<version>-arm64v8
latest-<version>-amd64
```

##### Development releases
```text
development-<version>-arm32v7
development-<version>-arm64v8
development-<version>-amd64
```

***
#### Setup
  For DSMR Reader specific environment settings, please refer to: https://dsmr-reader.readthedocs.io/nl/v4/env_settings.html

  It's possible to set the following settings as environment variables, for example:
  ```properties
  # Required (defaults are shown as value):
  - DJANGO_TIME_ZONE=Europe/Amsterdam
  - VIRTUAL_HOST=localhost
  ```

* ##### Nginx related:
  ```properties
  # Enables port 443 for nginx
  # /etc/ssl/private/fullchain.pem and /etc/ssl/private/privkey.pem are required to be mounted!
  ENABLE_NGINX_SSL=false
  ```

  Nginx .httpassword (thanks @Caroga):
  ```properties
  ENABLE_HTTP_AUTH=false
  HTTP_AUTH_USERNAME=
  HTTP_AUTH_PASSWORD=
  ```

* ##### Supervisord related:
  ```properties
  SD_LOGLEVEL=info
  SD_USER=root
  SD_GROUP=root
  ```

* ##### DSMR related (defaults are shown as value):
  ```properties
  # Webinterface user:
  DSMRREADER_ADMIN_USER=admin
  # Webinterface user password:
  DSMRREADER_ADMIN_PASSWORD=admin
  # Loglevel. Valid values are WARNING, INFO, DEBUG:
  DSMRREADER_LOGLEVEL=WARNING
  # Secret key for encryption:
  DJANGO_SECRET_KEY=dsmrreader
  # Ignore database size notifications:
  DSMRREADER_SUPPRESS_STORAGE_SIZE_WARNINGS=True
  # Plugins (custom) setup:
  DSMRREADER_PLUGINS=dsmr_plugins.modules.plugin_name1,dsmr_plugins.modules.plugin_name2
  # Enable IFrame support (f.e. for use in HASS).
  ENABLE_IFRAME=false
  ```

* ##### DB related (defaults are shown as value):
  ```properties
  # Optional. Vacuum clean Postgres on startup:
  VACUUM_DB_ON_STARTUP=false
  # Required. Defaults are set to:
  DJANGO_DATABASE_ENGINE=django.db.backends.postgresql
  DJANGO_DATABASE_NAME=dsmrreader
  DJANGO_DATABASE_USER=dsmrreader
  DJANGO_DATABASE_PASSWORD=dsmrreader
  DJANGO_DATABASE_HOST=dsmrdb
  DJANGO_DATABASE_PORT=5432
  DJANGO_DATABASE_CONN_MAX_AGE=60
  ```

* ##### DSMR Datalogger related
  ```properties
  # Set the datalogger mode.
  # Valid values are:
    # sender (datlogger sender only)
    # receiver (local datalogger disabled, api container)
    # standalone (a single container setup)
  DATALOGGER_MODE=standalone
  DATALOGGER_TIMEOUT=x
  DATALOGGER_SLEEP=x
  DATALOGGER_DEBUG_LOGGING=false
  ```

* ##### Remote DSMR datalogger related
  More info: https://dsmr-reader.readthedocs.io/nl/v4/installation/datalogger.html):
  ```properties
  # Required. Destination(s) of the DSMR Reader (Docker) host(s)
  DATALOGGER_API_HOSTS=x
  # Required. Add the API keys of the DSMR Reader (Docker) destination host(s)
  DATALOGGER_API_KEYS=x
  # Required. Only serial or ipv4 (network) are valid values
  DATALOGGER_INPUT_METHOD=x
  ```

* ##### Serial settings. Required if the input method is set to serial:
  ```properties  DATALOGGER_SERIAL_PORT=/dev/ttyUSB0
  DATALOGGER_SERIAL_BAUDRATE=115200
  ```

* ##### Network settings. Required if the input method is set to ipv4:
  ```properties
  DATALOGGER_NETWORK_HOST=x.x.x.x
  DATALOGGER_NETWORK_PORT=x
  ```

* ##### Run with docker-compose
  An example docker-compose.yaml file can be found here: https://raw.githubusercontent.com/xirixiz/dsmr-reader-docker/master/docker-compose.example.yaml.<br/>

  You should modify the docker-compose file with parameters that suit your environment, then run docker-compose afterwards:
  ```bash
  docker-compose up -d
  ```
  After starting the containers with docker-compose, the dashboard is reachable at
  ```text
  http://<hostname>:7777
  ```
  After starting the containers, don't forget to modify the default DSMR version (default is DSMR v4):
  ```text
  http://<hostname>:7777/admin/dsmr_datalogger/dataloggersettings/
  ```

* ##### Run with Docker run
  Keep in mind the example below only runs dsmr, you need to run a postgres docker container or traditional postgres environment as well, since a database is needed.

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
    --device /dev/ttyUSB0:/dev/ttyUSB0 \
    xirixiz/dsmr-reader-docker
  ```

***
#### Features
* ##### To-do list:
  ```text
  * Upgrade to Docker Alpine base image 3.13
  * Upgrade to Postgres 13 client and backend
  ```

* ##### DSMR Reader - Database cleanup/vacuum
  It could be that you receive a notification that the database is growing, like in this issue: https://github.com/dsmrreader/dsmr-reader/issues/1165.

  You can cleanup the Docker database by running the following command from the application container:
  ```bash
  docker exec -ti dsmr bash -c '/app/cleandb.sh'
  ```

  Or if you'd like to run verbose:
  ```bash
  docker exec -ti dsmr bash -c '/app/cleandb.sh -v'
  ```
* ##### DSMR Reader - Plugins
  DSMR Reader plugins (https://dsmr-reader.readthedocs.io/en/latest/plugins.html) can be added by adding the plugin with a volume mapping and using it in the environmental variable to load it.

  ```yaml
  volumes:
    - ./modules/forward_telegram_to_api.py:/dsmr/dsmr_plugins/modules/forward_telegram_to_api.py
  environment:
    - DSMRREADER_PLUGINS=dsmr_plugins.modules.forward_telegram_to_api
  ```

* ##### Backup and restore mechanism 1
  dsmrdb in docker-compose is configured to use a docker volume. So when the application and docker containter have been removed, the postgres data still persists.

  Also you could easily create a backup. Values depend on docker/docker-compose user and database variables:
  ```bash
  docker-compose stop dsmr
  docker exec -t dsmrdb pg_dumpall -c -U dsmrreader > dsmrreader.sql
  docker-compose start dsmr
  ```

  It's also possible to gzip ofcourse:
  ```bash
  docker exec -t dsmrdb pg_dumpall -c -U dsmrreader | /bin/gzip > dsmrreader.sql.gz
  ```

  Or drop the database and restore a backup. Values depend on docker/docker-compose user and database variables:
  ```bash
  docker-compose stop dsmr
  docker exec -t dsmrdb dropdb dsmrreader -U dsmrreader
  docker exec -t dsmrdb createdb -O dsmrreader dsmrreader -U dsmrreader
  cat dsmrreader.sql | docker exec -i dsmrdb psql -U dsmrreader
  docker-compose start dsmr
  ```

* ##### Backup and restore mechanism 2
    Ofcourse it's also possible to use Docker's own volume backup and restore megansim.

    Backup:
    ```bash
    docker run -it --rm -v dsmrdb:/volume -v /tmp:/backup alpine \
      tar -cjf /backup/dsmrdb.tar.bz2 -C /volume ./
    ```

    Restore:
    ```bash
    docker run -it --rm -v dsmrdb:/volume -v /tmp:/backup alpine \
      sh -c "rm -rf /volume/* /volume/..?* /volume/.[!.]* ; tar -C /volume/ -xjf /backup/dsmrdb.tar.bz2"
    ```

* ##### Backup mechanism 3
  Be aware this backup is done via the dsmr container, not via the dsmrdb container!
  Backup:
  ```bash
  docker exec -ti dsmr bash -c 'PGPASSWORD=${DJANGO_DATABASE_PASSWORD} /usr/bin/pg_dump \
    -h "${DJANGO_DATABASE_HOST}" \
    -p "${DJANGO_DATABASE_PORT}" \
    -d "${DJANGO_DATABASE_NAME}" \
    -U "${DJANGO_DATABASE_USER}"'
  ```

* ##### Postgres upgrade (docker)
  ```text
  - stop the dsmr reader container ONLY
  - backup the dsmrdb database (see "Backup and restore mechanism" in the README.md)
  - validate the dsmrdb backup!
  - you could also consider to "vacuum" the database following "DSMR Reader - Database cleanup/vacuum" in the README.md.
  - stop and remove the dsmrdb container
  - rename the db folder that is mounted in the Docker container, containing the database data, to something else (.old, or whatever you like)
  - create a new db folder with the name used to mount the folder in the Docker container (so, the folder name just before you renamed it in the previous step)
  - update docker-compose or your docker run command with the new postgres version
  - be aware the client package has to be compatible with the postgres version you're going to use. Check here which version is within the dsmr image.
  - start dsmrdb (it's an empty but valid postgres db now).
  - restore the database backup created in step 2 (see "Backup and restore mechanism" in the README.md)
  - restart the dsmrdb container
  - start the dsmr container
  ```

***
#### Issues
* ##### MySQL backend - issue with DSMR running on top of MySQL - configured timezone info tables.
  It manifests as "Data processing is lagging behind" message on the web-interface and with only leading information in the logs if they set to DEBUG "Missing consumption data for:"
  \
  If you drill down from here then you can eventually find this issue: dsmrreader/dsmr-reader#909
  \
  Which can be resolved by installing timezone info tables in MySQL: https://dev.mysql.com/doc/refman/8.0/en/mysql-tzinfo-to-sql.html

* ##### Raspberry Pi
  This issue is caused by the upgrade from Alpine 3.12 to 3.13.
  Alpine 3.13 requires the following on the host OS (https://wiki.alpinelinux.org/wiki/Release_Notes_for_Alpine_3.13.0#time64_requirements):
  ```
  - Docker 19.03.9 or newer
  - libseccomp 2.4.2 or newer
  ```
  The libseccomp package hasn't been updated for Debian stable yet, Therefore, this image won't run on any Debian (or Raspbian) stable host.
  
  Fix:
  ```bash
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 04EE7237B7D453EC 648ACFD622F3D138
  echo 'deb http://httpredir.debian.org/debian buster-backports main contrib non-free' | sudo tee -a /etc/apt/sources.list.d/debian-backports.list
  sudo apt update
  sudo apt install libseccomp2 -t buster-backports  
  ```
  
* ##### Incorrect timestamps
  Mounting ```/etc/localtime:/etc/localtime``` results most of the times in an incorrect timestamp in DSMR Reader (+/- 1 hour). Removig the mount usually solves the problem.

* ##### Synology
  For Synology, or maybe other NAS appliances, an additional driver is required:
  * Drivers are required for DSM < 7.0: http://www.jadahl.com/drivers_6.1 or http://www.jadahl.com/drivers_6.2
  * Drivers to enable USB for DSM > 7.0:
  ```sh
  sudo insmod /lib/modules/usbserial.ko
  sudo insmod /lib/modules/ftdi_sio.ko
  ```
  * The docker-compose file must be set to version 3.2 or lower.

***
#### Inspiration
Project inspired by the hard work and effort of [@dennissiemensma](https://github.com/dsmrreader)

***
#### Contact
Created by [@xirixiz](https://github.com/xirixiz) - feel free to contact me!
