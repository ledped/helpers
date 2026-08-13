#!/bin/bash

set -euo pipefail

usage() {
    printf 'Usage: %s ENV_VAR=KEYCHAIN_SERVICE [...] -- COMMAND [ARG ...]\n' "${0##*/}" >&2
}

if (($# == 0)); then
    usage
    exit 2
fi

found_separator=false
account="${USER:-$(/usr/bin/id -un)}"

while (($# > 0)); do
    if [[ "$1" == "--" ]]; then
        found_separator=true
        shift
        break
    fi

    mapping="$1"
    shift

    if [[ "$mapping" != *=* ]]; then
        printf 'Error: invalid mapping %q; expected ENV_VAR=KEYCHAIN_SERVICE.\n' "$mapping" >&2
        exit 2
    fi

    variable_name="${mapping%%=*}"
    service="${mapping#*=}"

    if [[ ! "$variable_name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
        printf 'Error: invalid environment variable name %q.\n' "$variable_name" >&2
        exit 2
    fi

    if [[ -z "$service" ]]; then
        printf 'Error: Keychain service must be non-empty for %s.\n' "$variable_name" >&2
        exit 2
    fi

    if ! secret="$(/usr/bin/security find-generic-password -s "$service" -a "$account" -w)"; then
        printf 'Error: unable to read the Keychain item for %s.\n' "$variable_name" >&2
        exit 1
    fi

    printf -v "$variable_name" '%s' "$secret"
    export "$variable_name"
    unset secret
done

if [[ "$found_separator" != true ]]; then
    printf 'Error: missing -- before the command.\n' >&2
    usage
    exit 2
fi

if (($# == 0)); then
    printf 'Error: missing command after --.\n' >&2
    usage
    exit 2
fi

exec "$@"