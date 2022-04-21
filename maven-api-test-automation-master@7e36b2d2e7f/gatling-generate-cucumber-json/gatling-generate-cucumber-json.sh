#!/usr/bin/env bash

set -o errexit  # Fail when a command fails (ignore using set +o errexit; ...; set -o errexit)
set -o nounset  # Fail when undefined environment variables are used
set -o pipefail # Fail when any command in a pipe sequence fails (default is last only)

PREREQS=(node npm)
PREREQS_OK=1

for PREREQ in "${PREREQS[@]}"; do
    if ! command -v "${PREREQ}" > /dev/null 2>&1; then
        echo "FAIL: Command '${PREREQ}' is not installed" >&2
        PREREQS_OK=0
    fi
done

# exit if prerequisites are not OK
[ "${PREREQS_OK}" -eq 0 ] && exit 1

THIS_FOLDER="$(cd "$(dirname "${0}")" && pwd)"

if [ ! -d "${THIS_FOLDER}/node_modules" ]; then
    cd "${THIS_FOLDER}" || {
        echo "FAIL: Unable to change directory to '${THIS_FOLDER}'"
        exit 1
    }
    npm ci
    cd -
fi

node "${THIS_FOLDER}/bin/gatling-generate-cucumber-json.js" "$@"
