#!/usr/bin/env bash

: ==========================================
:   Installation utilities
: ==========================================

# This file contains utility functions to be used within the
# Sublime installation scripts.

color_default="0m"
color_info="94m" # blue
color_success="92m" # green
color_warning="93m" # yellow
color_error="91m" # red
color_bold="97m" # white

# prints colored text
print_color() {
    if [ "$2" == "info" ] ; then
        COLOR="$color_info"
    elif [ "$2" == "success" ] ; then
        COLOR="$color_success"
    elif [ "$2" == "warning" ] ; then
        COLOR="$color_warning"
    elif [ "$2" == "error" ] ; then
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
   printf "\n** "
   print_color "$1" "success"
   printf " **\n"
}

print_info() {
   print_color "\n$1\n" "info"
}

print_warning() {
   print_color "\n$1\n" "warning"
}
