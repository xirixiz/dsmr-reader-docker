# dsmr-reader-docker

A docker-compose file in order to start the following application in Docker:  
dsrm-reader (https://github.com/dennissiemensma/dsmr-reader)

Also it starts a postgres container for the application to store it's data.

After starting the containers with docker-compose, the dashboard is reachable at  
HTTP: http://\<hostname>:8888  

After starting the containers, don't forget to modify the default DSMR version (default is DSMR v4):  
http://\<hostname>:8888/admin/dsmr_datalogger/dataloggersettings/


dsrmdb in docker-compose is configured to use a docker volume. So when the application and docker containter have been removed, the postgres data still persists.

Also you could easily create a backup:  
docker exec -t dsmrdb pg_dumpall -c -U postgres > /tmp/dump_date +%d-%m-%Y"_"%H_%M_%S.sql

Or restore:  
cat /tmp/<your_dump>.sql | docker exec -i dsrmdb psql -U postgres

## DEVELOPMENT

Now there's also a development branch. It uses the development branch from https://github.com/dennissiemensma/dsmr-reader.
A compose_project_name has been specified and the docker-compose file has been modified to use different ports and volumes.  

HTTP: http://\<hostname>:8885
