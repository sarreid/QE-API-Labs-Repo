#!/usr/bin/env bash
#
# Simple script to run tests and save output to timestamp file
#

set -o errexit  # Fail when a command fails (ignore using set +o errexit; ...; set -o errexit)
set -o nounset  # Fail when undefined environment variables are used
set -o pipefail # Fail when any command in a pipe sequence fails (default is last only)

SCRIPT=${SCRIPT:-tests}

usage () {
    (
        if [ "$#" -gt 0 ] && [ -n "${1}" ]; then
            echo
            echo "Unknown option '${1}' specified"
        fi
        echo
        echo "usage: $0 [option] ..."
        echo
        echo "   -c | --npm-ci          Perform 'npm ci' to reinstall node modules"
        echo "   -s | --script name     Package script to run (default: ${SCRIPT})"
        echo "   --                     Remaining arguments are passed through to the package script being run"
        echo
    ) >&2
    exit 1
}

formatDuration() {
    if [[ "$#" -gt 0 && -n "${1}" && "${1}" =~ ^[0-9]+$ ]]; then
        (( h =  ${1} / 3600))
        (( m = (${1} % 3600) / 60))
        (( s =  ${1} % 60))
    else
        h=0
        m=0
        s=0
    fi
    printf '%02d:%02d:%02d' $h $m $s
}

#
# quoteArgs - echo arguments, quoting those arguments which contain any of the following characters:
#
#   space       Ensure arguments are not treated as multiple arguments
#   <           Redirects stdout to a file
#   >           Redirects stdin from a file
#   &           Used to run a command in the background
#   |           Used to pipe output to another command
#   ;           Terminates a command
#
# To be safe, anything which is not alphanumeric, '-', '=' or '_' is quoted
#
quoteArgs() {
    COMMAND_LINE=''

    if [ "$#" -gt 0 ]; then
        for ARG in "$@"; do
            if [ "${#COMMAND_LINE}" -gt 0 ]; then
                COMMAND_LINE+=' '
            fi
            # In order to use regex set [], place regex in an environment variable
            PATTERN='[^-0-9a-zA-Z_=.]'
            if [[ "${ARG}" =~ ${PATTERN} ]]; then
                COMMAND_LINE+="'${ARG}'"
            else
                COMMAND_LINE+="${ARG}"
            fi
        done
    fi

    echo "${COMMAND_LINE}"
}

THIS_FOLDER="$(cd "$(dirname "${0}")" && pwd)"
NPM_CI=0

while [ "$#" -gt 0 ] && [ -n "${1}" ]; do
    case "${1}" in
        -c|--npm-ci)
            NPM_CI=1
            shift
            ;;
        -s|--script)
            if [ "$#" -lt 2 ] || [ -z "${2}" ]; then
                echo "FAIL: Package script name must be specified." >&2
                exit 1
            fi
            SCRIPT="${2}"
            shift; shift
            ;;
        --script=*)
            SCRIPT="${1#*=}"
            shift
            ;;
        --)
            shift
            break 2 # Break out of case AND while
            ;;
        -\?|--help)
            usage
            ;;
        *)
            usage "${1}"
            ;;
    esac
done


# Verify the the required prerequisites are available
PREREQS=(node npm tee)
PREREQS_OK=1

for PREREQ in "${PREREQS[@]}"; do
    if ! command -v "${PREREQ}" > /dev/null 2>&1; then
        echo "FAIL: Command '${PREREQ}' is not installed" >&2
        PREREQS_OK=0
    fi
done

# exit if prerequisites are not OK
[ "${PREREQS_OK}" -eq 0 ] && exit 1

# Change directory to the test-integration folder - that is, where this file is located
cd "${THIS_FOLDER}" || {
    echo "FAIL: Unable to change directory to '${THIS_FOLDER}'"
    exit 1
}

RESULTS_FOLDER="./results"
RESULTS_FILE="${RESULTS_FOLDER}/tests-$(date '+%Y.%m.%d-%H.%M.%S').txt"

if [ ! -d "${RESULTS_FOLDER}" ]; then
    echo "Creating '${RESULTS_FOLDER}'..."
    mkdir -p "${RESULTS_FOLDER}"
fi

{
    if [ ! -d './node_modules' ] || [ "${NPM_CI}" -ne 0 ]; then
        echo "Installing NodeJS dependencies"
        npm ci
    fi

    ARGS=("npm" "run" "${SCRIPT}")

    if [ "$#" -gt 0 ]; then
        # Copy additional arguments specified on the command line
        for ARG in "$@"; do
            ARGS+=("${ARG}")
        done
    fi

    echo
    echo "Running integration tests:"
    echo
    echo "    Script:      ${SCRIPT}"
    echo "    Command:     $(quoteArgs "${ARGS[@]}")"
    echo
    echo "Output written to '${RESULTS_FILE}'"

    echo
    echo "Executing:"
    echo
    echo "    $(quoteArgs "${ARGS[@]}")"

    START="$(date +%s)"
    "${ARGS[@]}"
    END="$(date +%s)"

    (( DURATION = END - START ))

    echo
    echo "Output saved to '${RESULTS_FILE}' (took $(formatDuration "${DURATION}"))"
    echo
} | tee "${RESULTS_FILE}"
