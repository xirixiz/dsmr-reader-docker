# Configuration Reference

`Complete reference for all environment variables supported by DSMR Reader Docker.

---

## Container Configuration

Container-specific settings that control Docker container behavior.

| Variable                                      | Default      | Description                                                               |
|-----------------------------------------------|--------------|---------------------------------------------------------------------------|
| `CONTAINER_RUN_MODE`                          | `standalone` | Modes: `standalone`, `server_remote_datalogger`,`remote_datalogger`       |
| `CONTAINER_ENABLE_DEBUG`                      | `false`      | Enable verbose debug output in container initialization                   |
| `CONTAINER_ENABLE_NGINX_ACCESS_LOGS`          | `false`      | Enable nginx access logs (increases disk I/O)                             |
| `CONTAINER_ENABLE_NGINX_SSL`                  | `false`      | Enable SSL/TLS in nginx (requires certificates)                           |
| `CONTAINER_ENABLE_HTTP_AUTH`                  | `false`      | Enable HTTP basic authentication                                          |
| `CONTAINER_ENABLE_CLIENTCERT_AUTH`            | `false`      | Enable client certificate authentication                                  |
| `CONTAINER_ENABLE_IFRAME`                     | `false`      | Allow embedding in iframes                                                |
| `CONTAINER_ENABLE_VACUUM_DB_AT_STARTUP`       | `false`      | Run database vacuum on startup                                            |

**Note:** For DSMR Reader application debug mode, see [DSMR Reader docs](https://dsmr-reader.readthedocs.io/en/v6/env_settings.html).

---

## Database Configuration

PostgreSQL connection settings (all required).

| Variable                                      | Default      | Description                                                               |
|-----------------------------------------------|--------------|---------------------------------------------------------------------------|
| `DJANGO_DATABASE_HOST`                        | -            | PostgreSQL hostname                                                       |
| `DJANGO_DATABASE_PORT`                        | `5432`       | PostgreSQL port                                                           |
| `DJANGO_DATABASE_NAME`                        | -            | Database name                                                             |
| `DJANGO_DATABASE_USER`                        | -            | Database username                                                         |
| `DJANGO_DATABASE_PASSWORD                `    | -            | Database password                                                         |

---

## Application Configuration

Core DSMR Reader settings (all required).

| Variable                                      | Default      | Description                                                               |
|-----------------------------------------------|--------------|---------------------------------------------------------------------------|
| `DJANGO_TIME_ZONE`                            | -            | Timezone (e.g., `Europe/Amsterdam`)                                       |
| `DJANGO_SECRET_KEY`                           | -            | Django secret key (generate secure random string)                         |
| `DSMRREADER_ADMIN_USER`                       | -            | Admin username                                                            |
| `DSMRREADER_ADMIN_PASSWORD`                   | -            | Admin password                                                            |

---

## Remote Datalogger Configuration

Required only when `CONTAINER_RUN_MODE=remote_datalogger`.

### API Settings

| Variable                                      | Default      | Description                                                               |
|-----------------------------------------------|--------------|---------------------------------------------------------------------------|
| `DSMRREADER_REMOTE_DATALOGGER_API_HOSTS`      | Yes          | Comma-separated server URLs                                               |
| `DSMRREADER_REMOTE_DATALOGGER_API_KEYS`       | Yes          | Comma-separated API keys                                                  |

### Input Method

| Variable                                      | Default      | Description                                                               |
|-----------------------------------------------|--------------|---------------------------------------------------------------------------|
| `DSMRREADER_REMOTE_DATALOGGER_INPUT_METHOD`   | `serial`     | Input method: `serial` or `ipv4`                                          |

### Serial Configuration

For `DSMRREADER_REMOTE_DATALOGGER_INPUT_METHOD=serial`:

| Variable                                      | Default      | Description                                                               |
|-----------------------------------------------|--------------|---------------------------------------------------------------------------|
| `DSMRREADER_REMOTE_DATALOGGER_SERIAL_DEVICE`  | Yes          | Device path (e.g., `/dev/ttyUSB0`)                                        |
| `DSMRREADER_REMOTE_DATALOGGER_SERIAL_BAUDRATE`| Yes          | Baud rate (e.g., `115200`)                                                |
| `DSMRREADER_REMOTE_DATALOGGER_SERIAL_BYTESIZE`| Yes          | Byte size (typically `8`)                                                 |

### Network Configuration

For `DSMRREADER_REMOTE_DATALOGGER_INPUT_METHOD=ipv4`:

| Variable                                      | Default      | Description                                                               |
|---------------------------------------------- |--------------|---------------------------------------------------------------------------|
| `DSMRREADER_REMOTE_DATALOGGER_NETWORK_HOST`   | Yes          | Smart meter IP or hostname                                                |
| `DSMRREADER_REMOTE_DATALOGGER_NETWORK_PORT`   | Yes          | Smart meter TCP port                                                      |

---

## Additional DSMR Reader Settings

DSMR Reader supports many additional environment variables. See the [upstream documentation](https://dsmr-reader.readthedocs.io/en/v6/env_settings.html) for the complete list.

Common examples:

| Variable                                      | Default      | Description                                                               |
|-----------------------------------------------|--------------|---------------------------------------------------------------------------|
| `DSMRREADER_LOGLEVEL`                         | -            | Logging level (DEBUG, INFO, WARNING, ERROR)                               |
| `DSMRREADER_PLUGINS`                          | -            | Comma-separated plugin modules                                            |
| `DSMRREADER_SUPPRESS_STORAGE_SIZE_WARNINGS`   | -            | Suppress disk space warnings                                              |

---

## Configuration Examples

### Minimal Standalone

```yaml
environment:
  DJANGO_DATABASE_HOST: dsmrdb
  DJANGO_DATABASE_NAME: dsmrreader
  DJANGO_DATABASE_USER: dsmrreader
  DJANGO_DATABASE_PASSWORD: dsmrreader
  DJANGO_TIME_ZONE: Europe/Amsterdam
  DJANGO_SECRET_KEY: your-secret-here
  DSMRREADER_ADMIN_USER: admin
  DSMRREADER_ADMIN_PASSWORD: admin
```

### With SSL and Debug

```yaml
environment:
  # ... basic config ...
  CONTAINER_ENABLE_DEBUG: "true"
  CONTAINER_ENABLE_NGINX_SSL: "true"
volumes:
  - ./certs:/etc/nginx/ssl:ro
```

### Remote Datalogger

```yaml
environment:
  CONTAINER_RUN_MODE: remote_datalogger
  DSMRREADER_REMOTE_DATALOGGER_API_HOSTS: http://dsmr-server
  DSMRREADER_REMOTE_DATALOGGER_API_KEYS: your-api-key
  DSMRREADER_REMOTE_DATALOGGER_INPUT_METHOD: serial
  DSMRREADER_REMOTE_DATALOGGER_SERIAL_DEVICE: /dev/ttyUSB0
  DSMRREADER_REMOTE_DATALOGGER_SERIAL_BAUDRATE: 115200
  DSMRREADER_REMOTE_DATALOGGER_SERIAL_BYTESIZE: 8
```

---

## See Also

- [Run Modes](RUN_MODES.md) - Detailed explanation of different run modes
- [Advanced Setup](ADVANCED_SETUP.md) - SSL, authentication, and more
- [DSMR Reader Docs](https://dsmr-reader.readthedocs.io/en/v6/) - Upstream documentation
