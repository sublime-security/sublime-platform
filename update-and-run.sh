#!/bin/bash

if [[ "$1" != "always_launch" ]]; then
    docker-compose ps | grep "mantis"
    if [[ "${?}" != "0" ]]; then
        echo "docker-compose appears to be brought down. Will not proceed to avoid relaunching."
    	exit 0
    fi
fi

cmd_prefix="sudo "

# Docker setups on OS X generally won't need sudo
# TODO this check is pretty naive -- a properly setup docker/compose setup in Linux won't need sudo either
if [[ "$(uname -s)" == "Darwin" ]]; then
    cmd_prefix=""
fi

# TODO if the platform is down don't restart it

if [[ -z "$(git status --porcelain)" ]]; then
	echo "git working dir clean. Proceeding with git updates."

	old_ref=$(git rev-parse HEAD)
	git pull
	new_ref=$(git rev-parse HEAD)

	if [[ "${old_ref}" != "${new_ref}" ]]; then
        $cmd_prefix docker-compose down --remove-orphans
	fi
else
    echo "Uncommitted changes present, ignoring updates to sublime-platform git repo"
fi

# TODO support checking for specific keys and generating as needed
SUBLIME_ENV_FILE=sublime.env

if [[ -f "$SUBLIME_ENV_FILE" ]]; then
    echo "$SUBLIME_ENV_FILE exists already!"
else
    POSTGRES_PASSWORD=$(openssl rand -hex 24)
    JWT_SECRET=$(openssl rand -hex 24)
     # note: key length must be 16, 24, or 32 bytes
    POSTGRES_ENCRYPTION_KEY=$(openssl rand -hex 32)
    FAKE_AWS_ACCESS_KEY_ID=$(openssl rand -hex 32)
    FAKE_AWS_SECRET_ACCESS_KEY=$(openssl rand -hex 32)

    echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD" >> $SUBLIME_ENV_FILE
    echo "JWT_SECRET=$JWT_SECRET" >> $SUBLIME_ENV_FILE
    echo "POSTGRES_ENCRYPTION_KEY=$POSTGRES_ENCRYPTION_KEY" >> $SUBLIME_ENV_FILE
    echo "CORS_ALLOW_ORIGINS=http://localhost:3000" >> $SUBLIME_ENV_FILE
    echo "BASE_URL=http://localhost:8000" >> $SUBLIME_ENV_FILE
    echo "DASHBOARD_PUBLIC_BASE_URL=http://localhost:3000" >> $SUBLIME_ENV_FILE
    echo "API_PUBLIC_BASE_URL=http://localhost:8000" >> $SUBLIME_ENV_FILE
    echo "AWS_ACCESS_KEY_ID=fake_$FAKE_AWS_ACCESS_KEY_ID" >> $SUBLIME_ENV_FILE
    echo "AWS_SECRET_ACCESS_KEY=fake_$FAKE_AWS_SECRET_ACCESS_KEY" >> $SUBLIME_ENV_FILE

    echo "Successfully generated $SUBLIME_ENV_FILE"
fi

$cmd_prefix docker-compose pull && $cmd_prefix docker-compose up -d

