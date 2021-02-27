[![DockerPulls](https://img.shields.io/docker/pulls/xirixiz/dsmr-reader-docker.svg)](https://img.shields.io/docker/pulls/xirixiz/dsmr-reader-docker/)
[![BuyMeCoffee][buymecoffeebadge]][buymecoffee]

##### STABLE releases. Download and install DSMR Reader release on container startup (See DSMR_RELEASE variable for more information)
```
latest-<version>-arm32v7
latest-<version>-arm64v8
latest-<version>-amd64
```

##### DEVELOPMENT releases, to be considered as unstable Docker images being tested.
```
development-<version>-arm32v7
development-<version>-arm64v8
development-<version>-amd64
```

arm32v6/armhf is deprecated since the introduction of calver.

#### DSMR Reader - Environment variables

For DSMR Reader specific environment settings, please refer to: https://dsmr-reader.readthedocs.io/nl/v4/env_settings.html

It's possible to set the following settings as environment variables, for example:
```
Required (defaults are shown as value):
- DJANGO_TIME_ZONE=Europe/Amsterdam
- VIRTUAL_HOST=localhost
```

```
Optional (defaults are shown as value):

Nginx related:
- ENABLE_NGINX_SSL=false            # Enables port 443 for nginx (/etc/ssl/private/fullchain.pem and /etc/ssl/private/privkey.pem are required to be mounted!)

Nginx .httpassword (thanks @Caroga):
- ENABLE_HTTP_AUTH=false
- HTTP_AUTH_USERNAME=
- HTTP_AUTH_PASSWORD=

Supervisord related:
- SD_LOGLEVEL=info
- SD_USER=root
- SD_GROUP=root
- DATALOGGER_MODE=standalone          # Set the datalogger mode. Valid values are sender (datlogger sender only), receiver (local datalogger disabled, api container), standalone (a single container setup)

Remote DSMR datalogger related (more info: https://dsmr-reader.readthedocs.io/nl/v4/installation/datalogger.html)
- DATALOGGER_API_HOSTS=x              # Required. Destination(s) of the DSMR Reader (Docker) host(s)
- DATALOGGER_API_KEYS=x               # Required. Add the API keys of the DSMR Reader (Docker) destination host(s)

- DATALOGGER_INPUT_METHOD=x           # Required. Only serial or ipv4 (network) are valid values
  ##################################################################################################################
- DATALOGGER_SERIAL_PORT=/dev/ttyUSB0 # Required if the input method is set to serial
- DATALOGGER_SERIAL_BAUDRATE=115200   # Required if the input method is set to serial
  ##################################################################################################################
- DATALOGGER_NETWORK_HOST=x.x.x.x     # Required if the input method is set to ipv4
- DATALOGGER_NETWORK_PORT=x           # Required if the input method is set to ipv4 (Docker port)
  ##################################################################################################################
- DATALOGGER_TIMEOUT=x                # Optional. In seconds
- DATALOGGER_SLEEP=x                  # Optional. In seconds
- DATALOGGER_DEBUG_LOGGING=false      # Optional.

DSMR related (defaults are shown as value):
- DSMRREADER_ADMIN_USER=admin                     # Webinterface user
- DSMRREADER_ADMIN_PASSWORD=admin                 # Webinterface user password
- DSMRREADER_LOGLEVEL=WARNING                     # Valid values are WARNING, INFO, DEBUG
- DJANGO_SECRET_KEY=dsmrreader                    # Secret key for encryption
- DSMRREADER_SUPPRESS_STORAGE_SIZE_WARNINGS=True  # Ignore database size notifications
- DSMRREADER_PLUGINS=dsmr_plugins.modules.plugin_name1,dsmr_plugins.modules.plugin_name2

DB related (defaults are shown as value):
- DJANGO_DATABASE_ENGINE django.db.backends.postgresql
- DJANGO_DATABASE_NAME=dsmrreader
- DJANGO_DATABASE_USER=dsmrreader
- DJANGO_DATABASE_PASSWORD=dsmrreader
- DJANGO_DATABASE_HOST=dsmrdb
- DJANGO_DATABASE_PORT=5432
- DJANGO_DATABASE_CONN_MAX_AGE=60
```

# MySQL backend - issue with DSMR running on top of MySQL - configured timezone info tables.
It manifests as "Data processing is lagging behind" message on the web-interface and with only leading information in the logs if they set to DEBUG "Missing consumption data for:"

If you drill down from here then you can eventually find this issue: dsmrreader/dsmr-reader#909
Which can be resolved by installing timezone info tables in MySQL: https://dev.mysql.com/doc/refman/8.0/en/mysql-tzinfo-to-sql.html

# DSMR Reader - Database cleanup/vacuum
It could be that you receive a notification that the database is growing, like in this issue: https://github.com/dsmrreader/dsmr-reader/issues/1165.
You can cleanup the Docker database by running the following command from the application container:

```
docker exec -ti dsmr bash -c '/app/cleandb.sh'
```

Or if you'd like to run verbose:

```
docker exec -ti dsmr bash -c '/app/cleandb.sh -v'
```

# DSMR Reader - Plugins
DSMR Reader plugins (https://dsmr-reader.readthedocs.io/en/latest/plugins.html) can be added by adding the plugin with a volume mapping and using it in the environmental variable to load it.

```
    volumes:
      - ./modules/forward_telegram_to_api.py:/dsmr/dsmr_plugins/modules/forward_telegram_to_api.py
    environment:
      - DSMRREADER_PLUGINS=dsmr_plugins.modules.forward_telegram_to_api
```

# DSMR Reader - Debugging
If you ever need to set the loglevel to DEBUG you can do that by setting the `DSMRREADER_LOGLEVEL` environmental variable

```
- DSMRREADER_LOGLEVEL=DEBUG
```

# DSMR Reader - Docker
A docker-compose file in order to start the following application in Docker:
dsmr-reader (https://github.com/dsmrreader/dsmr-reader)

The following architectures are available on the Docker Hub:
 - amd64 (default)
 - arm32
 - arm64

See https://hub.docker.com/r/xirixiz/dsmr-reader-docker/tags/ for the available images.
You can create specific architecture files by running the update_hub_images.sh file. Dockerfile.cross is being used as input (template).

You should first add the user you run Docker with on your host file system to the dialout group:
```
sudo usermod -aG dialout $(whoami)
```

# Docker-compose

An example docker-compose.yaml file can be found here:
https://raw.githubusercontent.com/xirixiz/dsmr-reader-docker/master/docker-compose.example.yaml

You should modify the docker-compose file with parameters that suit your environment, then run docker-compose afterwards:
```
docker-compose up -d
```

After starting the containers with docker-compose, the dashboard is reachable at
HTTP: http://\<hostname>:7777

After starting the containers, don't forget to modify the default DSMR version (default is DSMR v4):
http://\<hostname>:7777/admin/dsmr_datalogger/dataloggersettings/

# Docker run

Keep in mind the example below only runs dsmr, you need to run a postgres docker container or traditional postgres environment as well, since a database is needed.

```
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

# Backup and restore mechanism 1
dsmrdb in docker-compose is configured to use a docker volume. So when the application and docker containter have been removed, the postgres data still persists.

Also you could easily create a backup. Values depend on docker/docker-compose user and database variables:
```
docker-compose stop dsmr
docker exec -t dsmrdb pg_dumpall -c -U dsmrreader > dsmrreader.sql
docker-compose start dsmr
```

It's also possible to gzip ofcourse:
```
docker exec -t dsmrdb pg_dumpall -c -U dsmrreader | /bin/gzip > dsmrreader.sql.gz
```

Or drop the database and restore a backup. Values depend on docker/docker-compose user and database variables:
```
docker-compose stop dsmr
docker exec -t dsmrdb dropdb dsmrreader -U dsmrreader
docker exec -t dsmrdb createdb -O dsmrreader dsmrreader -U dsmrreader
cat dsmrreader.sql | docker exec -i dsmrdb psql -U dsmrreader
docker-compose start dsmr
```

# Backup and restore mechanism 2
Ofcourse it's also possible to use Docker's own volume backup and restore megansim.

Backup:
```
docker run -it --rm -v dsmrdb:/volume -v /tmp:/backup alpine \
    tar -cjf /backup/dsmrdb.tar.bz2 -C /volume ./
```

Restore:
```
docker run -it --rm -v dsmrdb:/volume -v /tmp:/backup alpine \
    sh -c "rm -rf /volume/* /volume/..?* /volume/.[!.]* ; tar -C /volume/ -xjf /backup/dsmrdb.tar.bz2"
 ```

# Upgrade the Postgres container to a newer release
```
- stop ONLY the dsmr reader container
- backup the dsmrdb database (see "Backup and restore mechanism" in the README.md)
- validate the dsmrdb backup!
- you could also consider to "vacuum" the database following "DSMR Reader - Database cleanup/vacuum" in the README.md.
- stop and remove the dsmrdb container
- rename the db folder that is mounted in the Docker container, containing the database data, to something else (.old, or whatever you like)
- create a new db folder with the name used to mount the folder in the Docker container (so, the folder name just before you renamed it in the previous step)
- update docker-compose or your docker run command with the new postgres version
  - be aware the client package has to be compatible with the postgres version you're going to use. Check here which version is within the dsmr image. The Docker bas image is based on python:3-slim-buster.
- start dsmrdb (it's an empty but valid postgres db now).
- restore the database backup created in step 2 (see "Backup and restore mechanism" in the README.md)
- restart the dsmrdb container
- start the dsmr container
```

# Important notes
The current configuration has been tested on Ubuntu > 17.x and Manjaro > 17.x

For Synology users:
- Drivers are necessary: http://www.jadahl.com/drivers_6.1 or http://www.jadahl.com/drivers_6.2
- The docker-compose file must be set to version 3.2 or lower.

[buymecoffee]: https://www.buymeacoffee.com/xirixiz
[buymecoffeebadge]: https://camo.githubusercontent.com/cd005dca0ef55d7725912ec03a936d3a7c8de5b5/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f6275792532306d6525323061253230636f666665652d646f6e6174652d79656c6c6f772e737667
