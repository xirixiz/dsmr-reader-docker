# Troubleshooting

Common issues and solutions for DSMR Reader Docker.

---

## Quick Diagnostics

```bash
# Check container status
docker-compose ps

# View container logs
docker-compose logs dsmr
docker-compose logs dsmrdb

# Check s6-overlay services
docker exec dsmr s6-rc -a list

# Test database connection
docker exec dsmr python manage.py check --database default
```

---

## Container Won't Start

### Check Logs

```bash
docker-compose logs dsmr
```

### Enable Debug Mode

```yaml
environment:
  CONTAINER_ENABLE_DEBUG: "true"
```

### Check Service Status

```bash
docker exec dsmr s6-rc -a list
```

### Common Causes

1. **Database not ready** - Container starts before database is ready
   - Solution: Add `depends_on` in docker-compose

2. **Missing environment variables** - Required variables not set
   - Solution: Check [Configuration Reference](CONFIGURATION.md)

3. **Port conflict** - Port 80 already in use
   - Solution: Change port mapping (`"8080:80"`)

---

## Database Connection Issues

### Symptoms

- Container starts but web interface shows errors
- "Connection refused" in logs
- "FATAL: database does not exist"

### Solutions

**Check database is running:**
```bash
docker-compose ps dsmrdb
docker-compose logs dsmrdb
```

**Verify credentials match:**
```bash
# In docker-compose.yaml, ensure these match:
# - POSTGRES_USER / DJANGO_DATABASE_USER
# - POSTGRES_PASSWORD / DJANGO_DATABASE_PASSWORD
# - POSTGRES_DB / DJANGO_DATABASE_NAME
```

**Test connection from container:**
```bash
docker exec dsmr psql -h $DJANGO_DATABASE_HOST \
  -U $DJANGO_DATABASE_USER -d $DJANGO_DATABASE_NAME
```

**Check database host:**
```yaml
# For docker-compose on same host, use service name:
DJANGO_DATABASE_HOST: dsmrdb

# NOT localhost or 127.0.0.1
```

---

## Web Interface Not Accessible

### Check nginx is Running

```bash
docker exec dsmr ps aux | grep nginx
```

### Check Port Mapping

```bash
docker-compose ps
# Verify port mapping shows: 0.0.0.0:80->80/tcp
```

### Enable nginx Access Logs

```yaml
environment:
  CONTAINER_ENABLE_NGINX_ACCESS_LOGS: "true"
```

Then check:
```bash
docker exec dsmr tail -f /var/log/nginx/access.log
docker exec dsmr tail -f /var/log/nginx/error.log
```

### Test nginx Configuration

```bash
docker exec dsmr nginx -t
```

---

## Serial Device Not Accessible

### Check Device Exists

```bash
ls -l /dev/ttyUSB0
```

### Check Permissions

```bash
# Should show: crw-rw---- 1 root dialout
ls -l /dev/ttyUSB0

# Fix permissions (temporary):
sudo chmod 666 /dev/ttyUSB0
```

### Add User to dialout Group

```bash
sudo usermod -aG dialout $USER
# Log out and back in
```

### Verify Device is Passed to Container

```yaml
devices:
  - /dev/ttyUSB0:/dev/ttyUSB0
```

### Check Inside Container

```bash
docker exec dsmr ls -l /dev/ttyUSB0
```

---

## Timestamp Issues

### Timestamps Off by One Hour

**❌ WRONG - Do NOT do this:**
```yaml
volumes:
  - /etc/localtime:/etc/localtime:ro
```

This causes timezone conflicts with PostgreSQL.

**✅ CORRECT - Use environment variable:**
```yaml
environment:
  DJANGO_TIME_ZONE: Europe/Amsterdam
```

### Verify Timezone

```bash
# Check container timezone
docker exec dsmr date

# Check database timezone
docker exec dsmrdb psql -U dsmrreader -d dsmrreader -c "SHOW TIME ZONE;"
```

---

## Data Not Showing / No Readings

### Check Datalogger is Running

```bash
docker exec dsmr ps aux | grep datalogger
```

### Check Datalogger Logs

```bash
docker-compose logs dsmr | grep -i datalogger
docker-compose logs dsmr | grep -i telegram
```

### Verify Smart Meter Configuration

Access web interface → Configuration → Datalogger settings

Common settings:
- **DSMR version** - Set to your meter version (4.x or 5.x)
- **Serial port** - `/dev/ttyUSB0`
- **Baud rate** - 115200 (DSMR 4/5) or 9600 (DSMR 2/3)

### Test Serial Connection Manually

```bash
# Inside container
docker exec -it dsmr bash

# Read raw data from serial port
cat /dev/ttyUSB0
# Should show telegram data every 10 seconds
# Press Ctrl+C to stop
```

---

## Performance Issues

### Slow Web Interface

**Check database size:**
```bash
docker exec dsmrdb psql -U dsmrreader -d dsmrreader \
  -c "SELECT pg_size_pretty(pg_database_size('dsmrreader'));"
```

**Enable vacuum on startup:**
```yaml
environment:
  CONTAINER_ENABLE_VACUUM_DB_AT_STARTUP: "true"
```

**Or run vacuum manually:**
```bash
docker exec dsmr /app/cleandb.sh -v
```

### High CPU Usage

**Check for stuck processes:**
```bash
docker exec dsmr ps aux
```

**Check container resource limits:**
```bash
docker stats dsmr dsmrdb
```

---

## SSL Certificate Errors

### Verify Certificates are Mounted

```bash
docker exec dsmr ls -la /etc/nginx/ssl/
```

Should show:
- `/etc/nginx/ssl/certificate.crt`
- `/etc/nginx/ssl/private.key`

### Test nginx Configuration

```bash
docker exec dsmr nginx -t
```

### Check Certificate Validity

```bash
docker exec dsmr openssl x509 -in /etc/nginx/ssl/certificate.crt -text -noout
```

---

## Remote Datalogger Issues

### Can't Connect to Server

**Test network connectivity:**
```bash
# From remote location
curl http://dsmr-server/about
```

**Check API key:**
```bash
# View configured API hosts/keys
docker exec dsmr-remote env | grep API
```

**Check server logs:**
```bash
# On server
docker-compose logs dsmr-server | grep -i api
```

### Data Not Appearing on Server

**Verify API is enabled on server:**
- Access server web interface
- Settings → API → Verify enabled

**Check firewall:**
```bash
# On server
sudo ufw status
sudo ufw allow 80/tcp
```

---

## Container Upgrade Issues

### After Upgrade, Container Won't Start

**Check breaking changes:**
- Review [CHANGELOG](../CHANGELOG)
- Check [GitHub releases](https://github.com/xirixiz/dsmr-reader-docker/releases)

**Check database compatibility:**
```bash
# View database version
docker exec dsmrdb psql -V
```

**Restore from backup if needed** - See [Advanced Setup](ADVANCED_SETUP.md#backup-strategy)

---

## Platform-Specific Issues

### Raspberry Pi

**libseccomp2 version too old:**

```bash
# Add backports repository
sudo apt-key adv --keyserver keyserver.ubuntu.com \
  --recv-keys 04EE7237B7D453EC 648ACFD622F3D138

echo 'deb http://httpredir.debian.org/debian buster-backports main contrib non-free' | \
  sudo tee -a /etc/apt/sources.list.d/debian-backports.list

# Update and install
sudo apt update
sudo apt install libseccomp2 -t buster-backports
```

### Synology NAS

**USB serial not accessible:**

Install `synokernel-usbserial` from Synology Community Package Center.

**Set device permissions:**
```bash
sudo chmod 666 /dev/ttyUSB0
```

### WSL2

**USB devices not accessible:**

WSL2 doesn't have native USB support. Options:
1. Use USB/IP forwarding
2. Run on Windows Docker Desktop
3. Use network smart meter instead

---

## Getting More Help

### Enable Debug Logging

```yaml
environment:
  CONTAINER_ENABLE_DEBUG: "true"
```

### Collect Diagnostic Information

```bash
# Container info
docker-compose ps
docker-compose logs dsmr > dsmr-logs.txt
docker-compose logs dsmrdb > db-logs.txt

# System info
docker version
docker-compose version
uname -a

# Configuration (remove sensitive data before sharing!)
docker-compose config > config.yaml
```

### Where to Ask for Help

1. **Check documentation** - [docs/](.)
2. **Search issues** - [GitHub Issues](https://github.com/xirixiz/dsmr-reader-docker/issues)
3. **Ask community** - [GitHub Discussions](https://github.com/xirixiz/dsmr-reader-docker/discussions)
4. **Upstream docs** - [DSMR Reader Documentation](https://dsmr-reader.readthedocs.io/en/v6/)

---

## See Also

- [Configuration Reference](CONFIGURATION.md) - All environment variables
- [Advanced Setup](ADVANCED_SETUP.md) - SSL, backups, maintenance
- [Run Modes](RUN_MODES.md) - Different operational modes
