# dsmr-reader-docker
dsrm-reader (https://github.com/dennissiemensma/dsmr-reader) in Docker


HTTP: http://\<hostname>:8888

HTTPS: https://\<hostname>:8889


Vergeet niet de juiste meter te selecteren. DSMR versie 4 is default:
http://\<hostname>:8888/admin/dsmr_datalogger/dataloggersettings/

###

dsrmdb in docker-compose is configured to use a docker volume. So when the application and docker containter have been removed, the postgres data still persists.

Also you could easily create a backup :
docker exec -t dsmrdb pg_dumpall -c -U postgres > /tmp/dump_date +%d-%m-%Y"_"%H_%M_%S.sql

Or restore:
cat /tmp/<your_dump>.sql | docker exec -i dsrmdb psql -U postgres
