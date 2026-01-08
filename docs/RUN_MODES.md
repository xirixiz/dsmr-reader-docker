# Run Modes

DSMR Reader Docker supports three operational modes to fit different deployment scenarios.

---

## Mode Comparison

| Mode | Smart Meter | Database | Web UI | Use Case |
|------|-------------|----------|--------|----------|
| **standalone** | ✅ Local | ✅ Yes | ✅ Yes | All-in-one setup |
| **server_remote_datalogger** | ❌ Remote | ✅ Yes | ✅ Yes | Central server |
| **remote_datalogger** | ✅ Local | ❌ Forwards | ❌ No | Remote sensor |

---

## Standalone Mode (Default)

**When to use:** Single location with smart meter directly connected.

Complete DSMR Reader installation with database and web interface.

### Configuration

```yaml
services:
  dsmrdb:
    image: postgres:17-alpine
    volumes:
      - dsmrdb_data:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: dsmrreader
      POSTGRES_PASSWORD: dsmrreader
      POSTGRES_DB: dsmrreader

  dsmr:
    image: xirixiz/dsmr-reader-docker:latest
    depends_on:
      - dsmrdb
    ports:
      - "80:80"
    devices:
      - /dev/ttyUSB0:/dev/ttyUSB0
    environment:
      CONTAINER_RUN_MODE: standalone
      DJANGO_DATABASE_HOST: dsmrdb
      DJANGO_DATABASE_NAME: dsmrreader
      DJANGO_DATABASE_USER: dsmrreader
      DJANGO_DATABASE_PASSWORD: dsmrreader
      DJANGO_TIME_ZONE: Europe/Amsterdam
      DJANGO_SECRET_KEY: your-secret-key
      DSMRREADER_ADMIN_USER: admin
      DSMRREADER_ADMIN_PASSWORD: admin
```

---

## Server Remote Datalogger Mode

**When to use:** Central server receiving data from multiple remote locations.

Runs database and web interface but receives telegrams via API from remote dataloggers.

### Server Configuration

```yaml
services:
  dsmrdb:
    image: postgres:17-alpine
    # ... same as standalone ...

  dsmr-server:
    image: xirixiz/dsmr-reader-docker:latest
    depends_on:
      - dsmrdb
    ports:
      - "80:80"
    environment:
      CONTAINER_RUN_MODE: server_remote_datalogger
      # ... database and application config ...
```

### Setup Steps

1. Start server container
2. Access web interface
3. Navigate to: Settings → API → Create API key
4. Copy API key for use in remote dataloggers
5. Configure remote dataloggers with server URL and API key

---

## Remote Datalogger Mode

**When to use:** Remote location with smart meter, forwarding to central server.

Reads smart meter locally and forwards telegrams to server. No database or web interface.

### Remote Configuration

```yaml
services:
  dsmr-remote:
    image: xirixiz/dsmr-reader-docker:latest
    devices:
      - /dev/ttyUSB0:/dev/ttyUSB0
    environment:
      CONTAINER_RUN_MODE: remote_datalogger

      # API configuration
      DSMRREADER_REMOTE_DATALOGGER_API_HOSTS: http://dsmr-server
      DSMRREADER_REMOTE_DATALOGGER_API_KEYS: your-api-key-from-server

      # Serial configuration
      DSMRREADER_REMOTE_DATALOGGER_INPUT_METHOD: serial
      DSMRREADER_REMOTE_DATALOGGER_SERIAL_DEVICE: /dev/ttyUSB0
      DSMRREADER_REMOTE_DATALOGGER_SERIAL_BAUDRATE: 115200
      DSMRREADER_REMOTE_DATALOGGER_SERIAL_BYTESIZE: 8
```

### Network Smart Meters

For network-connected smart meters:

```yaml
environment:
  CONTAINER_RUN_MODE: remote_datalogger
  DSMRREADER_REMOTE_DATALOGGER_API_HOSTS: http://dsmr-server
  DSMRREADER_REMOTE_DATALOGGER_API_KEYS: your-api-key
  DSMRREADER_REMOTE_DATALOGGER_INPUT_METHOD: ipv4
  DSMRREADER_REMOTE_DATALOGGER_NETWORK_HOST: 192.168.1.100
  DSMRREADER_REMOTE_DATALOGGER_NETWORK_PORT: 23
```

---

## Multi-Location Setup Example

### Scenario
- Main house: Server with database and web interface
- Garage: Remote datalogger with smart meter
- Vacation home: Remote datalogger with smart meter

### Architecture

```
[Garage Smart Meter] → [Remote Datalogger] ─┐
                                             │
                                             ├──→ [Server] → [Database] → [Web UI]
                                             │
[Vacation Smart Meter] → [Remote Datalogger]─┘
```

### Implementation

**Server (Main House):**
```yaml
# docker-compose.yaml at main house
services:
  dsmrdb:
    image: postgres:17-alpine
    volumes:
      - dsmrdb_data:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: dsmrreader
      POSTGRES_PASSWORD: dsmrreader
      POSTGRES_DB: dsmrreader

  dsmr-server:
    image: xirixiz/dsmr-reader-docker:latest
    depends_on:
      - dsmrdb
    ports:
      - "80:80"
    environment:
      CONTAINER_RUN_MODE: server_remote_datalogger
      DJANGO_DATABASE_HOST: dsmrdb
      DJANGO_DATABASE_NAME: dsmrreader
      DJANGO_DATABASE_USER: dsmrreader
      DJANGO_DATABASE_PASSWORD: dsmrreader
      DJANGO_TIME_ZONE: Europe/Amsterdam
      DJANGO_SECRET_KEY: your-secret-key
      DSMRREADER_ADMIN_USER: admin
      DSMRREADER_ADMIN_PASSWORD: admin
```

**Remote Datalogger (Garage):**
```yaml
# docker-compose.yaml at garage
services:
  dsmr-garage:
    image: xirixiz/dsmr-reader-docker:latest
    devices:
      - /dev/ttyUSB0:/dev/ttyUSB0
    environment:
      CONTAINER_RUN_MODE: remote_datalogger
      DSMRREADER_REMOTE_DATALOGGER_API_HOSTS: http://main-house:80
      DSMRREADER_REMOTE_DATALOGGER_API_KEYS: api-key-from-server
      DSMRREADER_REMOTE_DATALOGGER_INPUT_METHOD: serial
      DSMRREADER_REMOTE_DATALOGGER_SERIAL_DEVICE: /dev/ttyUSB0
      DSMRREADER_REMOTE_DATALOGGER_SERIAL_BAUDRATE: 115200
      DSMRREADER_REMOTE_DATALOGGER_SERIAL_BYTESIZE: 8
```

**Remote Datalogger (Vacation Home):**
```yaml
# docker-compose.yaml at vacation home
services:
  dsmr-vacation:
    image: xirixiz/dsmr-reader-docker:latest
    devices:
      - /dev/ttyUSB0:/dev/ttyUSB0
    environment:
      CONTAINER_RUN_MODE: remote_datalogger
      DSMRREADER_REMOTE_DATALOGGER_API_HOSTS: http://main-house:80
      DSMRREADER_REMOTE_DATALOGGER_API_KEYS: api-key-from-server
      DSMRREADER_REMOTE_DATALOGGER_INPUT_METHOD: serial
      DSMRREADER_REMOTE_DATALOGGER_SERIAL_DEVICE: /dev/ttyUSB0
      DSMRREADER_REMOTE_DATALOGGER_SERIAL_BAUDRATE: 115200
      DSMRREADER_REMOTE_DATALOGGER_SERIAL_BYTESIZE: 8
```

---

## Troubleshooting

### Remote Datalogger Can't Connect

**Check network connectivity:**
```bash
# From remote location
curl http://dsmr-server/healthcheck
```

**Check API key:**
- Verify API key in server web interface (Settings → API)
- Ensure API key matches in remote configuration

**Check logs:**
```bash
docker-compose logs dsmr-remote
```

### Server Not Receiving Data

**Verify API is enabled:**
- Access server web interface
- Settings → API → Verify API is enabled

**Check firewall:**
```bash
# On server
sudo ufw status
sudo ufw allow 80/tcp
```

**Check logs on server:**
```bash
docker-compose logs dsmr-server | grep -i api
```

---

## Need Help?

1. **Check this documentation** - Most answers are here
2. **Search issues** - [GitHub Issues](https://github.com/xirixiz/dsmr-reader-docker/issues)
3. **Ask community** - [GitHub Discussions](https://github.com/xirixiz/dsmr-reader-docker/discussions)
4. **Upstream docs** - [DSMR Reader Documentation](https://dsmr-reader.readthedocs.io/en/v6/)

---

**Maintained by [@xirixiz](https://github.com/xirixiz)**
