## HomeWizard P1 Meter Integration

DSMR Reader can integrate with HomeWizard P1 meters to read smart meter data over your network instead of using a direct serial connection.

### Quick Setup

1. **Enable HomeWizard Local API** in the HomeWizard app

2. **Create plugin file** `plugins/homewizard_p1.py`:

```python
import logging
import requests
from django.dispatch import receiver
from dsmr_backend.signals import backend_called
from dsmr_datalogger.services.datalogger import telegram_to_reading

HOMEWIZARD_ENDPOINT = 'http://1.2.3.4:80/api/v1/telegram'  # Replace with your IP
HOMEWIZARD_TIMEOUT = 5

logger = logging.getLogger(__name__)

@receiver(backend_called)
def handle_backend_called(**kwargs):
    try:
        response = requests.get(HOMEWIZARD_ENDPOINT, timeout=HOMEWIZARD_TIMEOUT)
        response.raise_for_status()
    except requests.exceptions.RequestException as e:
        logger.error(f'HomeWizard plugin: failed to retrieve telegram: {e}')
        return

    try:
        telegram_to_reading(data=response.text)
    except Exception as e:
        logger.exception(f'HomeWizard plugin: failed to process telegram: {e}')
```

3. **Update docker-compose.yaml**:

```yaml
services:
  dsmr:
    image: xirixiz/dsmr-reader-docker:latest
    volumes:
      - ./plugins/homewizard_p1.py:/app/dsmr_plugins/modules/homewizard_p1.py:ro
    environment:
      CONTAINER_RUN_MODE: server_remote_datalogger
      DSMRREADER_PLUGINS: dsmr_plugins.modules.homewizard_p1
      # ... other environment variables ...
```

4. **Restart containers**:

```bash
docker-compose down && docker-compose up -d
```

### Verification

Check plugin is loading:
```bash
docker-compose logs dsmr | grep -i homewizard
```

### Additional Documentation

For detailed setup instructions, troubleshooting, and Homey integration examples, see [HOMEY_INTEGRATION.md](HOMEY_INTEGRATION.md).

### References

- [Original GitHub Discussion](https://github.com/xirixiz/dsmr-reader-docker/issues/301)
- [Home Assistant Alternative](https://community.home-assistant.io/t/dsmr-reader-docker-and-homewizard-p1-meter-integration/747265)

## Need Help?

1. **Check this documentation** - Most answers are here
2. **Search issues** - [GitHub Issues](https://github.com/xirixiz/dsmr-reader-docker/issues)
3. **Ask community** - [GitHub Discussions](https://github.com/xirixiz/dsmr-reader-docker/discussions)
4. **Upstream docs** - [DSMR Reader Documentation](https://dsmr-reader.readthedocs.io/)

---

**Maintained by [@xirixiz](https://github.com/xirixiz)**
