# dsmr-reader-docker

A docker-compose file in order to start the following application in Docker:  
dsmr-reader (https://github.com/dennissiemensma/dsmr-reader)

Also it starts a postgres container for the application to store it's data.

You should first add the user you run Docker with on your host file system to the dialout group:
sudo usermod -aG dialout $(whoami)

After starting the containers with docker-compose, the dashboard is reachable at  
HTTP: http://\<hostname>:7777  

After starting the containers, don't forget to modify the default DSMR version (default is DSMR v4):  
http://\<hostname>:7777/admin/dsmr_datalogger/dataloggersettings/

---

dsmrdb in docker-compose is configured to use a docker volume. So when the application and docker containter have been removed, the postgres data still persists.

Also you could easily create a backup:  
- docker-compose stop dsmr
- docker exec -t dsmrdb pg_dumpall -c -U postgres > /tmp/dump_`date +%d-%m-%Y""%H%M%S`.sql
- docker-compose start dsmr


Or drop the database and restore a backup:
- docker-compose stop dsmr
- docker exec -t dsmrdb dropdb dsmrreader -U postgres
- docker exec -t dsmrdb createdb -O dsmrreader dsmrreader -U postgres
- cat /tmp/<your_dump>.sql | docker exec -i dsmrdb psql -U postgres
- docker-compose start dsmr

---

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

---

The current configuration has been tested on Ubuntu > 17.x and Manjaro > 17.x

For Synology users:
- Drivers are necessary: http://jadahl.dscloud.me/drivers.html
- The docker-compose file must be set to version 2 instead of 3.

