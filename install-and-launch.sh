#!/usr/bin/env bash

: ==========================================
:   Introduction
: ==========================================

# This script allows you to install the latest version of the Sublime Platform by running:
#
: curl -sL https://sublimesecurity.com/install.sh | bash
#
# Note: lines prefixed with ":" are no-ops but still retain syntax highlighting. Bash considers ":" as true and true can
# take an infinite number of arguments and still return true. Inspired from the Firebase tool installer.

: ==========================================
:   Advanced Usage
: ==========================================

# You can change the behavior of this script by passing environmental variables to the bash process. For example:
#
: curl -sL https://sublimesecurity.com/install.sh | arg1=foo arg2=bar bash
#

: -----------------------------------------
:  Sublime Host - default: localhost
: -----------------------------------------

# By default, this script assumes that Sublime is deployed locally. If you installed Sublime on a remote VPS or VM,
# you'll need to specify IP address of your remote system.
#
: curl -sL https://sublimesecurity.com/install.sh | sublime_host=0.0.0.0 bash
#
# Replace 0.0.0.0 with the IP address of your remote system.

: -----------------------------------------
:  Interactive - default: true
: -----------------------------------------

# By default, this script assumes that it is being called through the quickstart one-liner. In that case, we need to
# confirm where the Sublime instance is deployed unless it's passed in explicitly.
#
: curl -sL https://sublimesecurity.com/install.sh | interactive=false bash
#

: -----------------------------------------
:  Branch - default: main
: -----------------------------------------

# By default, this script assumes that it should pull dependencies from branch `main`. If you wish to get dependencies
# from another branch, you can specify it here.
#
: curl -sL https://sublimesecurity.com/install.sh | remote_branch=custom-branch bash
#

: -----------------------------------------
:  Clone Platform - default: true
: -----------------------------------------

# By default, this script will clone the latest Sublime Platform repo and enter into it before proceeding with the rest
# of the installation. You may want to disable this if you're running this script from within the Sublime Platform repo
# already.
#
: curl -sL https://sublimesecurity.com/install.sh | clone_platform=false bash
#

: -----------------------------------------
:  Auto Updates - default: true
: -----------------------------------------

# By default, this script will configure automatic updates to the Sublime Platform via a nightly cron job. Editing your
# crontab may require elevated accessibility permissions on certain operation systems (e.g. MacOS). If you're not
# comfortable with giving these permissions or you don't want automatic updates then disable this option.
#
: curl -sL https://sublimesecurity.com/install.sh | auto_updates=false bash
#

if [ -z "$interactive" ]; then
    interactive="true"
fi

if [ -z "$remote_branch" ]; then
    remote_branch="main"
fi

if [ "$interactive" != "true" ] && [ -z "$auto_updates" ]; then
    auto_updates=true
fi

export remote_branch

if ! curl -sL https://raw.githubusercontent.com/sublime-security/sublime-platform/${remote_branch}/preflight_checks.sh  | bash; then
    exit 1
fi

source /dev/stdin <<< "$(curl -sL https://raw.github.com/sublime-security/sublime-platform/${remote_branch}/utils.sh)"

if [ "$interactive" == "true" ] && [ -z "$sublime_host" ]; then
    print_info "Configuring host..."
    # Since this script is intended to be piped into bash, we need to explicitly read input from /dev/tty because stdin
    # is streaming the script itself
    printf "Please specify the hostname or IP address of where you're deploying Sublime. If no scheme is specified then we'll default to http://\n"
    read -rp "(IP address or hostname of your VPS or VM | default: http://localhost): " sublime_host </dev/tty
fi

if [ "$interactive" == "true" ] && [ -z "$auto_updates" ]; then
    print_info "Configuring automatic updates..."

    while true; do
        # Since this script is intended to be piped into bash, we need to explicitly read input from /dev/tty because stdin
        # is streaming the script itself
        read -rp "Would you like to enable auto-updates? If yes, your terminal may request permissions to make updates to your computer: [Y/n]: " yn </dev/tty
        case $yn in
            [Yy]* ) auto_updates="true"; break;;
            [Nn]* ) auto_updates="false"; break;;
            * ) echo "Please answer y or n.";;
        esac
    done

    # Re-run preflight checks with auto_update flag configured
    if ! curl -sL https://raw.githubusercontent.com/sublime-security/sublime-platform/${remote_branch}/preflight_checks.sh | auto_updates=$auto_updates bash; then
        exit 1
    fi
fi

if [ -z "$sublime_host" ]; then
    sublime_host="http://localhost"
fi

if [[ "$sublime_host" != http* ]]; then
    sublime_host="http://$sublime_host"
fi

if [ -z "$clone_platform" ]; then
    clone_platform=true
fi

if [ "$clone_platform" == "true" ]; then
    print_info "Cloning Sublime Platform repo..."
    if ! git clone --depth=1 https://github.com/sublime-security/sublime-platform.git; then
        print_error "Failed to clone Sublime Platform repo"
        echo "See https://docs.sublimesecurity.com/docs/quickstart-docker#troubleshooting for troubleshooting tips"
        echo "You may need to run the following command before retrying installation: rm -rf ./sublime-platform"
        exit 1
    fi

    cd sublime-platform || { print_error "Failed to cd into sublime-platform"; exit 1; }
fi


print_info "Launching Sublime Platform..."
# We are skipping preflight checks because we've already performed them at the start of this script
if ! sublime_host=$sublime_host skip_preflight=true auto_updates=$auto_updates ./launch-sublime-platform.sh; then
    print_error "Failed to launch Sublime Platform"
    echo "See https://docs.sublimesecurity.com/docs/quickstart-docker#troubleshooting for troubleshooting tips"
    echo "If you'd like to reinstall Sublime then follow the steps outline in https://docs.sublimesecurity.com/docs/quickstart-docker#wipe-postgres-volume"
    echo "Afterwards, run: rm -rf ./sublime-platform"
    echo "You can then go through the Sublime Platform installation again"
    exit 1
fi

print_success "Successfully installed Sublime Platform!"

dashboard_url=$(grep 'DASHBOARD_PUBLIC_BASE_URL' sublime.env | cut -d'=' -f2)
printf "It may take a couple of minutes for all services to start for the first time\n"
echo "Please go to your Sublime Dashboard at $dashboard_url"
