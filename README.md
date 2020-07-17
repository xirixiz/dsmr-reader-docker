[![DockerPulls][dockerpullsbadge]][dockerpulls]
[![BuyMeCoffee][buymecoffeebadge]][buymecoffee]

#### DSMR Reader - Releases info
##### Download and install DSMR Reader release on container startup
```
DYNUP-arm32v6
DYNUP-arm64v8
DYNUP-amd64
DYNUP-arm32v7
```

##### Latest releases, build-in DSMR Reader release
```
arm32v6
arm64v8
amd64
arm32v7
```

##### Version releases, build-in DSMR Reader release
```
arm32v6-<version>
arm64v8-<version
amd64-<version>
arm32v7-<version>
```

#### DSMR Reader - Environment variables
##### v4 changes
- Removed ``DSMR_EMAIL``
- Removed``SD_AUTOSTART_MQTT``
- Removed``SD_AUTORESTART_MQTT``
- Removed``DSMR_BACKEND_SLEEP``
- Removed``DSMR_DATALOGGER_SLEEP``
- Changed ``DSMRREADER_PLUGINS`` is now a comma separated list without quotes. E.g.: 
```
dsmr_plugins.modules.plugin_name1,dsmr_plugins.modules.plugin_name2
```

##### Currently supported
It's possible to set the following settings as environment variables, for example:
```
Required (defaults are shown as value):
- TZ=Europe/Amsterdam
- VIRTUAL_HOST=localhost
```

```
Optional (defaults are shown as value):

Nginx related (thanks @Caroga):
- ENABLE_HTTP_AUTH=false
- HTTP_AUTH_USERNAME=
- HTTP_AUTH_PASSWORD=

Supervisord related:
- SD_LOGLEVEL=info
- SD_USER=root
- SD_GROUP=root
- SD_AUTOSTART_DATALOGGER=true
- SD_AUTORESTART_DATALOGGER=true
- SD_AUTOSTART_BACKEND=true
- SD_AUTORESTART_BACKEND=true
- SD_AUTOSTART_CLIENT=true
- SD_AUTORESTART_CLIENT=true


DSMR related (defaults are shown as value):
- DSMR_USER=admin             # Webinterface user
- DSMR_PASSWORD=admin         # Webinterface user
- DSMRREADER_LOGLEVEL=WARNING # Valid values are WARNING, INFO, DEBUG
- DSMRREADER_PLUGINS=dsmr_plugins.modules.plugin_name1,dsmr_plugins.modules.plugin_name2
- SECRET_KEY=<some randomly generated value>

DB related (defaults are shown as value):
- DB_NAME=dsmrreader
- DB_USER=dsmrreader
- DB_PASS=dsmrreader
- DB_HOST=dsmrdb
- DB_PORT=5432
- CONN_MAX_AGE=60
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
dsmr-reader (https://github.com/dennissiemensma/dsmr-reader)

ualex73 created a fork, but that's based on an old setup. Docker image sizes have been reduced drastically (old 380mb, new 70mb), both for dsmr and dsmrdb.

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
  -e TZ=Europe/Amsterdam \
  -e DB_HOST=x.x.x.x \
  -e DB_USER=dsmrreader \
  -e DB_PASS=dsmrreader \
  -e VIRTUAL_HOST=localhost \
  --device /dev/ttyUSB0:/dev/ttyUSB0 \
  xirixiz/dsmr-reader-docker
```

# Backup and restore meganism 1
dsmrdb in docker-compose is configured to use a docker volume. So when the application and docker containter have been removed, the postgres data still persists.

Also you could easily create a backup. Values depend on docker/docker-compose user and database variables:
```
docker-compose stop dsmr
docker exec -t dsmrdb pg_dumpall -c -U dsmrreader > dsmrreader.sql
docker-compose start dsmr
```

Or drop the database and restore a backup. Values depend on docker/docker-compose user and database variables:
```
docker-compose stop dsmr
docker exec -t dsmrdb dropdb dsmrreader -U dsmrreader
docker exec -t dsmrdb createdb -O dsmrreader dsmrreader -U dsmrreader
cat dsmrreader.sql | docker exec -i dsmrdb psql -U dsmrreader
docker-compose start dsmr
```

# Backup and restore meganism 2
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

# Important notes
The current configuration has been tested on Ubuntu > 17.x and Manjaro > 17.x

For Synology users:
- Drivers are necessary: http://www.jadahl.com/drivers_6.1 or http://www.jadahl.com/drivers_6.2
- The docker-compose file must be set to version 3.2 or lower.

[buymecoffee]: https://www.buymeacoffee.com/xirixiz
[buymecoffeebadge]: https://camo.githubusercontent.com/cd005dca0ef55d7725912ec03a936d3a7c8de5b5/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f6275792532306d6525323061253230636f666665652d646f6e6174652d79656c6c6f772e737667
[dockerpulls]: https://hub.docker.com/r/xirixiz/dsmr-reader-docker/tags
[dockerpullsbadge]: https://img.shields.io/docker/pulls/xirixiz/dsmr-reader-docker

