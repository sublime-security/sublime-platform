#!/bin/sh

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

    # ascii art
    # credit: https://patorjk.com/
    # font: Cyberlarge
    cat << EOF

======================================================================
|  _______ _     _ ______         _____ _______ _______              |
|   |______ |     | |_____] |        |   |  |  | |______             |
|   ______| |_____| |_____] |_____ __|__ |  |  | |______             |
|                                                                    |
|    _____         _______ _______ _______  _____   ______ _______   |
|   |_____] |      |_____|    |    |______ |     | |_____/ |  |  |   |
|   |       |_____ |     |    |    |       |_____| |    \_ |  |  |   |
|                                                                    |
======================================================================

EOF

fi

: ==========================================
:   Installation utilities
: ==========================================

# Copied from utils.sh

color_default="0m"
color_info="94m" # blue
color_success="92m" # green
color_warning="93m" # yellow
color_error="91m" # red

# prints colored text
print_color() {
    if [ "$2" = "info" ] ; then
        COLOR="$color_info"
    elif [ "$2" = "success" ] ; then
        COLOR="$color_success"
    elif [ "$2" = "warning" ] ; then
        COLOR="$color_warning"
    elif [ "$2" = "error" ] ; then
        COLOR="$color_error"
    else #default color
        COLOR="$color_default"
    fi

    STARTCOLOR="\e[$COLOR"
    ENDCOLOR="\e[$color_default"

    printf "${STARTCOLOR}%b${ENDCOLOR}" "$1"
}

print_error() {
   print_color "\n$1\n" "error"
}

print_success() {
   print_color "\n$1\n" "success"
}

print_info() {
   print_color "\n$1\n" "info"
}

print_warning() {
   print_color "\n$1\n" "warning"
}

command_exists() {
    command -v "$@" > /dev/null 2>&1
}

major_minor() {
    echo "${1%%.*}.$(
      x="${1#*.}"
      echo "${x%%.*}"
    )"
}

version_gt() {
  [ "${1%.*}" -gt "${2%.*}" ] || [ "${1%.*}" -eq "${2%.*}" ] && [ "${1#*.}" -gt "${2#*.}" ]
}

version_ge() {
  [ "${1%.*}" -gt "${2%.*}" ] || [ "${1%.*}" -eq "${2%.*}" ] && [ "${1#*.}" -ge "${2#*.}" ]
}

version_lt() {
  [ "${1%.*}" -lt "${2%.*}" ] || [ "${1%.*}" -eq "${2%.*}" ] && [ "${1#*.}" -lt "${2#*.}" ]
}

open_ports() {
  lsof -i -P -n | grep LISTEN | sed 's/^.*:\([0-9][0-9]*\) (LISTEN)/\1/g' | uniq
}

check_port() {
  if open_ports | grep -q "$1"; then
    print_error "Port $1 is already in use\n"
    echo "If you're unable to free this port, reach out for assistance: support@sublimesecurity.com"
    exit 1
  fi
}

if [ -z "$remote_branch" ]; then
  remote_branch="main"
fi

if [ "$interactive" != "true" ] && [ -z "$auto_updates" ]; then
    auto_updates=true
fi

default_host="http://localhost"

preflight_checks() {
    print_info "Running preflight checks..."

    case "$(uname -s | tr '[:upper:]' '[:lower:]')" in
        linux*)     machine=linux;;
        darwin*)    machine=macos;;
    esac

    if [ -z "$machine" ]; then
        print_warning "Warning: You are using a non-recommended operating system so subsequent failures may occur."
        print_warning "Recommended operating systems:"
        print_warning "https://docs.sublimesecurity.com/docs/quickstart-docker#requirements"
    fi

    if [ "$machine" = "macos" ]; then
        macos_version="$(/usr/bin/sw_vers -productVersion)"
        if version_lt "$(major_minor "$macos_version")" "11.0"; then
            print_warning "Warning: Mac OS version $macos_version does not meet the recommended minimum version of 11.0"
        fi
    fi

    if [ "$machine" = "linux" ]; then
        # "Distributor ID: Ubuntu" -> "ubuntu
        linux_name="$(lsb_release -a 2>/dev/null | grep 'Distributor' | cut -d':' -f2 | xargs | tr '[:upper:]' '[:lower:]')"
        if [ "$linux_name" = "ubuntu" ]; then
            # "Release:    18.04" -> "18.04"
            ubuntu_version="$(lsb_release -a 2>/dev/null | grep 'Release' | cut -d':' -f2 | xargs)"
            if version_lt "$ubuntu_version" "20.04"; then
                print_warning "Warning: Ubuntu version $ubuntu_version does not meet the recommended minimum version of 20.04"
            fi
        else
            print_warning "Warning: Non-Ubuntu Linux distributions are currently not recommended and subsequent failures may occur."
        fi
    fi

    if command_exists lsof; then
      check_port 3000
      check_port 8000
    else
      print_color "\nlsof command not available - unable to complete port check." warning
      print_warning "Please ensure that ports 3000 and 8000 are available, or installation may fail."
      print_color "\nPress [ENTER] to continue." info
      read -r
      printf "\n"
    fi

    if ! command_exists git; then
        print_error "Git is not installed. Please install git and retry:"
        print_error "https://git-scm.com/downloads"
        exit 1
    fi

    # git --version -> git version 2.37.0 (Apple Git-136)
    git_version="$(git --version 2>/dev/null)"

    # Remove longest substring matching "*version " starting from the front of the string
    # Should be "2.37.0 (Apple Git-136)"
    git_version=${git_version##*version }

    # Remove longest substring matching " (*" starting from the end of the string
    # Should be "2.37.0"
    git_version=${git_version%% (*}

    if version_lt "$(major_minor "$git_version")" "2.7"; then
        print_error "Git version $git_version does not meet the minimum version of 2.7"
        print_error "Please update git and retry."
        exit 1
    fi

    if ! command_exists docker; then
        if [ "$machine" = "linux" ]; then
            print_error "Docker is not installed. Please install Docker and retry."
            print_warning "Snap installations of Docker are *not supported*. Please use this link to install Docker:"
            print_error "https://docs.docker.com/engine/install/ubuntu/#install-using-the-convenience-script"
            exit 1
        fi

        print_error "Docker not installed. Please install Docker and retry:"
        print_error "https://docs.docker.com/get-docker"
        exit 1
    fi

    docker_cmd_prefix=""
    if [ "$machine" = "linux" ]; then
        docker_cmd_prefix="sudo "
    fi

    # "Docker version 20.10.17, build 100c701"
    docker_version="$($docker_cmd_prefix docker --version 2>/dev/null)"

    # Remove longest substring matching "*version " starting from the front of the string
    # Should be "20.10.17, build 100c701"
    docker_version=${docker_version##*version }

    # Remove longest substring matching ", *" starting from the end of the string
    # Should be "20.10.17"
    docker_version=${docker_version%%, *}

    if version_lt "$(major_minor "$docker_version")" "20.10"; then
        print_error "Docker version $docker_version does not meet the minimum version of 20.10"
        print_error "Please update Docker and retry."
        exit 1
    fi

    if ! $docker_cmd_prefix docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and retry."
        exit 1
    fi

    # "Docker Compose version v2.10.2"
    docker_compose_version="$(docker compose version 2>/dev/null)"

    # Remove longest substring matching "*version v" starting from the front of the string
    # Should be "2.10.2"
    docker_compose_version=${docker_compose_version##*version v}

    if [ -z "$docker_compose_version" ]; then
        if [ "$machine" = "linux" ]; then
            print_error "Docker Compose is not installed. Please install Docker Compose and retry:"
            print_error "https://docs.docker.com/compose/install/linux/#install-using-the-repository"
            exit 1
        fi

        print_error "Docker Compose is not installed. Please install Docker Compose and retry:"
        print_error "https://docs.docker.com/compose/install/"
        exit 1
    fi

    if version_lt "$(major_minor "$docker_compose_version")" "2.4"; then
        print_error "Docker Compose version $docker_compose_version does not meet the minimum version of 2.4"
        print_error "Please update Docker Compose and retry."
        exit 1
    fi

    if [ "$auto_updates" = "true" ] && ! command_exists cron; then
        print_error "Cron is not installed. Please install cron and retry."
        exit 1
    fi

    if [ "$auto_updates" = "true" ] && command_exists systemctl && ! systemctl status cron > /dev/null 2>&1; then
        # This check may not be reliable if some other init system is used, or maybe cron was temp disabled
        print_warning "Cron may not be running! Will proceed, but auto updates will not function without cron"
    fi

    # snap, an ubuntu package manager, versions of docker won't play nicely with compose
    # reject these early and recommend users contact us if needed. Nothing specific about
    # our software is related to snap issues, but we don't want anyone to uninstall snap
    # docker without realizing they could loose data (from our platform or other applications).
    if command_exists snap && snap list | grep -i docker > /dev/null 2>&1; then
        print_error "Snap versions of Docker are not supported. Please follow these instructions to remove the package and re-install:"
        print_error "https://docs.sublimesecurity.com/docs/quickstart-docker#snap-is-not-supported"
        printf "\nIf you have existing docker containers or volumes or have any questions, please contact support@sublimesecurity.com for assistance\n"

        exit 1

    fi

    print_success "** Successfully completed preflight checks! **"
}

launch_sublime() {
    print_info "Configuring automatic updates..."
    if [ "$interactive" = "true" ] && [ -z "$auto_updates" ]; then
        while true; do
            # Since this script is intended to be piped into bash, we need to explicitly read input from /dev/tty because stdin
            # is streaming the script itself
            printf 'Would you like to enable auto-updates? [Y/n]: '
            read -r yn </dev/tty
            case $yn in
                [Yy]* | "" )
                    auto_updates="true";
                    printf 'Your terminal may request permission to add a cron job in the next step. Press enter to continue...';
                    read -r
                    break;;
                [Nn]* ) auto_updates="false"; break;;
                * ) echo "Please answer y or n.";;
            esac
        done
    fi

    if [ -z "$auto_updates" ]; then
        auto_updates=true
    fi

    if [ "$auto_updates" = "true" ]; then
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
}

install_sublime() {
    if [ "$interactive" = "true" ] && [ -z "$sublime_host" ]; then
        print_info "Configuring host...\n"

        # showing 'http://localhost' as the default can be confusing if you're on a remote host
        # make an attempt at showing an intelligent default host

        # if $SSH_CONNECTION is set, parse the IP and use that as the default
        # this should generally always be set if you're SSH'd in, unless you've forced no TTY (i.e. ssh -T)
        if [ -n "$SSH_CONNECTION" ]; then
            hostname=$(printf '%s' "$SSH_CONNECTION" | awk '{print $3}')
            default_host="http://${hostname}"
        fi

        # Since this script is intended to be piped into bash, we need to explicitly read input from /dev/tty because stdin
        # is streaming the script itself
        printf "Please specify the hostname or IP address of where you're deploying Sublime. We'll use this to configure your CORS settings.\n\n"
        printf "This should match the hostname you'll use to access your deployment after setup. You can change this later.\n\n"
        # printf "You can change this at any time: https://docs.sublimesecurity.com/docs/quickstart-docker#updating-your-sublime-host\n\n"
        # read -rp "Press enter to accept '$default_host' as the default: " sublime_host </dev/tty
        printf "Press enter to accept '%s' as the default: " "$default_host"
        read -r sublime_host </dev/tty
    fi

    if [ -z "$sublime_host" ]; then
        sublime_host=$default_host
    fi

    case "$sublime_host" in
    http*) sublime_host="http://$sublime_host";
    esac

    if [ -z "$clone_platform" ]; then
        clone_platform=true
    fi

    if [ "$clone_platform" = "true" ]; then
        print_info "Cloning Sublime Platform repo..."
        if ! git clone --depth=1 https://github.com/sublime-security/sublime-platform.git; then
            print_error "Failed to clone Sublime Platform repo\n"
            printf "Troubleshooting tips: https://docs.sublimesecurity.com/docs/quickstart-docker#troubleshooting\n\n"
            printf "You may need to run the following command before retrying installation:\n\n"
            printf "rm -rf ./sublime-platform\n"
            exit 1
        fi

        cd sublime-platform || { print_error "Failed to cd into sublime-platform"; exit 1; }
    fi

    if ! sublime_host=$sublime_host interactive=$interactive auto_updates=$auto_updates launch_sublime; then
        print_error "Failed to launch Sublime Platform\n"
        printf "Troubleshooting tips: https://docs.sublimesecurity.com/docs/quickstart-docker#troubleshooting\n\n"
        printf "If you'd like to re-install Sublime then follow these steps: https://docs.sublimesecurity.com/docs/quickstart-docker#wipe-your-data\n\n"
        printf "Afterwards, run: rm -rf ./sublime-platform\n\n"
        printf "You can then go through the Sublime Platform installation again\n"
        exit 1
    fi

    print_success "** Successfully installed Sublime Platform! **"

    dashboard_url=$(grep 'DASHBOARD_PUBLIC_BASE_URL' sublime.env | cut -d'=' -f2)
    printf "\nIt may take a couple of minutes for all services to start for the first time.\n\n"
    printf "For info on how to start or stop the Platform, or help with troubleshooting, see the docs:\n\n"
    printf "https://docs.sublimesecurity.com/docs/quickstart-docker#troubleshooting\n"
    print_success "Your Sublime Dashboard: $dashboard_url"
}

preflight_checks

install_sublime
