#!/bin/sh
set -e

echo "⏳ Waiting for Redis and Postgres to be ready..."

# Wait for Redis
until nc -z 0.0.0.0 6379; do
  echo "❌ Redis not ready, retrying in 2s..."
  sleep 2
done
echo "✅ Redis is up!"

# Wait for Postgres
until nc -z 0.0.0.0 5432; do
  echo "❌ Postgres not ready, retrying in 2s..."
  sleep 2
done
echo "✅ Postgres is up!"

# Replace env vars in config
envsubst < /usr/share/nginx/html/web/config.js > /usr/share/nginx/html/web/config.js.tmp
mv /usr/share/nginx/html/web/config.js.tmp /usr/share/nginx/html/web/config.js

# Replace NEST_SERVER_PORT in nginx config
sed -i "s/\${NEST_SERVER_PORT}/$NEST_SERVER_PORT/g" /etc/nginx/conf.d/default.conf

# Run database migrations and seed
pnpm prisma migrate deploy || true
pnpm prisma db seed || true

# Start Node.js backend in background
node dist/main &

# Start nginx in foreground (PID 1)
exec nginx -g 'daemon off;'