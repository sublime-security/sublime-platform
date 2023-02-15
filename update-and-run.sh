#!/bin/sh
set -e

. ./utils.sh

cmd_prefix="sudo "

# Docker setups on OS X generally won't need sudo
# TODO this check is pretty naive -- a properly setup docker/compose setup in Linux won't need sudo either
case "$(uname -s | tr '[:upper:]' '[:lower:]')" in
linux*) cmd_prefix="sudo " ;;
darwin*) cmd_prefix="" ;;
esac

if [ "$1" != "always_launch" ]; then
    if ! $cmd_prefix docker compose ps | grep "mantis" >/dev/null 2>&1; then
        print_error "docker compose appears to be brought down. Will not proceed to avoid relaunching."
        exit 0
    fi
fi

if [ -z "$(git status --porcelain)" ]; then
    echo "git working dir clean. Proceeding with git updates."

    old_ref=$(git rev-parse HEAD)
    git pull
    new_ref=$(git rev-parse HEAD)

    if [ "${old_ref}" != "${new_ref}" ]; then
        $cmd_prefix docker compose down --remove-orphans
    fi
else
    print_warning "Uncommitted changes present, ignoring updates to sublime-platform git repo"
fi

if [ -z "$sublime_host" ]; then
    sublime_host="http://localhost"
fi

SUBLIME_ENV_FILE=sublime.env

if ! grep "POSTGRES_PASSWORD" $SUBLIME_ENV_FILE >/dev/null 2>&1; then
    POSTGRES_PASSWORD=$(openssl rand -hex 24)
    echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD" >>$SUBLIME_ENV_FILE
    echo "Configured Postgres password"
fi

if ! grep "JWT_SECRET" $SUBLIME_ENV_FILE >/dev/null 2>&1; then
    JWT_SECRET=$(openssl rand -hex 24)
    echo "JWT_SECRET=$JWT_SECRET" >>$SUBLIME_ENV_FILE
    echo "Configured JWT secret"
fi

if ! grep "POSTGRES_ENCRYPTION_KEY" $SUBLIME_ENV_FILE >/dev/null 2>&1; then
    # Note: key length must be 16, 24, or 32 bytes
    POSTGRES_ENCRYPTION_KEY=$(openssl rand -hex 32)
    echo "POSTGRES_ENCRYPTION_KEY=$POSTGRES_ENCRYPTION_KEY" >>$SUBLIME_ENV_FILE
    echo "Configured Postgres encryption key"
fi

if ! grep "AWS_ACCESS_KEY_ID" $SUBLIME_ENV_FILE >/dev/null 2>&1; then
    # Note: key length must be 16, 24, or 32 bytes
    FAKE_AWS_ACCESS_KEY_ID=$(openssl rand -hex 32)
    echo "AWS_ACCESS_KEY_ID=fake_$FAKE_AWS_ACCESS_KEY_ID" >>$SUBLIME_ENV_FILE
    echo "Configured AWS access key ID"
fi

if ! grep "AWS_SECRET_ACCESS_KEY" $SUBLIME_ENV_FILE >/dev/null 2>&1; then
    # Note: key length must be 16, 24, or 32 bytes
    FAKE_AWS_SECRET_ACCESS_KEY=$(openssl rand -hex 32)
    echo "AWS_SECRET_ACCESS_KEY=fake_$FAKE_AWS_SECRET_ACCESS_KEY" >>$SUBLIME_ENV_FILE
    echo "Configured AWS secret access key"
fi

if ! grep "CORS_ALLOW_ORIGINS" $SUBLIME_ENV_FILE >/dev/null 2>&1; then
    echo "CORS_ALLOW_ORIGINS=$sublime_host:3000" >>$SUBLIME_ENV_FILE
    echo "Configured CORS allow origins"
fi

if ! grep "BASE_URL" $SUBLIME_ENV_FILE >/dev/null 2>&1; then
    echo "BASE_URL=$sublime_host:8000" >>$SUBLIME_ENV_FILE
    echo "Configured base URL"
fi

if ! grep "DASHBOARD_PUBLIC_BASE_URL" $SUBLIME_ENV_FILE >/dev/null 2>&1; then
    echo "DASHBOARD_PUBLIC_BASE_URL=$sublime_host:3000" >>$SUBLIME_ENV_FILE
    echo "Configured dashboard URL"
fi

if ! grep "API_PUBLIC_BASE_URL" $SUBLIME_ENV_FILE >/dev/null 2>&1; then
    echo "API_PUBLIC_BASE_URL=$sublime_host:8000" >>$SUBLIME_ENV_FILE
    echo "Configured API URL"
fi

$cmd_prefix docker compose up --quiet-pull -d

echo
echo "Checking health of containers..."
sleep 3

container_id_by_name() {
    echo $(docker ps -aqf "name="$1"")
}

pg_error_string="retryable migration error: pq: password authentication failed for user"
bora_container_id="$(container_id_by_name "sublime_bora_lite")"

if [ -z "$bora_container_id" ]; then
    echo "error: bora container not found"
fi

bora_logs="$(docker logs "$bora_container_id")"

if echo "$bora_logs" | grep -q "$pg_error_string"; then
    print_error "An error was encountered. Stopping containers..."

    docker compose down

    print_error "Your sublime.env file no longer contains the correct Postgres credentials."
    print_color "\nIf this is a new install and you don't have any data to lose, follow the instructions at this link:" error
    print_error "https://docs.sublimesecurity.com/docs/quickstart-docker#wipe-your-data"
    print_error "Then, delete the sublime-platform directory and re-run the installer."
    print_error "If you have data that you need to keep, please contact Sublime support."
fi
