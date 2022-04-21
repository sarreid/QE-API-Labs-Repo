#!/usr/bin/env bash

#
# Upload API automation test results to Jira using Xray API
#
# Uploads ZIP file containing API automation test result files (cucumber JSON format) using
# Xray API to create a test execution
#
# Updates test execution's summary, description, labels, environment, test environments to provide context
#

set -o errexit  # Fail when a command fails (ignore using set +o errexit; ...; set -o errexit)
set -o nounset  # Fail when undefined environment variables are used
set -o pipefail # Fail when any command in a pipe sequence fails (default is last only)

THIS_FOLDER="$(cd "$(dirname "${0}")" && pwd)"
JIRA_PROTOCOL_DEFAULT=${JIRA_PROTOCOL_DEFAULT:-https}
JIRA_HOST_DEFAULT=${JIRA_HOST_DEFAULT:-hub.deloittedigital.com.au}
JIRA_PATH_DEFAULT=${JIRA_PATH_DEFAULT:-rest/raven/1.0/import/execution/bundle}
JIRA_USERNAME_DEFAULT=${JIRA_USERNAME_DEFAULT:-XRay}
JIRA_PASSWORD_DEFAULT=${JIRA_PASSWORD_DEFAULT:-}
PASSWORD_TIMEOUT_DEFAULT=${PASSWORD_TIMEOUT_DEFAULT:-30}
RESULTS_FOLDER_DEFAULT=${RESULTS_FOLDER_DEFAULT:-${THIS_FOLDER}/target/surefire-reports}

usage () {
    local RETURN_CODE=0
    if [ -n "${1:-}" ]; then
        echo "FAIL: Unknown option '${1}' specified" >&2
        RETURN=1
    fi
    cat <<USAGE_EOF

usage: $(basename "$0") [option]

    -f value  | --folder value    Folder containing Cucumber JSON report files to upload to Jira (default: ${RESULTS_FOLDER_DEFAULT})
    -h value  | --host value      Jira host name (default: ${JIRA_HOST_DEFAULT})
    -p value  | --path value      Jira path to upload resutls to (default: ${JIRA_PATH_DEFAULT})
    -r value  | --protocol value  Jira protocol use (default: ${JIRA_PROTOCOL_DEFAULT})
    -t value  | --timeout value   Number of seconds to wait for password to be entered (default: ${PASSWORD_TIMEOUT_DEFAULT} seconds)
    -u name   | --username name   Jira username to upload results as (default: ${JIRA_USERNAME_DEFAULT})
    -w value  | --password value  Jira password to upload results as (if not specified, it will be prompted for)

    --help                        Show this help and exit
USAGE_EOF

    return "${RETURN}"
}

#
# Display failure message, which optional 'information returned' and 'Data'
#
# Arguments:
#       $1      Log type (eg FAIL, WARM, INFO)
#       $1      Message to be displayed
#       $2      Optional - this value is displayed as 'information returned'
#       $3      Optional - this value is displayed as 'Data'
#
logit() {

    if [ "$#" -lt 2 ] || [ "$#" -gt 4 ]; then
        # NOTE: We cannot call fail() as down the rabbit hole we go"
        echo "FAIL: usage logit log-type message [info [data]]"
        return 1
    fi

    LOG_TYPE=${1}
    MESSAGE=${2}
    INFO=${3:-}
    DATA=${4:-}
    echo "${LOG_TYPE}: ${MESSAGE}"
    if [ -n "${INFO}" ]; then
        echo "Information returned:"
        echo "${INFO}"
    fi
    if [ -n "${DATA}" ]; then
        echo "Data:"
        echo "${DATA}"
    fi
}

#
# Display failure message, which optional 'information returned' and 'Data' to stderr
#
# Arguments:
#       $1      Message to be displayed
#       $2      Optional - this value is displayed as 'information returned'
#       $3      Optional - this value is displayed as 'Data'
#
fail() {
    logit "FAIL" "$@" >&2
    return 1
}

#
# Display warning message, which optional 'information returned' and 'Data' to stderr
#
# Arguments:
#       $1      Message to be displayed
#       $2      Optional - this value is displayed as 'information returned'
#       $3      Optional - this value is displayed as 'Data'
#
warn() {
    logit "WARN" "$@" >&2
    return 0
}

#
# Display informational message, which optional 'information returned' and 'Data'
#
# Arguments:
#       $1      Message to be displayed
#       $2      Optional - this value is displayed as 'information returned'
#       $3      Optional - this value is displayed as 'Data'
#
info() {
    logit "INFO" "$@"
    return 0
}

#
# Returns absolute path to relative path
#
abspath() {
    if [ "$#" -ne 1 ]; then
        echo "FAIL: usage abspath path"
        return 1
    fi
  echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

#
# Contains element - returns 0 if item is present in a list of items; otherwise non-zero is returned
#
# Arguments:
#       $1          Item to match
#       $2 ...      Items to be matched
#
# Example:
#
#       VALUES=('One' 'Two' 'Three')
#       VALUE='Two'
#       if containsElement "${VALUE}" "$VALUES[@]"; then
#           echo "Value '${VALUE}' is present"
#       else
#           echo "Value '${VALUE}' is not present"
#       fi
#
containsElement () {
    if [ "$#" -lt 1 ]; then
        echo "FAIL: usage containsElement check value ..."
        return 1
    fi

    local MATCH="${1}"
    shift
    local ARG
    local RETURN_CODE=1
    for ARG in "$@"; do
        if [ "${ARG}" == "${MATCH}" ]; then
            RETURN_CODE=0
            break
        fi
    done
    return "${RETURN_CODE}"
}

#
# Checks whether status matches expected, showing information about failure.
#
# Arguments:
#       $1          Status code returned
#       $2          Expected status code
#       $3          Caption, a broef description of nature of API call
#       $4          Jira username (for unauthorised or forbidden)
#       $5          Optional - data returned by API call
#
# Unauthorised (401), forbidden (403) and not found (404) are handled explicitly as these are known for brevity of output
#
checkStatusCode() {
    if [ "$#" -lt 4 ] || [ "$#" -gt 5 ]; then
        echo "FAIL: usage checkStatusCode status-code expected-status-code caption jira-username [data]"
        return 1
    fi
    local STATUS_CODE="${1}"
    local STATUS_CODE_EXPECTED="${2}"
    local STATUS_CODE_UNAUTHORISED='401'
    local STATUS_CODE_FORBIDDEN='403'
    local STATUS_CODE_NOT_FOUND='404'
    local CAPTION="${3}"
    local JIRA_USERNAME="${4}"
    local DATA="${5}"

    if [ "${STATUS_CODE}" != "${STATUS_CODE_EXPECTED}" ]; then
        if [ "${STATUS_CODE}" == "${STATUS_CODE_UNAUTHORISED}" ]; then
            fail "${CAPTION} failed - unauthorised (${STATUS_CODE_UNAUTHORISED}) - check permissions for Jira user '${JIRA_USERNAME}' and password supplied"
        elif [ "${STATUS_CODE}" == "${STATUS_CODE_FORBIDDEN}" ]; then
            fail "${CAPTION} failed - forbidden (${STATUS_CODE_FORBIDDEN}) - check permissions for Jira user '${JIRA_USERNAME}' and password supplied"
        elif [ "${STATUS_CODE}" == "${STATUS_CODE_NOT_FOUND}" ]; then
            fail "${CAPTION} failed - not found (${STATUS_CODE_NOT_FOUND})"
        else
            fail "${CAPTION} failed - status code ${STATUS_CODE} returned when ${STATUS_CODE_EXPECTED} was expected" "${DATA}"
        fi
        return 1
    fi
}

#
# Given JIRA data of an issue where names has been expanded (expand=names), a field name is returned
# using the field's description has the lookup value.
#
# To be used to lookup custom fields, but works for normal fields too.
#
# Arguments:
#       $1          JSON data of issue
#       $2          Field description to use to lookup field name
#
# Returns:
#       Field name, or blank if it can't be found
#
lookupFieldName() {
    if [ "$#" -ne 2 ]; then
        fail "usage lookupFieldName JSON field-description"
        return 1
    fi
    local DATA=${1}
    local FIELD_DESCRIPTION=${2}
    local FIELD_NAME=''

    #
    # Jira issue data includes the names of the fields
    # {
    #      :
    #      "names": {
    #          "customfield_10470": "Database Objects DML Changes Quality Analyst.",
    #          "customfield_10350": "Project Name",
    #          "customfield_14843": "Test Environments",
    #          "fixVersions": "Targeted Release/s",
    #          "customfield_11200": "Global Rank",
    #          :
    #      }
    # }
    #
    # Using '.names | to_entries[]' will convert the above into:
    #
    # {
    #     "key": "customfield_10470",
    #     "value": "Database Objects DML Changes Quality Analyst."
    # }
    # {
    #     "key": "customfield_10350",
    #     "value": "Project Name"
    # }
    # {
    #     "key": "customfield_14843",
    #     "value": "Test Environments"
    # }
    # {
    #     "key": "fixVersions",
    #     "value": "Targeted Release/s"
    # }
    # {
    #     "key": "customfield_11200",
    #     "value": "Global Rank"
    # }
    #
    # From which we can then use 'select(.value == "Test Environments") | .key' to select the 'customfield_14843'
    #
    if ! FIELD_NAME=$(jq -e -r ".names | to_entries[] | select(.value == \"${FIELD_DESCRIPTION}\") | .key" <<< "${DATA}"); then
        warn "Lookup of field name failed as no field has a description of '${FIELD_DESCRIPTION}'"
    fi
    echo "${FIELD_NAME}"
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

#
# Get host name
#
getHostName() {
    local COMMAND=(hostname)
    local OUTPUT
    if ! OUTPUT=$("${COMMAND[@]}"); then
        warn "Command \"$(quoteArgs "${COMMAND[@]}")\" failed"
    fi
    echo "${OUTPUT}"
}

#
# Get user name
#
getUserName() {
    COMMAND=(whoami)
    if ! OUTPUT=$("${COMMAND[@]}"); then
        warn "Command \"$(quoteArgs "${COMMAND[@]}")\" failed"
    fi
    echo "${OUTPUT}"
}

while [ "$#" -gt 0 ] && [ -n "${1}" ]; do
    case "${1}" in
        -f|--folder)
            if [ "$#" -lt 2 ] || [ -z "${2}" ]; then
                echo "FAIL: Folder name must be specified." >&2
                exit 1
            fi
            RESULTS_FOLDER="${2}"
            shift; shift
            ;;
        -f=*|--folder=*)
            RESULTS_FOLDER="${1#*=}"
            shift
            ;;
        -h|--host)
            if [ "$#" -lt 2 ] || [ -z "${2}" ]; then
                echo "FAIL: Host value must be specified." >&2
                exit 1
            fi
            JIRA_HOST="${2}"
            shift; shift
            ;;
        -h=*|--host=*)
            JIRA_HOST="${1#*=}"
            shift
            ;;
        -p|--path)
            if [ "$#" -lt 2 ] || [ -z "${2}" ]; then
                echo "FAIL: Jira path value must be specified." >&2
                exit 1
            fi
            JIRA_PATH="${2}"
            shift; shift
            ;;
        -p=*|--path=*)
            JIRA_PATH="${1#*=}"
            shift
            ;;
        -r|--protocol)
            if [ "$#" -lt 2 ] || [ -z "${2}" ]; then
                echo "FAIL: Jira protocol value must be specified." >&2
                exit 1
            fi
            JIRA_PROTOCOL="${2}"
            shift; shift
            ;;
        -r=*|--protocol=*)
            JIRA_PROTOCOL="${1#*=}"
            shift
            ;;
        -t|--timeout)
            if [ "$#" -lt 2 ] || [ -z "${2}" ]; then
                echo "FAIL: Timeout value must be specified." >&2
                exit 1
            fi
            PASSWORD_TIMEOUT="${2}"
            shift; shift
            ;;
        -t=*|--timeout=*)
            PASSWORD_TIMEOUT="${1#*=}"
            shift
            ;;
        -u|--username)
            if [ "$#" -lt 2 ] || [ -z "${2}" ]; then
                echo "FAIL: Username value must be specified." >&2
                exit 1
            fi
            JIRA_USERNAME="${2}"
            shift; shift
            ;;
        -u=*|--username=*)
            JIRA_USERNAME="${1#*=}"
            shift
            ;;
        -w|--password)
            if [ "$#" -lt 2 ] || [ -z "${2}" ]; then
                echo "FAIL: Password value must be specified." >&2
                exit 1
            fi
            JIRA_PASSWORD="${2}"
            shift; shift
            ;;
        -w=*|--password=*)
            JIRA_PASSWORD="${1#*=}"
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

# At this time, no command line parameters are processed
if [ "$#" -ne 0 ]; then
    usage
    exit 1
fi

# Verify the the required prerequisites are available
PREREQS=(curl jq head tail tr sed)
PREREQS_OK=1

for PREREQ in "${PREREQS[@]}"; do
    if ! command -v "${PREREQ}" > /dev/null 2>&1; then
        echo "FAIL: Command '${PREREQ}' is not available" >&2
        PREREQS_OK=0
    fi
done

[ "${PREREQS_OK}" -eq 0 ] && exit 1

THIS_FOLDER="$(cd "$(dirname "${0}")" && pwd)"
RESULTS_FOLDER=${RESULTS_FOLDER:-${RESULTS_FOLDER_DEFAULT}}
RESULTS_ZIP_FILE_NAME=${RESULTS_ZIP_FILE_NAME:-results.zip}
RESULTS_ZIP_FILE=${RESULTS_ZIP_FILE:-${THIS_FOLDER}/${RESULTS_ZIP_FILE_NAME}}

# Get absolute path name to results ZIP file - so we can change directory to the results folder
ABSOLUTE_RESULTS_ZIP_FILE=$(abspath "${RESULTS_ZIP_FILE}")

if [ ! -d "${RESULTS_FOLDER}" ]; then
    fail "Results folder '${RESULTS_FOLDER}' does not exist"
    exit 1
fi

if [ -f "${RESULTS_ZIP_FILE}" ]; then
    echo
    echo "Results ZIP file '${RESULTS_ZIP_FILE}' already exists - deleting"
    rm -f "${RESULTS_ZIP_FILE}"
fi

if ! cd "${RESULTS_FOLDER}"; then
    fail "Unable to change directory to '${RESULTS_FOLDER}'"
    exit 1
fi

# Get JSON result files present in current folder, which is the results folder
RESULT_JSON_FILES=()
while IFS='' read -r RESULT_JSON_FILE; do
    RESULT_JSON_FILES+=("${RESULT_JSON_FILE}");
done < <(find "." -name "*.json" 2> /dev/null)

if [ "${#RESULT_JSON_FILES[@]}" -eq 0 ]; then
    fail "No JSON result files found in '${RESULTS_FOLDER}'"
    exit 1
fi

echo
echo "JSON result files found in '${RESULTS_FOLDER}': ${#RESULT_JSON_FILES[@]}"
echo

if command -v zip > /dev/null 2>&1; then
    echo "Creating result ZIP file '${ABSOLUTE_RESULTS_ZIP_FILE}' (using zip)"
    zip "${ABSOLUTE_RESULTS_ZIP_FILE}" -- "${RESULT_JSON_FILES[@]}"
elif command -v powershell > /dev/null 2>&1; then
    echo "Creating result ZIP file '${ABSOLUTE_RESULTS_ZIP_FILE}' (using powershell)"
    powershell Compress-Archive -Force -Path '*.json' -DestinationPath "${ABSOLUTE_RESULTS_ZIP_FILE}"
else
    fail "Unable to ZIP JSON result files as neither zip or powershell are available"
    exit 1
fi

# Return to previous directory
cd - > /dev/null

if [ ! -f "${RESULTS_ZIP_FILE}" ]; then
    fail "Results ZIP fie '${RESULTS_ZIP_FILE}' does not exist"
    exit 1
fi

JIRA_PROTOCOL=${JIRA_PROTOCOL:-${JIRA_PROTOCOL_DEFAULT}}
JIRA_HOST=${JIRA_HOST:-${JIRA_HOST_DEFAULT}}
JIRA_PATH=${JIRA_PATH:-${JIRA_PATH_DEFAULT}}
JIRA_USERNAME=${JIRA_USERNAME:-${JIRA_USERNAME_DEFAULT}}
JIRA_PASSWORD=${JIRA_PASSWORD:-${JIRA_PASSWORD_DEFAULT}}
PASSWORD_TIMEOUT=${PASSWORD_TIMEOUT:-${PASSWORD_TIMEOUT_DEFAULT}}

JIRA_UPLOAD_API_URL="${JIRA_PROTOCOL}://${JIRA_HOST}/${JIRA_PATH}"

if [ -z "${JIRA_PASSWORD}" ]; then

    # Fail if stdin is not associated with a terminal session
    if [ ! -t 0 ]; then
        fail "Password cannot be solicited when standard input is not taken from an interacive terminal"
        exit 1
    fi

    echo
    echo "Password for Jira user '${JIRA_USERNAME}' has not been provided."
    echo
    while [ -z "${JIRA_PASSWORD}" ]; do
        #
        # Passord has not been specified, so read password from terminal
        #
        #       -s          Do not echo characters as they are typed (it is a password after all)
        #       -p prompt   Display the prompt text
        #       -t number   Timeout after number seconds
        #
        PROMPT="Enter password for Jira user '${JIRA_USERNAME}' (press Ctrl-C to exit - ${PASSWORD_TIMEOUT} seconds timeout): "
        if ! read -s -r -p "${PROMPT}" -t "${PASSWORD_TIMEOUT}" JIRA_PASSWORD; then
            echo
            fail "Password was not entered within ${PASSWORD_TIMEOUT} seconds"
            exit 1
        fi
        # Force a newline, otherwise output will be after the read prompt
        echo
    done
fi

echo
echo "Uploading Jira results file '${RESULTS_ZIP_FILE}' to '${JIRA_UPLOAD_API_URL}'"
if ! OUTPUT=$(curl --silent \
                    --insecure \
                    --user "${JIRA_USERNAME}:${JIRA_PASSWORD}" \
                    --request POST \
                    --header "Content-Type: multipart/form-data" \
                    --form "file=@${RESULTS_ZIP_FILE}" \
                    --write-out '\n%{http_code}' \
                    "${JIRA_UPLOAD_API_URL}"); then
    fail "FAIL: Unable to upload results file '${RESULTS_ZIP_FILE}' to Jira" "${OUTPUT}"
    exit 1
fi

STATUS_CODE=$(tail --lines=1 <<< "${OUTPUT}")
DATA=$(head --lines=-1 <<< "${OUTPUT}")

checkStatusCode "${STATUS_CODE}" 200 "Uploading of results file '${RESULTS_ZIP_FILE}'" "${JIRA_USERNAME}" "${DATA}"

#
# The format of the JSON response is as follows:
#
# {
#   "testExecIssue": {
#     "id": "115439",
#     "key": "EXAMPLE-1",
#     "self": "https://ictissues.sro.vic.gov.au/rest/api/2/issue/115439"
#   },
#   "testIssues": {
#     "success": [
#       {
#         "id": "115425",
#         "key": "EXAMPLE-2",
#         "self": "https://ictissues.sro.vic.gov.au/rest/api/2/issue/115425"
#       },
#       {
#         "id": "115391",
#         "key": "EXAMPLE-3",
#         "self": "https://ictissues.sro.vic.gov.au/rest/api/2/issue/115391"
#       },
#       {
#         "id": "115393",
#         "key": "EXAMPLE-4",
#         "self": "https://ictissues.sro.vic.gov.au/rest/api/2/issue/115393"
#       }
#     ]
#   }
# }


# Validate that information returned is valid JSON
if ! jq -e . > /dev/null 2>&1 <<< "${DATA}"; then
    fail "Data returned for uploading of results file '${RESULTS_ZIP_FILE}' is not valid JSON" "${DATA}"
    exit 1
fi

JIRA_EXECUTION_ISSUE_ID_JSON_PATH='.testExecIssue.id'
if ! JIRA_EXECUTION_ISSUE_ID=$(jq -e -r "${JIRA_EXECUTION_ISSUE_ID_JSON_PATH}" <<< "${DATA}"); then
    fail "Unable to locate Jira execution issue id using path '${JIRA_EXECUTION_ISSUE_ID_JSON_PATH}'" "${DATA}"
    exit 1
fi

if [ -z "${JIRA_EXECUTION_ISSUE_ID}" ]; then
    fail "Jira execution issue id using path '${JIRA_EXECUTION_ISSUE_ID_JSON_PATH}' is blank" "${DATA}"
    exit 1
fi

JIRA_EXECUTION_ISSUE_KEY_JSON_PATH='.testExecIssue.key'
if ! JIRA_EXECUTION_ISSUE_KEY=$(jq -e -r "${JIRA_EXECUTION_ISSUE_KEY_JSON_PATH}" <<< "${DATA}"); then
    fail "Unable to locate Jira execution issue key using path '${JIRA_EXECUTION_ISSUE_KEY_JSON_PATH}'" "${DATA}"
    exit 1
fi

if [ -z "${JIRA_EXECUTION_ISSUE_KEY}" ]; then
    fail "Jira execution issue key using path '${JIRA_EXECUTION_ISSUE_KEY_JSON_PATH}' is blank" "${DATA}"
    exit 1
fi

JIRA_EXECUTION_ISSUE_URL_JSON_PATH='.testExecIssue.self'
if ! JIRA_EXECUTION_ISSUE_URL=$(jq -e -r "${JIRA_EXECUTION_ISSUE_URL_JSON_PATH}" <<< "${DATA}"); then
    # Create Jira execution issue url manually
    JIRA_EXECUTION_ISSUE_URL="${JIRA_PROTOCOL}://${JIRA_HOST}/rest/api/2/issue/${JIRA_EXECUTION_ISSUE_ID}"
    echo "INFO: Unable to locate Jira execution issue url using path '${JIRA_EXECUTION_ISSUE_URL_JSON_PATH}'.  Using '${JIRA_EXECUTION_ISSUE_URL}' instead."
fi

if [ -z "${JIRA_EXECUTION_ISSUE_URL}" ]; then
    fail "Jira execution issue key using path '${JIRA_EXECUTION_ISSUE_URL_JSON_PATH}' is blank" "${DATA}"
    exit 1
fi

echo
echo "INFO: Test execution '${JIRA_EXECUTION_ISSUE_KEY}' (issue ID '${JIRA_EXECUTION_ISSUE_ID}') has been created"
echo
jq -e . <<< "${DATA}"

EXIT_CODE=0
TEST_ISSUES_JSON_PATH='.testIssues'

#
# Locate all status values within '.testIssues'
#
# NOTE: We need to remove the trailing carriage return which is present when run on Windows
#
STATUSES=()
while IFS='' read -r STATUS; do
    # Remove trailing carriage return - courtesy of Windows
    # shellcheck disable=SC2001
    STATUS=$(echo "${STATUS}" | sed 's/\s+$//g')
    STATUSES+=("${STATUS}")
done < <(jq -e -r "${TEST_ISSUES_JSON_PATH} | keys[]" <<< "${DATA}")

STATUS_SUCCESS='success'
if containsElement "${STATUS_SUCCESS}" "${STATUSES[@]}"; then
    echo
    echo "Test execution contains details of the following Jira test issues:"
    echo
    jq -e -r "${TEST_ISSUES_JSON_PATH}.${STATUS_SUCCESS}[] | \"\t\(.key)\"" <<< "${DATA}"
else
    fail "Status '${STATUS_SUCCESS}' is not present within test issues using path '${TEST_ISSUES_JSON_PATH}'"
    EXIT_CODE=1
fi

#
# Output details of response for statues other than success (whatever they are)
#
for STATUS in "${STATUSES[@]}"; do
    [ "${STATUS}" == "${STATUS_SUCCESS}" ] && continue
    echo
    echo "FAIL: Test execution contains details for the status '${STATUS}':"
    echo
    jq -e "${TEST_ISSUES_JSON_PATH}.${STATUS}" <<< "${DATA}"
    EXIT_CODE=1
done

#
# We need to retrive the details of the test execution issue created, so we can use the custom field name for 'Test Environments' to
# update its value
#
# NOTE: expand=names is required so that the names collection of field name -> field description is available
#
echo
echo "Getting Jira details for '${JIRA_EXECUTION_ISSUE_KEY}' using '${JIRA_EXECUTION_ISSUE_URL}'"
if ! OUTPUT=$(curl --silent \
                    --insecure \
                    --user "${JIRA_USERNAME}:${JIRA_PASSWORD}" \
                    --get \
                    --data 'expand=names' \
                    --write-out '\n%{http_code}' \
                    "${JIRA_EXECUTION_ISSUE_URL}"); then
    fail "Getting Jira details for '${JIRA_EXECUTION_ISSUE_KEY}' failed" "${OUTPUT}"
    exit 1
fi

STATUS_CODE=$(tail --lines=1 <<< "${OUTPUT}")
DATA=$(head --lines=-1 <<< "${OUTPUT}")
checkStatusCode "${STATUS_CODE}" 200 "Getting Jira details for '${JIRA_EXECUTION_ISSUE_KEY}'" "${JIRA_USERNAME}" "${DATA}"

TEST_ENVIRONMENTS_DESCRIPTION='Test Environments'
TEST_ENVIRONMENTS_CUSTOM_FIELD=$(lookupFieldName "${DATA}" "${TEST_ENVIRONMENTS_DESCRIPTION}")

if [ -n "${TEST_ENVIRONMENTS_CUSTOM_FIELD}" ]; then
    echo
    echo "Field with description '${TEST_ENVIRONMENTS_DESCRIPTION}' is mapped to field '${TEST_ENVIRONMENTS_CUSTOM_FIELD}'"
fi

#
# Update newly created Xray test execution to provide:
#
#   Summary             Automation Results - YYYY-MM-DD HH:MM:SS OFFSET
#   Labels              Automation
#   Desciption          ...
#   Environment         Applicable environment
#   Test Environments   Applicable environment
#

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S %z")
JENKINS_BUILD_URL=${JENKINS_BUILD_URL:-N/A}
JIRA_EXECUTION_ISSUE_LABEL=${JIRA_EXECUTION_ISSUE_LABEL:-Automation}
JIRA_EXECUTION_ISSUE_ENVIRONMENT=${JIRA_EXECUTION_ISSUE_ENVIRONMENT:-DEV}
JIRA_EXECUTION_ISSUE_FIX_VERSION=${JIRA_EXECUTION_ISSUE_FIX_VERSION:-}

JIRA_EXECUTION_ISSUE_SUMMARY="Automation Results - ${JIRA_EXECUTION_ISSUE_ENVIRONMENT} - ${TIMESTAMP}"
#
# Create description to be used
#
JIRA_EXECUTION_ISSUE_DESCRIPTION=$(cat << EOF_DESCRIPTION
||Property||Description||
|Date|${TIMESTAMP}|
|Host|$(getHostName)|
|User|$(getUserName)|
|Environment|${JIRA_EXECUTION_ISSUE_ENVIRONMENT}|
|Jenkins|${JENKINS_BUILD_URL}|
EOF_DESCRIPTION
)

#
# Create JSON to update test execution details.
#
# Update JSON using jq - which allows newline characters and double quotes to be escaped correctly (let jq do the hard work)
# Ensure that jq field referencing the jq variables KEY and VALUE, using $KEY and $VALUE, are enclosed within single quotes, so $KEY or $VALUE are not expanded
# as an environment variable.  If the jq filter value is double quoted, then you need to ensure that the "$" character is escaped, ie "\$"
#
UPDATE_EXECUTION_ISSUE_DATA='{ "update": { } }'

if [ -n "${JIRA_EXECUTION_ISSUE_SUMMARY}" ]; then
    UPDATE_EXECUTION_ISSUE_DATA=$(jq -e --arg VALUE "${JIRA_EXECUTION_ISSUE_SUMMARY}" '.update.summary = [ { set: $VALUE } ]' <<< "${UPDATE_EXECUTION_ISSUE_DATA}")
fi
if [ -n "${JIRA_EXECUTION_ISSUE_DESCRIPTION}" ]; then
    UPDATE_EXECUTION_ISSUE_DATA=$(jq -e --arg VALUE "${JIRA_EXECUTION_ISSUE_DESCRIPTION}" '.update.description = [ { set: $VALUE } ]' <<< "${UPDATE_EXECUTION_ISSUE_DATA}")
fi
if [ -n "${JIRA_EXECUTION_ISSUE_LABEL}" ]; then
    UPDATE_EXECUTION_ISSUE_DATA=$(jq -e --arg VALUE "${JIRA_EXECUTION_ISSUE_LABEL}" '.update.labels = [ { add: $VALUE } ]' <<< "${UPDATE_EXECUTION_ISSUE_DATA}")
fi
if [ -n "${JIRA_EXECUTION_ISSUE_ENVIRONMENT}" ]; then
    UPDATE_EXECUTION_ISSUE_DATA=$(jq -e --arg VALUE "${JIRA_EXECUTION_ISSUE_ENVIRONMENT}" '.update.environment = [ { set: $VALUE } ]' <<< "${UPDATE_EXECUTION_ISSUE_DATA}")
    if [ -n "${TEST_ENVIRONMENTS_CUSTOM_FIELD}" ]; then
        UPDATE_EXECUTION_ISSUE_DATA=$(jq -e --arg KEY "${TEST_ENVIRONMENTS_CUSTOM_FIELD}" --arg VALUE "${JIRA_EXECUTION_ISSUE_ENVIRONMENT}" '.update[$KEY] = [ { add: $VALUE } ]' <<< "${UPDATE_EXECUTION_ISSUE_DATA}")
    fi
fi
if [ -n "${JIRA_EXECUTION_ISSUE_FIX_VERSION}" ]; then
    UPDATE_EXECUTION_ISSUE_DATA=$(jq -e --arg VALUE "${JIRA_EXECUTION_ISSUE_FIX_VERSION}" '.update.fixVersions = [ { add: $VALUE } ]' <<< "${UPDATE_EXECUTION_ISSUE_DATA}")
fi

echo
echo "Updating Jira execution issue '${JIRA_EXECUTION_ISSUE_KEY}' (issue ID '${JIRA_EXECUTION_ISSUE_ID}') with the following:"
echo
jq . <<< "${UPDATE_EXECUTION_ISSUE_DATA}"
echo
if ! OUTPUT=$(curl --silent \
                    --insecure \
                    --user "${JIRA_USERNAME}:${JIRA_PASSWORD}" \
                    --request PUT \
                    --header 'Content-Type: application/json' \
                    --data "${UPDATE_EXECUTION_ISSUE_DATA}" \
                    --header 'Accept: application/json' \
                    --write-out '\n%{http_code}' \
                    "${JIRA_EXECUTION_ISSUE_URL}"); then
    fail "FAIL: Unable to update Jira execution issue '${JIRA_EXECUTION_ISSUE_KEY}' (issue ID '${JIRA_EXECUTION_ISSUE_ID}')" "${OUTPUT}" "${UPDATE_EXECUTION_ISSUE_DATA}"
    exit 1
fi

STATUS_CODE=$(tail --lines=1 <<< "${OUTPUT}")
DATA=$(head --lines=-1 <<< "${OUTPUT}")

checkStatusCode "${STATUS_CODE}" 204 "Updating of Jira execution issue '${JIRA_EXECUTION_ISSUE_KEY}'" "${JIRA_USERNAME}" "${DATA}"

echo "Jira execution issue '${JIRA_EXECUTION_ISSUE_KEY}' (issue ID '${JIRA_EXECUTION_ISSUE_ID}') updated"

exit "${EXIT_CODE}"
