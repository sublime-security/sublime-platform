#!/bin/bash

echo "Validating that docker (non-snap) and docker-compose (standalone not plugin) are installed"
echo "Ubuntu snap packages will be rejected"

# Startup version checks
which docker
if [[ "${?}" != "0" ]]; then
	echo "docker not installed. Please install docker and retry"
	exit 1
fi

which docker-compose
if [[ "${?}" != "0" ]]; then
    echo "docker-compose not installed. Please install docker-compose and retry"
	exit 1
fi

which cron
if [[ "${?}" != "0" ]]; then
    echo "cron not installed. Please install cron and retry"
	exit 1
fi

which systemctl
if [[ "${?}" == "0" ]]; then
    systemctl status cron
    if [[ "${?}" != "0" ]]; then
        # this check may not be reliable if some other init system is used, or maybe cron was temp disabled.
        echo "cron may not be running! Will proceed, but auto updates will not function without cron"
    fi
fi

# snap, an ubuntu package manager, versions of docker won't play nicely with compose
# reject these early and recommend users contact us if needed. Nothing specific about
# our software is related to snap issues, but we don't want anyone to uninstall snap
# docker without realizing they could loose data (from our platform or other applications).
which snap
if [[ "${?}" == "0" ]]; then
	snap list | grep -i docker
	if [[ "${?}" == "0" ]]; then
		echo "snap versions of docker software detected! Cannot proceed."
		echo "snap versions of docker are not recommended and can prevent issues when using compose in the future (e.g. cannot bring containers down)"
		echo "please uninstall snap docker packages and install with apt"
		echo "If you have existing docker containers or volumes or are otherwise unsure, please contact Sublime Security for assistance"
		exit 1
	fi
fi

# If this command is modified we might need a more sophisticated check below (worse case is more updates than intended)
update_command="cd ""$(pwd)"" && ./update-and-run.sh"

crontab -l | grep "$update_command"
if [[ "${?}" == "1" ]]; then
	echo "Adding daily update check"
	(crontab -l 2>/dev/null; echo "0 12 * * * ""$update_command") | crontab -
else
	echo "daily update check is already setup"
fi

echo "Updating and running!"
$update_command always_launch
