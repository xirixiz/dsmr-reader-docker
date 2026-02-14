#!/bin/bash
# DSMR Reader - CPU Usage Troubleshooting Script
# This script helps diagnose high CPU usage in your DSMR Reader container

set -euo pipefail

CONTAINER_NAME="dsmr"  # Change this to your container name/ID

echo "=========================================="
echo "DSMR Reader CPU Troubleshooting"
echo "=========================================="
echo ""

# Check which processes are consuming CPU inside the container
echo "1️⃣  Top processes inside container:"
echo "=========================================="
docker exec "${CONTAINER_NAME}" ps aux --sort=-%cpu | head -n 10
echo ""

# Check all running DSMR processes
echo "2️⃣  All DSMR Reader processes:"
echo "=========================================="
docker exec "${CONTAINER_NAME}" ps aux | grep -E 'dsmr|python|nginx|postgres' | grep -v grep
echo ""

# Check if datalogger is running and consuming resources
echo "3️⃣  Datalogger process status:"
echo "=========================================="
docker exec "${CONTAINER_NAME}" ps aux | grep -E 'dsmr_datalogger|dsmr_backend' | grep -v grep || echo "No datalogger processes found"
echo ""

# Check container logs for errors or warnings
echo "4️⃣  Recent container logs (last 50 lines):"
echo "=========================================="
docker logs --tail 50 "${CONTAINER_NAME}" 2>&1
echo ""

# Check database connections
echo "6️⃣  Database connection count:"
echo "=========================================="
docker exec "${CONTAINER_NAME}" sh -c 'if command -v psql >/dev/null 2>&1; then
    PGPASSWORD="${DJANGO_DATABASE_PASSWORD}" psql -h "${DJANGO_DATABASE_HOST}" -U "${DJANGO_DATABASE_USER}" -d "${DJANGO_DATABASE_NAME}" -c "SELECT count(*) as connections FROM pg_stat_activity;" 2>/dev/null || echo "Cannot connect to database"
else
    echo "psql not available in container"
fi'
echo ""

# Check for Python processes stuck in loops
echo "7️⃣  Python process details:"
echo "=========================================="
docker exec "${CONTAINER_NAME}" sh -c 'for pid in $(pgrep python); do
    echo "PID: $pid"
    ps -p $pid -o pid,ppid,%cpu,%mem,cmd
    echo "---"
done'
echo ""

# Check NGINX status
echo "8️⃣  NGINX status:"
echo "=========================================="
docker exec "${CONTAINER_NAME}" sh -c 'if pgrep nginx >/dev/null; then
    echo "NGINX is running"
    ps aux | grep nginx | grep -v grep
else
    echo "NGINX is not running"
fi'
echo ""

# Check for configuration issues
echo "9️⃣  Environment configuration:"
echo "=========================================="
docker exec "${CONTAINER_NAME}" sh -c 'cat /app/.env 2>/dev/null || echo "No .env file found"'
echo ""

# Live monitoring of CPU usage
echo "🔟  Live CPU usage (5 second sample):"
echo "=========================================="
echo "Sampling CPU usage for 5 seconds..."
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" "${CONTAINER_NAME}"
sleep 5
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" "${CONTAINER_NAME}"
echo ""

# Check for stuck serial connections (common issue)
echo "1️⃣1️⃣  Serial port status:"
echo "=========================================="
docker exec "${CONTAINER_NAME}" sh -c 'if [ -c "/dev/ttyUSB0" ] || [ -c "/dev/ttyAMA0" ]; then
    lsof /dev/tty* 2>/dev/null || echo "lsof not available"
    ls -la /dev/tty* 2>/dev/null || echo "No serial devices found"
else
    echo "No serial devices detected"
fi'
echo ""

# Check datalogger mode
echo "1️⃣2️⃣  DSMR Reader operation mode:"
echo "=========================================="
docker exec "${CONTAINER_NAME}" sh -c 'echo "CONTAINER_RUN_MODE: ${CONTAINER_RUN_MODE:-not set}"
echo "DSMRREADER_REMOTE_DATALOGGER_INPUT_METHOD: ${DSMRREADER_REMOTE_DATALOGGER_INPUT_METHOD:-not set}"'
echo ""

echo "=========================================="
echo "📊 Diagnostic Summary"
echo "=========================================="
echo ""
echo "Common causes of high CPU in DSMR Reader:"
echo ""
echo "1. Datalogger reading too frequently"
echo "   → Check DSMRREADER_REMOTE_DATALOGGER_SLEEP setting"
echo ""
echo "2. Serial port connection issues"
echo "   → Check if serial device is accessible and baudrate is correct"
echo ""
echo "3. Database queries running continuously"
echo "   → Check if database is responding properly"
echo ""
echo "4. Stuck Python processes"
echo "   → Look for processes with high %CPU in the output above"
echo ""
echo "5. NGINX access logging on busy system"
echo "   → Consider setting CONTAINER_ENABLE_NGINX_ACCESS_LOGS=false"
echo ""
echo "=========================================="
echo "🔧 Recommended Actions"
echo "=========================================="
echo ""
echo "To reduce CPU usage, try these settings:"
echo ""
echo "Environment variables to add/modify:"
echo "  DSMRREADER_REMOTE_DATALOGGER_SLEEP=60        # Slow down readings (default: 1)"
echo "  DSMRREADER_REMOTE_DATALOGGER_TIMEOUT=10      # Shorter timeout"
echo "  CONTAINER_ENABLE_NGINX_ACCESS_LOGS=false     # Disable NGINX logging"
echo "  DSMRREADER_LOGLEVEL=WARNING                  # Reduce log verbosity"
echo ""
echo "If using serial connection:"
echo "  - Verify correct baudrate (usually 115200)"
echo "  - Check serial port permissions"
echo "  - Ensure no other process is accessing the port"
echo ""
echo "To restart the container with new settings:"
echo "  docker restart ${CONTAINER_NAME}"
echo ""
echo "To view live process monitoring:"
echo "  docker exec -it ${CONTAINER_NAME} top"
echo ""