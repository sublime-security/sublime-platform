#!/usr/bin/env bash

: ==========================================
:   Introduction
: ==========================================

# This script allows you to install the latest version of the Sublime Platform by running:
#
: curl -sL https://raw.githubusercontent.com/sublime-security/sublime-platform/main/install-and-launch.sh | bash
#
# Note: lines prefixed with ":" are no-ops but still retain syntax highlighting. Bash considers ":" as true and true can
# take an infinite number of arguments and still return true. Inspired from the Firebase tool installer.

: ==========================================
:   Advanced Usage
: ==========================================

# You can change the behavior of this script by passing environmental variables to the bash process. For example:
#
: curl -sL https://raw.githubusercontent.com/sublime-security/sublime-platform/main/install-and-launch.sh | arg1=foo arg2=bar bash
#

: -----------------------------------------
:  Sublime Host - default: localhost
: -----------------------------------------

# By default, this script assumes that Sublime is deployed locally. If you installed Sublime on a remote VPS or VM,
# you'll need to specify IP address of your remote system.
#
: curl -sL https://raw.githubusercontent.com/sublime-security/sublime-platform/main/install-and-launch.sh | sublime_host=0.0.0.0 bash
#
# Replace 0.0.0.0 with the IP address of your remote system.

echo "Cloning Sublime Platform repo"
if ! git clone https://github.com/sublime-security/sublime-platform.git;
then
  echo "Failed to clone Sublime Platform repo"
  exit 1
fi

echo "Launching Sublime Platform"
cd sublime-platform || { echo "Failed to cd into sublime-platform"; exit 1; }

./launch-sublime-platform.sh

open "$(grep 'DASHBOARD_PUBLIC_BASE_URL' sublime.env | cut -d'=' -f2)"
