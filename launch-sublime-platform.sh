#!/bin/bash

. ./utils.sh

if [ -z "$interactive" ]; then
    interactive="true"
fi

if [ "$interactive" != "true" ] && [ -z "$auto_updates" ]; then
    auto_updates=true
fi

if ! ./preflight_checks.sh; then
    exit 1
fi

command_exists() {
    command -v "$@" > /dev/null 2>&1
}

print_info "Configuring automatic updates..."
if [ "$interactive" == "true" ] && [ -z "$auto_updates" ]; then
    while true; do
        # Since this script is intended to be piped into bash, we need to explicitly read input from /dev/tty because stdin
        # is streaming the script itself
        read -rp 'Would you like to enable auto-updates? [Y/n]: ' yn </dev/tty
        case $yn in
            [Yy]* | "" ) auto_updates="true"; read -rp 'Your terminal may request permission to add a cron job in the next step. Press enter to continue...'; break;;
            [Nn]* ) auto_updates="false"; break;;
            * ) echo "Please answer y or n.";;
        esac
    done
fi

if [ -z "$auto_updates" ]; then
    auto_updates=true
fi

if [ "$auto_updates" == "true" ]; then
    # We run cron specific preflight checks again in case the user interactively enabled automatic updates
    if ! command_exists cron; then
        print_error "Cron not installed"
        echo "Please install cron and retry"
        exit 1
    fi

    if command_exists systemctl && ! systemctl status cron > /dev/null 2>&1; then
        # This check may not be reliable if some other init system is used, or maybe cron was temp disabled
        print_warning "cron may not be running! Will proceed, but auto updates will not function without cron"
    fi

    # If this command is modified we might need a more sophisticated check below (worse case is more updates than intended)
    update_command="cd ""$(pwd)"" && bash -lc ./update-and-run.sh"

    if ! crontab -l | grep "$update_command" > /dev/null 2>&1; then
        echo "Adding daily update check"
        (crontab -l 2>/dev/null; echo "0 12 * * * ""$update_command") | crontab -
    else
        echo "Daily update check is already setup"
    fi
fi

print_info "Launching Sublime Platform..."
./update-and-run.sh always_launch
