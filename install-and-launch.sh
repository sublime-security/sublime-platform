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
:  Clone Platform - default: true
: -----------------------------------------

# By default, this script will clone the latest Sublime Platform repo and enter into it before proceeding with the rest
# of the installation. You may want to disable this if you're running this script from within the Sublime Platform repo
# already.
#
: curl -sL https://sublimesecurity.com/install.sh | clone_platform=false bash
#

printf "\nRunning preflight checks\n"
if ! curl -sL https://raw.githubusercontent.com/sublime-security/sublime-platform/main/preflight_checks.sh | bash; then
    exit 1
fi

if [ -z "$interactive" ]; then
    interactive="true"
fi

if [ "$interactive" == "true" ] && [ -z "$sublime_host" ]; then
    # Since this script is intended to be piped into bash, we need to explicitly read input from /dev/tty because stdin
    # is streaming the script itself
    printf "\nPlease specify the hostname or IP address of where you're deploying Sublime\n"
    read -rp "(IP address or hostname of your VPS or VM | default: http://localhost): " sublime_host </dev/tty
fi

if [ -z "$clone_platform" ]; then
    clone_platform=true
fi

if [ "$clone_platform" == "true" ]; then
    echo "Cloning Sublime Platform repo"
    if ! git clone --depth=1 https://github.com/sublime-security/sublime-platform.git; then
      echo "Failed to clone Sublime Platform repo"
      exit 1
    fi

    cd sublime-platform || { echo "Failed to cd into sublime-platform"; exit 1; }
fi


echo "Launching Sublime Platform"
# We are skipping preflight checks because we've already performed them at the start of this script
if ! sublime_host=$sublime_host skip_preflight=true ./launch-sublime-platform.sh; then
    echo "Failed to launch Sublime Platform"
    exit 1
fi

echo "Successfully installed Sublime Platform!"
dashboard_url=$(grep 'DASHBOARD_PUBLIC_BASE_URL' sublime.env | cut -d'=' -f2)
echo "Your Sublime Dashboard is running at $dashboard_url"
echo "It may take a couple of minutes for all services to start for the first time"
