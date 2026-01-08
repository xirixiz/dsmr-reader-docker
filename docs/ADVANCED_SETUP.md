# Advanced Setup

Advanced configuration options for production deployments.

---

## SSL/TLS Configuration

Enable HTTPS for secure access to DSMR Reader.

### Generate Certificates

**Self-signed (testing only):**
```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout private.key -out certificate.crt \
  -subj "/CN=dsmr.local"
```

**Let's Encrypt (production):**
```bash
certbot certonly --standalone -d dsmr.example.com
```

### Configure Container

```yaml
services:
  dsmr:
    image: xirixiz/dsmr-reader-docker:latest
    ports:
      - "443:443"
      - "80:80"  # Optional HTTP redirect
    volumes:
      - ./certs/certificate.crt:/etc/nginx/ssl/certificate.crt:ro
      - ./certs/private.key:/etc/nginx/ssl/private.key:ro
    environment:
      CONTAINER_ENABLE_NGINX_SSL: "true"
```

---

## HTTP Basic Authentication

Protect the web interface with username/password.

### Create Password File

```bash
# Install htpasswd utility
apt-get install apache2-utils  # Debian/Ubuntu
yum install httpd-tools         # RHEL/CentOS

# Create password file
htpasswd -c htpasswd username
# Enter password when prompted
```

### Configure Container

```yaml
services:
  dsmr:
    image: xirixiz/dsmr-reader-docker:latest
    volumes:
      - ./htpasswd:/etc/nginx/.htpasswd:ro
    environment:
      CONTAINER_ENABLE_HTTP_AUTH: "true"
```

---

## Client Certificate Authentication

Mutual TLS authentication using client certificates.

### Certificate Setup

1. **Create CA certificate** (one-time)
2. **Create server certificate** (signed by CA)
3. **Create client certificates** (signed by CA, one per user)

### Configure Container

```yaml
services:
  dsmr:
    image: xirixiz/dsmr-reader-docker:latest
    volumes:
      - ./certs/ca.crt:/etc/nginx/ssl/ca.crt:ro
      - ./certs/server.crt:/etc/nginx/ssl/certificate.crt:ro
      - ./certs/server.key:/etc/nginx/ssl/private.key:ro
    environment:
      CONTAINER_ENABLE_NGINX_SSL: "true"
      CONTAINER_ENABLE_CLIENTCERT_AUTH: "true"
```

**Note:** Users must import their client certificate into their browser.

---

## Network Smart Meters

Read smart meters via TCP/IP instead of USB serial.

### Configuration

```yaml
environment:
  DSMRREADER_REMOTE_DATALOGGER_INPUT_METHOD: ipv4
  DSMRREADER_REMOTE_DATALOGGER_NETWORK_HOST: 192.168.1.100
  DSMRREADER_REMOTE_DATALOGGER_NETWORK_PORT: 23
```

### Common Devices

- **HomeWizard P1 meter** - See [HomeWizard Integration](HOMEY_INTEGRATION.md)
- **Network serial adapters** - Transparent serial-to-TCP bridges
- **Ser2net** - Linux serial port sharing

---

## Iframe Embedding

Allow embedding DSMR Reader in dashboards (Home Assistant, Grafana, etc).

```yaml
environment:
  CONTAINER_ENABLE_IFRAME: "true"
```

**Security note:** Only enable on trusted networks.

---

## Database Maintenance

### Automatic Vacuum on Startup

Enable database optimization on container startup:

```yaml
environment:
  CONTAINER_ENABLE_VACUUM_DB_AT_STARTUP: "true"
```

**Note:** Increases startup time but improves performance for large databases.

### Manual Vacuum

Run database vacuum manually:

```bash
docker exec dsmr /app/cleandb.sh
```

Verbose output:
```bash
docker exec dsmr /app/cleandb.sh -v
```

---

## Reverse Proxy Setup

### Nginx

```nginx
server {
    listen 443 ssl http2;
    server_name dsmr.example.com;

    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;

    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Traefik

```yaml
services:
  dsmr:
    image: xirixiz/dsmr-reader-docker:latest
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.dsmr.rule=Host(`dsmr.example.com`)"
      - "traefik.http.routers.dsmr.entrypoints=websecure"
      - "traefik.http.routers.dsmr.tls.certresolver=letsencrypt"
```

---

## Debug Mode

Enable verbose container initialization logging:

```yaml
environment:
  CONTAINER_ENABLE_DEBUG: "true"
```

**For DSMR Reader application debug**, see [DSMR Reader documentation](https://dsmr-reader.readthedocs.io/en/v6/env_settings.html).

---

## Custom Plugins

Load custom DSMR Reader plugins:

```yaml
volumes:
  - ./plugins/my_plugin.py:/app/dsmr_plugins/modules/my_plugin.py:ro
environment:
  DSMRREADER_PLUGINS: dsmr_plugins.modules.my_plugin
```

Multiple plugins:
```yaml
environment:
  DSMRREADER_PLUGINS: dsmr_plugins.modules.plugin1,dsmr_plugins.modules.plugin2
```

See [DSMR Reader Plugin Documentation](https://dsmr-reader.readthedocs.io/en/latest/plugins.html) for plugin development.

---

## Backup Strategy

### Database Backups

**Method 1 - pg_dump via dsmr container:**
```bash
docker exec dsmr sh -c 'PGPASSWORD=$DJANGO_DATABASE_PASSWORD \
  pg_dump -h $DJANGO_DATABASE_HOST -U $DJANGO_DATABASE_USER \
  $DJANGO_DATABASE_NAME' > backup.sql
```

**Method 2 - pg_dump via dsmrdb container:**
```bash
docker exec dsmrdb pg_dump -U dsmrreader dsmrreader > backup.sql
```

**Method 3 - Docker volume backup:**
```bash
docker run --rm \
  -v dsmrdb_data:/volume \
  -v $(pwd):/backup \
  alpine tar czf /backup/dsmrdb.tar.gz -C /volume ./
```

### Automated Backups

Create cron job:
```bash
# /etc/cron.daily/dsmr-backup
#!/bin/bash
BACKUP_DIR=/backups/dsmr
DATE=$(date +%Y%m%d_%H%M%S)
docker exec dsmrdb pg_dump -U dsmrreader dsmrreader > ${BACKUP_DIR}/dsmr_${DATE}.sql
find ${BACKUP_DIR} -name "dsmr_*.sql" -mtime +7 -delete
```

### Restore

```bash
# Stop container
docker-compose stop dsmr

# Restore database
cat backup.sql | docker exec -i dsmrdb psql -U dsmrreader -d dsmrreader

# Start container
docker-compose start dsmr
```

---

## Need Help?

1. **Check this documentation** - Most answers are here
2. **Search issues** - [GitHub Issues](https://github.com/xirixiz/dsmr-reader-docker/issues)
3. **Ask community** - [GitHub Discussions](https://github.com/xirixiz/dsmr-reader-docker/discussions)
4. **Upstream docs** - [DSMR Reader Documentation](https://dsmr-reader.readthedocs.io/)

---

**Maintained by [@xirixiz](https://github.com/xirixiz)**