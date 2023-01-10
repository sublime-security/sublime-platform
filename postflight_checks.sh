#!/usr/bin/env bash

. ./utils.sh

if ! which jq > /dev/null 2>&1; then
    print_error "Post-flight checks require jq to be installed. Please install jq and retry (https://stedolan.github.io/jq/download/)"
    exit 1
fi

if [ -z "$timeout_minutes" ]; then
    timeout_minutes=20
fi

if [ -z "$retry_interval_seconds" ]; then
    retry_interval_seconds=5
fi

if [ -z "$unhealthy_retries" ]; then
    unhealthy_retries=3
fi

remaining_timeout_seconds=$(( timeout_minutes * 60 ))
remaining_unhealthy_retries=$unhealthy_retries

health_endpoint="$(grep 'API_PUBLIC_BASE_URL' sublime.env | cut -d'=' -f2)/v1/health"
while [ $remaining_timeout_seconds -gt 0 ]; do
    print_info "Attempting to check Sublime Platform health"

    if [ "$(curl -s "$health_endpoint" | jq '.success')" == "true" ]; then
        print_success "Sublime Platform is healthy!"
        exit 0
    fi

    if [ "$(curl -s "$health_endpoint" | jq '.success')" == "false" ]; then
        remaining_unhealthy_retries=$(( remaining_unhealthy_retries - 1 ))
    fi

    if [ $remaining_unhealthy_retries -lt 0 ]; then
        print_error "Sublime Platform is unhealthy. See details below:"
        curl -s "$health_endpoint" | jq '.'
        exit 1
    fi

    remaining_timeout_seconds=$(( remaining_timeout_seconds - retry_interval_seconds ))
    sleep $retry_interval_seconds
done

print_error "Unable to check Sublime Platform health due to timeout"
exit 1
