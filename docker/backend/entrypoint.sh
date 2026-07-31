#!/bin/bash
# DEBUG SCAFFOLD: on any failure, keep the container alive (instead of
# exiting) so `docker logs` / Coolify's Logs tab can show what broke,
# rather than the container being crash-looped and torn down before
# anyone can inspect it. Revert to a plain `set -e` script once the
# underlying issue is fixed.
set +e

fail() {
    echo "=== ENTRYPOINT FAILED: $1 (exit code $2) ==="
    echo "=== Sleeping so the container stays up for inspection ==="
    exec sleep infinity
}

echo "Waiting for PostgreSQL..."
retries=0
max_retries=30
while ! python -c "
import socket, os
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((os.environ['DBHOST'], int(os.environ['DBPORT'])))
s.close()
" 2>/dev/null; do
    retries=$((retries + 1))
    if [ "$retries" -ge "$max_retries" ]; then
        fail "waiting for postgres" 1
    fi
    echo "  PostgreSQL not ready yet (attempt $retries/$max_retries)..."
    sleep 1
done
echo "PostgreSQL is ready."

echo "Running migrations..."
python manage.py migrate --noinput
rc=$?
[ $rc -ne 0 ] && fail "migrate" $rc

echo "Creating default admin user (if needed)..."
python manage.py create_default_admin
rc=$?
[ $rc -ne 0 ] && fail "create_default_admin" $rc

echo "Collecting static files..."
python manage.py collectstatic --noinput
rc=$?
[ $rc -ne 0 ] && fail "collectstatic" $rc

echo "Starting development server..."
exec python manage.py runserver 0.0.0.0:8000
