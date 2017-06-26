# dsmr-reader-docker

A docker-compose file in order to start the following application in Docker:  
dsmr-reader (https://github.com/dennissiemensma/dsmr-reader)

Also it starts a postgres container for the application to store it's data.

You should first add the user you run Docker with on your host file system to the dialout group:
sudo usermod -aG dialout $(whoami)

After starting the containers with docker-compose, the dashboard is reachable at  
HTTP: http://\<hostname>:8888  

After starting the containers, don't forget to modify the default DSMR version (default is DSMR v4):  
http://\<hostname>:8888/admin/dsmr_datalogger/dataloggersettings/

---

dsmrdb in docker-compose is configured to use a docker volume. So when the application and docker containter have been removed, the postgres data still persists.

Also you could easily create a backup:  
docker exec -t dsmrdb pg_dumpall -c -U postgres > /tmp/dump_date +%d-%m-%Y"_"%H_%M_%S.sql

Or restore:  
cat /tmp/<your_dump>.sql | docker exec -i dsmrdb psql -U postgres

---
The current configuration has been tested on Ubuntu 17.04 and Manjaro 17.0.2

For Synology users:
- Drivers are necessary: http://jadahl.dscloud.me/drivers.html
- The docker-compose file must be set to version 2 instead of 3.

## DEVELOPMENT

Now there's also a development branch. It uses the development branch from https://github.com/dennissiemensma/dsmr-reader/tree/development.  
A compose_project_name has been specified and the docker-compose file has been modified to use different ports and volumes.  

HTTP: http://\<hostname>:8885
