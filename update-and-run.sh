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

if [ ! -z "$cmd_prefix_override" ]; then
    cmd_prefix=$cmd_prefix_override
fi

if [ "$1" != "always_launch" ]; then
    if ! $cmd_prefix docker compose ps | grep "mantis" >/dev/null 2>&1; then
        print_error "Sublime Platform appears to have been manually shut down. Will not proceed to avoid relaunching."
        print_warning "If you wish to relaunch, please refer to the documentation here:"
        print_warning "https://docs.sublimesecurity.com/docs/quickstart-docker#how-to-update"
        exit 0
    fi
fi

if [ -z "$(git status --porcelain)" ]; then
    echo "git working dir clean. Proceeding with git updates."

    old_ref=$(git rev-parse HEAD)
    logrun git pull
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

CERTBOT_ENV_FILE=certbot.env
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

if [ -f "$CERTBOT_ENV_FILE" ]; then
    $cmd_prefix docker compose --profile letsencrypt pull --include-deps
    $cmd_prefix sh -c "LETSENCRYPT_ENV=$CERTBOT_ENV_FILE docker compose --profile letsencrypt up --quiet-pull -d"
else
    $cmd_prefix docker compose pull --include-deps
    $cmd_prefix docker compose up --quiet-pull -d
fi
