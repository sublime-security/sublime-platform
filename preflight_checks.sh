#!/usr/bin/env bash

# shellcheck disable=SC2154
if [ "$skip_preflight" == "true" ]; then
    exit 0
fi

echo "Running preflight checks"

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

case "$(uname -s | tr '[:upper:]' '[:lower:]')" in
    linux*)     machine=linux;;
    darwin*)    machine=macos;;
esac

if [ -z "$machine" ]; then
    echo "Warning: You are using a non-recommended operating system so subsequent failures may occur"
fi

if [ "$machine" == "macos" ]; then
    macos_version="$(/usr/bin/sw_vers -productVersion)"
    if version_lt "$(major_minor "$macos_version")" "11.0"; then
        echo "Warning: Mac OS version $macos_version does not meet the recommended minimum version of 11.0"
    fi
fi

if [ "$machine" == "linux" ]; then
    linux_name="$(grep 'NAME' /etc/os-release | cut -d'=' -f2 | tr '[:upper:]' '[:lower:]')"
    if [ "$linux_name" == "ubuntu" ]; then
        # "20.04.3 LTS (Focal Fossa)"
        ubuntu_version="$(grep 'VERSION' /etc/os-release | cut -d'=' -f2)"

        # Remove longest substring matching " *" starting from the front of the string
        # Should be "20.04.3"
        ubuntu_version=${ubuntu_version## *}
        if version_lt "$(major_minor "$ubuntu_version")" "20.04"; then
            echo "Warning: Ubuntu version $ubuntu_version does not meet the recommended minimum version of 20.04"
        fi
    else
        echo "Warning: Non-Ubuntu Linux distributions are unsupported and subsequent failures may occur"
    fi
fi

if ! which git > /dev/null 2>&1; then
    echo "git not installed. Please install git and retry (https://git-scm.com/downloads)"
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
    echo "git version $git_version does not meet the minimum version of 2.7. Please update git and retry"
    exit 1
fi

if ! which docker > /dev/null 2>&1; then
	echo "docker not installed. Please install docker and retry (https://docs.docker.com/get-docker/)"
	exit 1
fi

# "Docker version 20.10.17, build 100c701"
docker_version="$(docker --version 2>/dev/null)"

# Remove longest substring matching "*version " starting from the front of the string
# Should be "20.10.17, build 100c701"
docker_version=${docker_version##*version }

# Remove longest substring matching ", *" starting from the end of the string
# Should be "20.10.17"
docker_version=${docker_version%%, *}

if version_lt "$(major_minor "$docker_version")" "20.10"; then
    echo "docker version $docker_version does not meet the minimum version of 20.10. Please update docker and retry"
    exit 1
fi

if ! docker info > /dev/null 2>&1; then
	echo "docker is not running. Please start docker and retry"
	exit 1
fi

if ! which docker-compose > /dev/null 2>&1; then
    echo "docker-compose not installed. Please install docker-compose and retry (https://docs.docker.com/compose/install/)"
	exit 1
fi

# "Docker Compose version v2.10.2"
docker_compose_version="$(docker-compose --version 2>/dev/null)"

# Remove longest substring matching "*version v" starting from the front of the string
# Should be "2.10.2"
docker_compose_version=${docker_compose_version##*version v}

if version_lt "$(major_minor "$docker_compose_version")" "2.10"; then
    echo "docker-compose version $docker_compose_version does not meet the minimum version of 2.10. Please update docker-compose and retry"
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

echo "Successfully completed preflight checks!"
