#!/bin/bash

if ! ./preflight_checks.sh; then
    exit 1
fi

# If this command is modified we might need a more sophisticated check below (worse case is more updates than intended)
update_command="cd ""$(pwd)"" && bash -lc ./update-and-run.sh"

if ! crontab -l | grep "$update_command" > /dev/null 2>&1; then
	echo "Adding daily update check"
	(crontab -l 2>/dev/null; echo "0 12 * * * ""$update_command") | crontab -
else
	echo "Daily update check is already setup"
fi

echo "Updating and running!"
./update-and-run.sh always_launch
