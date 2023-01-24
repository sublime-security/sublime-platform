#!/usr/bin/env bash

# shellcheck disable=SC2154
if [ "$skip_preflight" == "true" ]; then
    exit 0
fi

if [ -z "$remote_branch" ]; then
    remote_branch="main"
fi

source /dev/stdin <<< "$(curl -sL https://raw.github.com/sublime-security/sublime-platform/${remote_branch}/utils.sh)"

print_info "Running preflight checks..."

major_minor() {
  echo "${1%%.*}.$(
    x="${1#*.}"
    echo "${x%%.*}"
  )"
}

version_gt() {
  [[ "${1%.*}" -gt "${2%.*}" ]] || [[ "${1%.*}" -eq "${2%.*}" && "${1#*.}" -gt "${2#*.}" ]]
}

version_ge() {
  [[ "${1%.*}" -gt "${2%.*}" ]] || [[ "${1%.*}" -eq "${2%.*}" && "${1#*.}" -ge "${2#*.}" ]]
}

version_lt() {
  [[ "${1%.*}" -lt "${2%.*}" ]] || [[ "${1%.*}" -eq "${2%.*}" && "${1#*.}" -lt "${2#*.}" ]]
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

case "$(uname -s | tr '[:upper:]' '[:lower:]')" in
    linux*)     machine=linux;;
    darwin*)    machine=macos;;
esac

if [ -z "$machine" ]; then
    print_warning "Warning: You are using a non-recommended operating system so subsequent failures may occur."
    print_warning "Recommended operating systems:"
    print_warning "https://docs.sublimesecurity.com/docs/quickstart-docker#requirements"
fi

if [ "$machine" == "macos" ]; then
    macos_version="$(/usr/bin/sw_vers -productVersion)"
    if version_lt "$(major_minor "$macos_version")" "11.0"; then
        print_warning "Warning: Mac OS version $macos_version does not meet the recommended minimum version of 11.0"
    fi
fi

if [ "$machine" == "linux" ]; then
    # "Distributor ID: Ubuntu" -> "ubuntu
    linux_name="$(lsb_release -a 2>/dev/null | grep 'Distributor' | cut -d':' -f2 | xargs | tr '[:upper:]' '[:lower:]')"
    if [ "$linux_name" == "ubuntu" ]; then
        # "Release:    18.04" -> "18.04"
        ubuntu_version="$(lsb_release -a 2>/dev/null | grep 'Release' | cut -d':' -f2 | xargs)"
        if version_lt "$ubuntu_version" "20.04"; then
            print_warning "Warning: Ubuntu version $ubuntu_version does not meet the recommended minimum version of 20.04"
        fi
    else
        print_warning "Warning: Non-Ubuntu Linux distributions are currently not recommended and subsequent failures may occur."
    fi
fi

check_port 3000
check_port 8000

if ! which git > /dev/null 2>&1; then
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

if ! which docker > /dev/null 2>&1; then
    if [ "$machine" == "linux" ]; then
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
if [ "$machine" == "linux" ]; then
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
    if [ "$machine" == "linux" ]; then
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

if [ "$auto_updates" == "true" ] && ! which cron > /dev/null 2>&1; then
    print_error "Cron is not installed. Please install cron and retry."
    exit 1
fi

if [ "$auto_updates" == "true" ] && which systemctl > /dev/null 2>&1 && ! systemctl status cron > /dev/null 2>&1; then
    # This check may not be reliable if some other init system is used, or maybe cron was temp disabled
    print_warning "Cron may not be running! Will proceed, but auto updates will not function without cron"
fi

# snap, an ubuntu package manager, versions of docker won't play nicely with compose
# reject these early and recommend users contact us if needed. Nothing specific about
# our software is related to snap issues, but we don't want anyone to uninstall snap
# docker without realizing they could loose data (from our platform or other applications).
if which snap > /dev/null 2>&1 && snap list | grep -i docker > /dev/null 2>&1; then
    print_error "Snap versions of Docker detected! Cannot proceed."
    print_error "Snap versions of Docker are not recommended because they can cause issues when using Docker Compose in the future (e.g. cannot bring containers down)"

    if [ "$machine" == "linux" ]; then
        print_warning "Please uninstall Snap Docker packages and follow the official Docker installation instructions:"
        print_warning "https://docs.docker.com/engine/install/ubuntu/#install-using-the-convenience-script"
        printf "\nIf you have existing docker containers or volumes or are otherwise unsure, please contact support@sublimesecurity.com for assistance\n"
        exit 1
    fi

    print_warning "Please uninstall Snap Docker packages and follow the Docker instructions:"
    print_warning "https://docs.docker.com/get-docker/"
    printf "\nIf you have existing docker containers or volumes or are otherwise unsure, please contact support@sublimesecurity.com for assistance\n"
    exit 1

fi

print_success "** Successfully completed preflight checks! **"
