#!/usr/bin/env bash

# shellcheck disable=SC2154
if [ "$skip_preflight" == "true" ]; then
    exit 0
fi

echo "Validating that docker (non-snap) and docker-compose (standalone not plugin) are installed"
echo "Ubuntu snap packages will be rejected"

if ! which docker > /dev/null 2>&1; then
	echo "docker not installed. Please install docker and retry (https://docs.docker.com/get-docker/)"
	exit 1
fi

if ! which docker-compose > /dev/null 2>&1; then
    echo "docker-compose not installed. Please install docker-compose and retry (https://docs.docker.com/compose/install/)"
	exit 1
fi

if ! which cron > /dev/null 2>&1; then
    echo "cron not installed. Please install cron and retry"
	exit 1
fi

if which systemctl > /dev/null 2>&1 && ! systemctl status cron > /dev/null 2>&1; then
    # this check may not be reliable if some other init system is used, or maybe cron was temp disabled.
    echo "cron may not be running! Will proceed, but auto updates will not function without cron"
fi

# snap, an ubuntu package manager, versions of docker won't play nicely with compose
# reject these early and recommend users contact us if needed. Nothing specific about
# our software is related to snap issues, but we don't want anyone to uninstall snap
# docker without realizing they could loose data (from our platform or other applications).
if which snap > /dev/null 2>&1 && snap list | grep -i docker > /dev/null 2>&1; then
    echo "snap versions of docker software detected! Cannot proceed."
    echo "snap versions of docker are not recommended and can cause issues when using compose in the future (e.g. cannot bring containers down)"
    echo "please uninstall snap docker packages and install with apt"
    echo "If you have existing docker containers or volumes or are otherwise unsure, please contact support@sublimesecurity.com for assistance"
    exit 1
fi
