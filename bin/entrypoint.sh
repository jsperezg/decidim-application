#!/bin/bash
# https://stackoverflow.com/a/38732187/1935918
set -e

function initialize_database {
  bundle exec rails db:create && bundle exec rails db:migrate
}

if [ -f /app/tmp/pids/server.pid ]; then
  rm /app/tmp/pids/server.pid
fi

bundle exec rails db:migrate 2>/dev/null || initialize_database

exec "$@"
