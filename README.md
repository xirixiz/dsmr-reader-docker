#### DSMR Reader - Environment variables
Now it's possible to set the following settings as environment variables, for example:
```
Required (defaults are shown as value):
- TZ=Europe/Amsterdam
- DB_HOST=dsmrdb
- DB_USER=dsmrreader
- DB_PASS=dsmrreader
- DSMR_USER=admin
- DSMR_EMAIL=root@localhost
- DSMR_PASSWORD=admin
- VIRTUAL_HOST=localhost

Optional (defaults are shown as value):
Supervisord related:
- SD_LOGLEVEL=info
- SD_USER=root
- SD_GROUP=root
- SD_AUTOSTART_DATALOGGER=true
- SD_AUTORESTART_DATALOGGER=true
- SD_AUTOSTART_BACKEND=true
- SD_AUTORESTART_BACKEND=true
- SD_AUTOSTART_MQTT=false
- SD_AUTORESTART_MQTT=false

DSMR related:
- DB_PORT=5432
- DSMRREADER_BACKEND_SLEEP=60
- DSMRREADER_DATALOGGER_SLEEP=60
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

An example docker-compose.yaml file can be found here: https://raw.githubusercontent.com/xirixiz/dsmr-reader-docker/master/docker-compose.example.yaml

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
  -e DB_HOST=x.x.x.x \
  -e DSMR_USER=dsmrreader \
  -e DSMR_PASSWORD=dsmrreader \
  -e DSMR_EMAIL=root@localhost \
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
- Drivers are necessary: http://www.jadahl.com/drivers/
- The docker-compose file must be set to version 3.2 or lower.

