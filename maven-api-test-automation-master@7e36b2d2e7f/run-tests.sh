#!/usr/bin/env zsh

#
# Script to run Karate/Gatling based tests and save output and HTML reports to timestamp file/folder
#

set -o errexit  # Fail when a command fails (ignore using set +o errexit; ...; set -o errexit)
set -o nounset  # Fail when undefined environment variables are used
set -o pipefail # Fail when any command in a pipe sequence fails (default is last only)

# Default values which can be overridden via options within this script
POM_FILE_DEFAULT=${POM_FILE_DEFAULT:-pom.xml}
ENV_DEFAULT=${ENV_DEFAULT:-dev}

# Values which can be overridden by setting values to the following environment variables
GIT_ORIGIN=${GIT_ORIGIN:-origin}
GIT_UNTRACKED_FILES=${GIT_UNTRACKED_FILES:-no}
PROFILE_KARATE_TESTS=${PROFILE_KARATE_TESTS:-karate-tests}
PROFILE_KARATE_VERIFY=${PROFILE_KARATE_VERIFY:-karate-verify}
PROFILE_UNIT_TESTS=${PROFILE_UNIT_TESTS:-unit-tests}
PROFILE_GATLING_VERIFY=${PROFILE_GATLING_VERIFY:-gatling-verify}
RESULTS_FOLDER=${RESULTS_FOLDER:-results}
CLASSPATH_FOLDER=${CLASSPATH_FOLDER:-./src/test/resources}

# Do not include environment within latest link
RESULTS_LATEST_LINK="${RESULTS_FOLDER}/tests-latest.txt"
HTML_RESULTS_LATEST_LINK="${RESULTS_FOLDER}/tests-latest"

TEST_MODE_GATLING='gatling'
TEST_MODE_KARATE='karate'
TEST_MODE_UNIT='unit'
TEST_MODE_VERIFY_GATLING='verify-gatling'
TEST_MODE_VERIFY_KARATE='verify-karate'
TEST_MODE_DEFAULT=${TEST_MODE_KARATE}
TEST_MODES=("${TEST_MODE_GATLING}" "${TEST_MODE_KARATE}" "${TEST_MODE_UNIT}" "${TEST_MODE_VERIFY_GATLING}" "${TEST_MODE_VERIFY_KARATE}")

usage () {
    EXIT_CODE=0
    if [ -n "${1:-}" ]; then
        echo "FAIL: Unknown option '${1}' specified" >&2
        EXIT_CODE=1
    fi
    cat <<EOF1

usage: $0 [option] ...

    -a        | --and-tags             AND tags instead of OR
    -d number | --threads number       Number of threads to use
    -e name   | --env name             Run tests against this environment (default: ${ENV_DEFAULT})
    -f folder | --feature folder       Feature folder to process (can be specified 1 or more times)
    -i        | --no-ignore            Do not ignore tests tagged with @ignore
    -o        | --no-clean             Do not clean
    -m file   | --pom file             Use this POM file (default: ${POM_FILE_DEFAULT})
    -p name   | --profile name         Use specified POM profile
    -r        | --remove-results       Delete results folder '${RESULTS_FOLDER}' and exit
    -s mode   | --test-mode mode       Test mode - one of $(quoteArgs --force "${TEST_MODES[@]}") (default: '${TEST_MODE_DEFAULT}')
    -t value  | --tag value            Tag to execute (can be specified 1 or more times)

    --help                             Show this help and exit
    --do-not-check-env                 Do not check environment value - pass through as is
    --do-not-check-features            Do not check feature folders exist - pass through as is
    --do-not-check-tags                Do not check tags for leading '@' - pass through as is
    --do-not-execute                   Display maven command line and exit
    --list                             List all things which can be listed
    --list-environments                List environments
    --list-profiles                    List profiles within POM file
    --list-test-modes                  List test modes
    --no-git-properties                Do not pass git related values (repository, branch, dirty)
    --no-host-user-properties          Do not pass host and user related values
    --no-html-report                   Do not generate HTML report
    --no-no-data                       Do not ignore tests tagged with @NO-DATA
    --no-no-data-env                   Do not ignore tests tagged with @NO-DATA-{env}
    --prompt-no-tags                   Prompt to continue if no tags specified
    --skip-tests                       Define skipTests to prevent Junit tests from running (allows src & test Java code to be compiled)
    --                                 The arguments following are added to the Maven command line

EOF1

    if isUnix; then
        cat <<EOF2
Define the following aliases, open last report and open last failures, to open the last features/failures HTML file:"

    alias olr="echo \\"open '\\\$(realpath --relative-to=. '${HTML_RESULTS_LATEST_LINK}/overview-features.html')'\\"; open '${HTML_RESULTS_LATEST_LINK}/overview-features.html'"
    alias olf="echo \\"open '\\\$(realpath --relative-to=. '${HTML_RESULTS_LATEST_LINK}/overview-failures.html')'\\"; open '${HTML_RESULTS_LATEST_LINK}/overview-failures.html'"

EOF2
    fi

    exit "${EXIT_CODE}"
}

isUnix() {
    if UNAME=$(uname); then
        [[ "${UNAME}" =~ ^Linux*$ ]] && return 0
        [[ "${UNAME}" =~ ^Darwin*$ ]] && return 0
    fi
    # Not Unix (for example Git Bash on Windows, or Cygwin)
    return 1
}

confirm() {
    echo
    while true; do
        read -r -p "$* Continue? (yes/no) " INPUT
        INPUT=$(echo "${INPUT}" | tr '[:upper:]' '[:lower:]')
        case "${INPUT}" in
            y|yes)
                echo "Continuing..."
                break
                ;;
            n|no)
                echo "Exiting..."
                exit 1
                ;;
            *)
                ;;
        esac
    done
}

#
# joinArgs - Join one or more arguments (2nd and subsequent arguments) with the specified delimiter (1st argument)
#
function joinArgs() {
    if [ "$#" -le 1 ]; then
        echo "usage: joinArgs sep args ..." >&2
        return 1
    fi
    local IFS="$1"
    shift
    echo "$*"
}

#
# formatDuration - Format number of seconds into HH:MM:SS
#
formatDuration() {
    if [ "$#" -ne 1 ]; then
        echo "usage: formatDuration seconds" >&2
        return 1
    fi
    if [[ "$#" -gt 0 && -n "${1}" && "${1}" =~ ^[0-9]+$ ]]; then
        h=$(( ${1} / 3600))
        m=$(( (${1} % 3600) / 60))
        s=$(( ${1} % 60))
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
    local COMMAND_LINE=''
    local FORCE=0

    if [ "$#" -gt 0 ] && [ "${1}" == '--force' ]; then
        FORCE=1
        shift
    fi

    if [ "$#" -gt 0 ]; then
        # In order to use regex set [], place regex in an environment variable
        local PATTERN='[^-0-9a-zA-Z_=.]'
        for ARG in "$@"; do
            if [ "${#COMMAND_LINE}" -gt 0 ]; then
                COMMAND_LINE+=' '
            fi
            if [ "${FORCE}" -ne 0 ] || [[ "${ARG}" =~ ${PATTERN} ]]; then
                COMMAND_LINE+="'${ARG}'"
            else
                COMMAND_LINE+="${ARG}"
            fi
        done
    fi

    echo "${COMMAND_LINE}"
}

#
# Best match - returns 0 if item is present in a list of items, partial matches allowed; otherwise non-zero is returned
#
# Arguments:
#       $1          Item to match
#       $2 ...      Items to be matched
#
# Example:
#
#       VALUES=('One' 'Two' 'Three')
#       VALUE='Tw'
#       if BEST_MATCH=$(bestMatch "${VALUE}" "$VALUES[@]"); then
#           echo "Best match of '${VALUE}' is "${BEST_MATCH}"
#       fi
#
bestMatch () {
    if [ "$#" -lt 1 ]; then
        echo "FAIL: usage bestMatch check value ..."
        return 1
    fi

    local MATCH="${1}"
    shift

    local BEST_MATCH=''
    local ARG
    for ARG in "$@"; do
        if [ "${ARG}" == "${MATCH}" ]; then
            # Exact match always wins
            BEST_MATCH=${ARG}
            break
        fi
        if [ "${ARG:0:${#MATCH}}" == "${MATCH}" ]; then
            if [ -n "${BEST_MATCH}" ]; then
                # MATCH does not uniquely match one and only one item
                BEST_MATCH=''
                break
            fi
            BEST_MATCH=${ARG}
        fi
    done

    [ -z "${BEST_MATCH}" ] && return 1

    echo -n "${BEST_MATCH}"
    return 0
}

#
# List profiles present within the specified POM file
#
# NOTE: Requires name of profile to be the firsst line in the profile definition, for example:
#
#       <profile>
#           <id>name</id>
#           <properties>
#               :
#           </properties>
#       </profile>
#
listProfiles() {
    if [ ! -f "${POM_FILE}" ]; then
        echo "FAIL: POM file '${POM_FILE}' does not exist" >&2
        return 1
    fi
    echo
    echo "Valid profiles within '${POM_FILE}' are:"
    if ! grep --after-context=1 '<profile>' "${POM_FILE}" | grep '<id>' | sed --quiet 's:.*<id>\(.*\)</id>.*:    \1:p' | sort; then
        echo '   No profiles are present!'
    fi
}

#
# List available test modes
#
listTestModes() {
    echo
    if [ "${#TEST_MODES[@]}" -gt 0 ]; then
        echo "Valid test modes:"
        for TEST_MODE in "${TEST_MODES[@]}"; do
            if [ "${TEST_MODE}" == "${TEST_MODE_DEFAULT}" ]; then
                echo "    ${TEST_MODE} (default)"
            else
                echo "    ${TEST_MODE}"
            fi 
        done
    else
        echo 'No test modes have been defined!'
    fi
}

#
# Validates one or more profile names within pom file
#
# Assumes that profle name definition is the line after <profile>
#
#       <profile>
#           <id>alt-test-runner</id>
#           <properties>
#               <include.test.runner>com.tenx.bdd.runner.AltTestRunner</include.test.runner>
#               <exclude.test.runner>com.tenx.bdd.runner.TestRunner</exclude.test.runner>
#           </properties>
#       </profile>
#
validateProfiles() {
    if [ ! -f "${POM_FILE}" ]; then
        echo "FAIL: POM file '${POM_FILE}' does not exist" >&2
        return 1
    fi
    RET_CODE=0
    for PROFILE in "$@"; do
            if ! grep --after-context=1 '<profile>' "${POM_FILE}" | grep "<id>${PROFILE}</id>" > /dev/null 2>&1; then
            echo "FAIL: Profile '${PROFILE}' does not exist within '${POM_FILE}'" 1>&2
            RET_CODE=1
        fi
    done
    if [ "${RET_CODE}" -ne 0 ]; then
        listProfiles
    fi
    return "${RET_CODE}"
}

CONFIG_FILE_FOLDER=${CONFIG_FILE_FOLDER:-./src/test/resources}
CONFIG_FILE_PREFIX=${CONFIG_FILE_PREFIX:-karate-config-}
CONFIG_FILE_SUFFIX=${CONFIG_FILE_SUFFIX:-.js}

#
# Verifies that the environment specified is valid, by verifying that the environment specific
# Karate configuration file exists, which is:
#
# ./src/test/resources/karate-config-${ENV}.js
#
validateEnvironment() {
    if [ "$#" -ne 1 ]; then
        echo "usage: validateEnvironment environment" >&2
        return 1
    fi

    local ENV=${1}

    local ENVIRONMENT_CONFIG_FILE="${CONFIG_FILE_FOLDER}/${CONFIG_FILE_PREFIX}${ENV}${CONFIG_FILE_SUFFIX}"

    if [ ! -f "${ENVIRONMENT_CONFIG_FILE}" ]; then
        echo "FAIL: Environment '${ENV}' is not valid as environment configuration file '${ENVIRONMENT_CONFIG_FILE}' does not exist" 1>&2
        listEnvironments
        return 1
    fi

    return 0
}

#
# List valid environments - found by looking for files which match the following
#
# ./src/test/resources/karate-config-*.js
#
listEnvironments() {
    local CONFIG_FILE_PATTERN="${CONFIG_FILE_PREFIX}*${CONFIG_FILE_SUFFIX}"
    local ENVIRONMENTS=()
    while IFS='' read -r CONFIG_FILE; do
        ENVIRONMENT=$(sed --quiet "s:.*${CONFIG_FILE_PREFIX}\(.*\)${CONFIG_FILE_SUFFIX}.*:\1:p" <<< "${CONFIG_FILE}")
        ENVIRONMENTS+=("${ENVIRONMENT}");
    done < <(find "${CONFIG_FILE_FOLDER}" -name "${CONFIG_FILE_PATTERN}" 2> /dev/null | sort)

    echo
    if [ "${#ENVIRONMENTS[@]}" -gt 0 ]; then
        echo "Valid environments are:"
        for ENVIRONMENT in "${ENVIRONMENTS[@]}"; do
            echo "  ${ENVIRONMENT}"
        done
    else
        echo "No environment configuration files have been created within '${CONFIG_FILE_FOLDER}' matching '${CONFIG_FILE_PATTERN}'"
    fi
}

#
# Get host name
#
getHostName() {
    COMMAND=(hostname)
    if ! "${COMMAND[@]}"; then
        echo "WARN: Command \"$(quoteArgs "${COMMAND[@]}")\" failed" >&2
    fi
}

#
# Get user name
#
getUserName() {
    COMMAND=(whoami)
    if ! "${COMMAND[@]}"; then
        echo "WARN: Command \"$(quoteArgs "${COMMAND[@]}")\" failed" >&2
    fi
}

#
# Get the URL of the repository identiified as origin (override via GIT_ORIGIN value - default origin)
#
getGitRepositoryUrl() {
    COMMAND=(git config --get "remote.${GIT_ORIGIN}.url")
    if ! "${COMMAND[@]}"; then
        echo "WARN: Command \"$(quoteArgs "${COMMAND[@]}")\" failed" >&2
    fi
}

#
# Get the name of the curren branch - requires git version 2.22 or later
#
getGitBranch() {
    COMMAND=(git branch --show-current)
    if ! "${COMMAND[@]}"; then
        echo "WARN: Command \"$(quoteArgs "${COMMAND[@]}")\" failed" >&2
    fi
}

#
# Get the long hash of the last commit
#
getGitCommitHash() {
    COMMAND=(git log -n 1 '--pretty=format:%H')
    if ! "${COMMAND[@]}"; then
        echo "WARN: Command \"$(quoteArgs "${COMMAND[@]}")\" failed" >&2
    fi
}

#
# Get the dirty state, expressed as 'Uncommitted files: N', which denotes uncommitted changes.
#
# Uses 'git status --short --untracked-files=no' to count number of uncommitted files
# (to count untracked files set environment variable GIT_UNTRACKED_FILES='all')
#
#       $ git status
#           On branch update/tags-and-scripts
#           Your branch is ahead of 'master' by 5 commits.
#             (use "git push" to publish your local commits)
#
#           Changes to be committed:
#             (use "git restore --staged <file>..." to unstage)
#               modified:   run-tests.sh
#
#           Changes not staged for commit:
#             (use "git add <file>..." to update what will be committed)
#             (use "git restore <file>..." to discard changes in working directory)
#               modified:   src/test/java/runner/TagBasedApiRunner.java
#
#           Untracked files:
#             (use "git add <file>..." to include in what will be committed)
#               README.md
#
#       $ git status --short
#           M  run-tests.sh
#            M src/test/java/runner/TagBasedApiRunner.java
#           ?? README.md
#
#       $ git status --short --untracked-files=no
#           M  run-tests.sh
#            M src/test/java/runner/TagBasedApiRunner.java
#
getGitDirty() {
    COMMAND=(git status --short "--untracked-files=${GIT_UNTRACKED_FILES}")
    # NOTE: 'args echo -n' will remove leading and trailing whitespace (including newline) from 'wc' output
    if CHANGES=$("${COMMAND[@]}" | wc -l | xargs echo -n); then
        if [ "${CHANGES}" -gt 0 ]; then
            echo "Uncommitted files: ${CHANGES}"
        fi
    else
        echo "WARN: Command \"$(quoteArgs "${COMMAND[@]}")\" failed" >&2
    fi
}

THIS_FOLDER="$(cd "$(dirname "${0}")" && pwd)"
CLEAN=1
TAGS=()
FEATURES=()
PROMPT_NO_TAGS=${PROMPT_NO_TAGS:-0}
SKIP_TESTS=${SKIP_TESTS:-0}
THREADS=${THREADS:-}
NO_IGNORE=0
AND_TAGS=0
REMOVE_RESULTS=0
NO_NO_DATA=0
NO_NO_DATA_ENV=0
PROFILES=()
CHECK_ENV=${CHECK_ENV:-1}
CHECK_TAGS=${CHECK_TAGS:-1}
CHECK_FEATURES=${CHECK_FEATURES:-1}
EXECUTE=${EXECUTE:-1}
POM_FILE=${POM_FILE:-${POM_FILE_DEFAULT}}
LIST_ENVIRONMENTS=0
LIST_PROFILES=0
LIST_TEST_MODES=0
GIT_PROPERTIES=${GIT_PROPERTIES:-1}
HOST_USER_PROPERTIES=${HOST_USER_PROPERTIES:-1}
HTML_REPORT=${HTML_REPORT:-1}

while [ "$#" -gt 0 ] && [ -n "${1}" ]; do
    case "${1}" in
        -a|--and-tags)
            AND_TAGS=1
            shift
            ;;
        -e|--env|--environment)
            if [ "$#" -lt 2 ] || [ -z "${2}" ]; then
                echo "FAIL: Environment name must be specified." >&2
                exit 1
            fi
            ENV="${2}"
            shift; shift
            ;;
        -e=*|--env=*|--environment=*)
            ENV="${1#*=}"
            shift
            ;;
        -f|--feature)
            if [ "$#" -lt 2 ] || [ -z "${2}" ]; then
                echo "FAIL: Feature folder must be specified." >&2
                exit 1
            fi
            FEATURES+=("${2}")
            shift; shift
            ;;
        -f=*|--feature=*)
            FEATURES+=("${1#*=}")
            shift
            ;;
        -i|--no-ignore)
            NO_IGNORE=1
            shift
            ;;
        -o|--no-clean)
            CLEAN=0
            shift
            ;;
        -m|--pom)
            if [ "$#" -lt 2 ] || [ -z "${2}" ]; then
                echo "FAIL: POM file must be specified." >&2
                exit 1
            fi
            POM_FILE="${2}"
            shift; shift
            ;;
        -m=*|--pom=*)
            POM_FILE="${1#*=}"
            shift
            ;;
        -p|--profile)
            if [ "$#" -lt 2 ] || [ -z "${2}" ]; then
                echo "FAIL: POM profile must be specified." >&2
                exit 1
            fi
            PROFILES+=("${2}")
            shift; shift
            ;;
        -p=*|--profile=*)
            PROFILES+=("${1#*=}")
            shift
            ;;
        -r|--remove-results)
            REMOVE_RESULTS=1
            shift
            ;;
        -s|--test-mode)
            if [ "$#" -lt 2 ] || [ -z "${2}" ]; then
                echo "FAIL: Test mode value must be specified." >&2
                exit 1
            fi
            TEST_MODE+="${2}"
            shift; shift
            ;;
        -s=*|--test-mode=*)
            TEST_MODE+="${1#*=}"
            shift
            ;;
        -t|--tag)
            if [ "$#" -lt 2 ] || [ -z "${2}" ]; then
                echo "FAIL: Tag value must be specified." >&2
                exit 1
            fi
            TAGS+=("${2}")
            shift; shift
            ;;
        -t=*|--tag=*)
            TAGS+=("${1#*=}")
            shift
            ;;
        -d|--threads)
            if [ "$#" -lt 2 ] || [ -z "${2}" ]; then
                echo "FAIL: Number of threads must be specified." >&2
                exit 1
            fi
            THREADS="${2}"
            shift; shift
            ;;
        -d=*|--threads=*)
            THREADS="${1#*=}"
            shift
            ;;
        --do-not-check-tags)
            CHECK_TAGS=0
            shift
            ;;
        --do-not-check-features)
            CHECK_FEATURES=0
            shift
            ;;
        --do-not-check-env)
            CHECK_ENV=0
            shift
            ;;
        --do-not-execute)
            EXECUTE=0
            shift
            ;;
        --list)
            LIST_ENVIRONMENTS=1
            LIST_PROFILES=1
            LIST_TEST_MODES=1
            shift
            ;;
        --list-environments)
            LIST_ENVIRONMENTS=1
            shift
            ;;
        --list-profiles)
            LIST_PROFILES=1
            shift
            ;;
        --list-test-modes)
            LIST_TEST_MODES=1
            shift
            ;;
        --no-git-properties)
            GIT_PROPERTIES=0
            shift
            ;;
        --no-no-data)
            NO_NO_DATA=1
            shift
            ;;
        --no-no-data-env)
            NO_NO_DATA_ENV=1
            shift
            ;;
        --no-host-user-properties)
            HOST_USER_PROPERTIES=0
            shift
            ;;
        --no-html-report)
            HTML_REPORT=0
            shift
            ;;
        --prompt-no-tags)
            PROMPT_NO_TAGS=1
            shift
            ;;
        --skip-tests)
            SKIP_TESTS=1
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

# Change directory to this folder - that is, where this file is located
cd "${THIS_FOLDER}" || {
    echo "FAIL: Unable to change directory to '${THIS_FOLDER}'"
    exit 1
}

if [ "${REMOVE_RESULTS}" -ne 0 ]; then
    if [ -d "${RESULTS_FOLDER}"  ];  then
        echo "Removing results folder '${RESULTS_FOLDER}'"
        rm -rf "${RESULTS_FOLDER}"
    else
        echo "Results folder '${RESULTS_FOLDER}' does not exist"
    fi
    exit 0
fi

if [ "${LIST_ENVIRONMENTS}" -ne 0 ] || [ "${LIST_PROFILES}" -ne 0 ] || [ "${LIST_TEST_MODES}" -ne 0 ]; then
    [ "${LIST_ENVIRONMENTS}" -ne 0 ] && listEnvironments
    [ "${LIST_PROFILES}" -ne 0 ]     && listProfiles
    [ "${LIST_TEST_MODES}" -ne 0 ]   && listTestModes
    exit 0
fi

# Get current environment, or default, and force lowercase
ENV=$(echo "${ENV:-${ENV_DEFAULT}}" | tr '[:upper:]' '[:lower:]')

if [ -z "${ENV}" ]; then
    echo "FAIL: Environment has not been specified" >&2
    exit 1
fi

if [ "${CHECK_ENV}" -ne 0 ]; then
    validateEnvironment "${ENV}"
fi

# Ensure test mode is default
TEST_MODE=${TEST_MODE:-${TEST_MODE_DEFAULT}}
LOGBACK_XML_FILE=${LOGBACK_XML_FILE:-}

if TEST_MODE_MATCH=$(bestMatch "${TEST_MODE}" "${TEST_MODES[@]}"); then
    TEST_MODE=${TEST_MODE_MATCH}
else
    echo "FAIL: Test mode '${TEST_MODE}' must match, wholly or partially, one of $(quoteArgs --force "${TEST_MODES[@]}")" >&2
    exit 1
fi

# Get test mode description
if [ "${TEST_MODE}" == "${TEST_MODE_KARATE}" ]; then
    TEST_MODE_DESCRIPTION="Karate tests against ${ENV}"
elif [ "${TEST_MODE}" == "${TEST_MODE_VERIFY_KARATE}" ]; then
    TEST_MODE_DESCRIPTION="verify Karate against ${ENV}"
elif [ "${TEST_MODE}" == "${TEST_MODE_GATLING}" ]; then
    TEST_MODE_DESCRIPTION="Gatling tests against ${ENV}"
elif [ "${TEST_MODE}" == "${TEST_MODE_VERIFY_GATLING}" ]; then
    TEST_MODE_DESCRIPTION="verify Gatling tests against ${ENV}"
elif [ "${TEST_MODE}" == "${TEST_MODE_UNIT}" ]; then
    TEST_MODE_DESCRIPTION="unit tests"
else
    TEST_MODE_DESCRIPTION=${TEST_MODE}
fi

if [ "${TEST_MODE}" == "${TEST_MODE_KARATE}" ]; then
    [ -n "${PROFILE_KARATE_TESTS}" ] && PROFILES+=("${PROFILE_KARATE_TESTS}")
elif [ "${TEST_MODE}" == "${TEST_MODE_VERIFY_KARATE}" ]; then
    [ -n "${PROFILE_KARATE_TESTS}" ] && PROFILES+=("${PROFILE_KARATE_TESTS}")
    [ -n "${PROFILE_KARATE_VERIFY}" ] && PROFILES+=("${PROFILE_KARATE_VERIFY}")
    HTML_REPORT=0
elif [ "${TEST_MODE}" == "${TEST_MODE_UNIT}" ]; then
    [ -n "${PROFILE_UNIT_TESTS}" ] && PROFILES+=("${PROFILE_UNIT_TESTS}")
elif [ "${TEST_MODE}" == "${TEST_MODE_GATLING}" ]; then
    LOGBACK_XML_FILE='logback-no-console-test.xml'
elif [ "${TEST_MODE}" == "${TEST_MODE_VERIFY_GATLING}" ]; then
    [ -n "${PROFILE_GATLING_VERIFY}" ] && PROFILES+=("${PROFILE_GATLING_VERIFY}")
    LOGBACK_XML_FILE='logback-no-console-test.xml'
fi

OUTPUT_LOG_FILE=${OUTPUT_LOG_FILE:-target/output.log}
CUCUMBER_HTML_FOLDER=${CUCUMBER_HTML_FOLDER:-target/cucumber-html-reports}
GATLING_FOLDER=${GATLING_FOLDER:-target/gatling}
SUREFIRE_FOLDER=${SUREFIRE_FOLDER:-target/surefire-reports}

RESULTS_FILE_NAME_BASE=${RESULTS_FILE_NAME_BASE:-tests}

COMMAND=(mvn)
[ "${CLEAN}" -ne 0 ] && COMMAND+=(clean)

if [ "${TEST_MODE}" == "${TEST_MODE_GATLING}" ] || [ "${TEST_MODE}" == "${TEST_MODE_VERIFY_GATLING}" ]; then
    COMMAND+=('test-compile' 'gatling:test')
elif [ "${TEST_MODE}" == "${TEST_MODE_KARATE}" ] || [ "${TEST_MODE}" == "${TEST_MODE_VERIFY_KARATE}" ] || [ "${TEST_MODE}" == "${TEST_MODE_UNIT}" ]; then
    COMMAND+=('test-compile' 'surefire:test')
fi 

if [ "${#PROFILES[@]}" -gt 0 ]; then
    validateProfiles "${PROFILES[@]}"
    COMMAND+=("--activate-profiles" "$(joinArgs ',' "${PROFILES[@]}")")
fi

RESULTS_FILE_NAME_BASE="${RESULTS_FILE_NAME_BASE}-${TEST_MODE}"

if [ "${TEST_MODE}" == "${TEST_MODE_GATLING}" ] || [ "${TEST_MODE}" == "${TEST_MODE_VERIFY_GATLING}" ] || [ "${TEST_MODE}" == "${TEST_MODE_KARATE}" ] || [ "${TEST_MODE}" == "${TEST_MODE_VERIFY_KARATE}" ]; then
    COMMAND+=("--define" "karate.env=${ENV}")
    RESULTS_FILE_NAME_BASE="${RESULTS_FILE_NAME_BASE}-${ENV}"
fi

if [ "${SKIP_TESTS}" -ne 0 ]; then
    # Compile the tests, but do not run them
    # NOTE: -Dmaven.test.skip=true will not compile the tests
    COMMAND+=("--define" "skipTests")
fi

if [ -n "${LOGBACK_XML_FILE}" ]; then
    COMMAND+=("--define" "logback.configurationFile=${LOGBACK_XML_FILE}")
fi

if [ "${TEST_MODE}" == "${TEST_MODE_KARATE}" ] || [ "${TEST_MODE}" == "${TEST_MODE_VERIFY_KARATE}" ]; then
    [ -n "${THREADS}" ] && COMMAND+=("--define" "apitest.threads=${THREADS}")

    COMMAND+=("--define" "apitest.fail.if.failures=${FAIL_IF_FAILURES:-true}")

    if [[ "${#FEATURES[@]}" -eq 0 && "${#TAGS[@]}" -eq 0 && "${PROMPT_NO_TAGS}" -ne 0 ]]; then
        confirm "No tags have been specified."
    fi
    if [ "${#TAGS[@]}" -gt 0 ]; then
        APITEST_TAGS=''
        if [ "${AND_TAGS}" -ne 0 ]; then
            TAG_DELIMITER='&'
        else
            TAG_DELIMITER=','
        fi
        for TAG in "${TAGS[@]}"; do
            if [[ "${CHECK_TAGS}" -ne 0  && ! "${TAG}" =~ ^~?@.+$ ]]; then
                echo "FAIL: Tag value '${TAG}' must start with a '@' or '~@' - please correct or use --do-not-check-tags" >&2
                exit 1
            fi
            if [ "${#APITEST_TAGS}" -gt 0 ]; then
                APITEST_TAGS+="${TAG_DELIMITER}"
            fi
            APITEST_TAGS+="${TAG}"
        done
        COMMAND+=("--define" "apitest.tags=${APITEST_TAGS}")
    fi
    if [ "${NO_IGNORE}" -ne 0 ]; then
        COMMAND+=("--define" "apitest.ignore=false")
    fi
    if [ "${NO_NO_DATA}" -ne 0 ]; then
        COMMAND+=("--define" "apitest.no.data=false")
    fi
    if [ "${NO_NO_DATA_ENV}" -ne 0 ]; then
        COMMAND+=("--define" "apitest.no.data.env=false")
    fi
    if [ "${#FEATURES[@]}" -gt 0 ]; then
        INVALID_FEATURES=0
        if [ "${CHECK_FEATURES}" -ne 0 ]; then
            for FEATURE in "${FEATURES[@]}"; do
                if [[ "${FEATURE}" =~ ^classpath: ]]; then
                    # Convert class path folder into relative folder using CLASSPATH_FOLDER
                    FOLDER=${CLASSPATH_FOLDER}/${FEATURE//classpath:/}
                    echo "INFO: Class path '${FEATURE}' specified, checking folder '${FOLDER}'"
                else
                    FOLDER=${FEATURE}
                fi
                if [ ! -d "${FOLDER}" ]; then
                    echo "FAIL: Feature folder '${FOLDER}' does not exist" >&2
                    INVALID_FEATURES=$(( INVALID_FEATURES + 1 ))
                fi
            done
        fi
        if [ "${INVALID_FEATURES}" -ne 0 ]; then
            echo "FAIL: ${INVALID_FEATURES} feature folders are invalid - please correct or use --do-not-check-features" >&2
            exit 1
        fi
        COMMAND+=("--define" "apitest.feature.paths=$(joinArgs ',' "${FEATURES[@]}")")
    fi
    if [ "${HOST_USER_PROPERTIES}" -ne 0 ] && [ "${HTML_REPORT}" -ne 0 ]; then
        COMMAND+=("--define" "apitest.host=$(getHostName)")
        COMMAND+=("--define" "apitest.user=$(getUserName)")
    fi
    if [ "${GIT_PROPERTIES}" -ne 0 ] && [ "${HTML_REPORT}" -ne 0 ]; then
        COMMAND+=("--define" "apitest.git.repository.url=$(getGitRepositoryUrl)")
        COMMAND+=("--define" "apitest.git.branch=$(getGitBranch)")
        COMMAND+=("--define" "apitest.git.commit.hash=$(getGitCommitHash)")
        COMMAND+=("--define" "apitest.git.dirty=$(getGitDirty)")
    fi
    if [ "${HTML_REPORT}" -eq 0 ]; then
        COMMAND+=("--define" "apitest.html.report.generate=false")
    fi
fi

if [ "$#" -gt 0 ]; then
    # Copy additional arguments specified on the command line
    for ARG in "$@"; do
        COMMAND+=("${ARG}")
    done
fi

if [ "${EXECUTE}" -eq 0 ]; then
    echo
    echo "Command to be excecuted:"
    echo
    echo "    $(quoteArgs "${COMMAND[@]}")"
    echo
    exit 0
fi

EXIT_CODE=0

if [ ! -d "${RESULTS_FOLDER}" ]; then
    echo "INFO: Creating results folders '${RESULTS_FOLDER}'"
    mkdir -p "${RESULTS_FOLDER}"
fi

TIMESTAMP=$(date '+%Y.%m.%d-%H.%M.%S')
RESULTS_FILE_NAME="${RESULTS_FILE_NAME_BASE}-${TIMESTAMP}.txt"
RESULTS_FILE="${RESULTS_FOLDER}/${RESULTS_FILE_NAME}"
TIMESTAMPED_RESULTS_FOLDER_NAME="${RESULTS_FILE_NAME_BASE}-${TIMESTAMP}"
TIMESTAMPED_RESULTS_FOLDER="${RESULTS_FOLDER}/${TIMESTAMPED_RESULTS_FOLDER_NAME}"

if ! {
    LOCAL_EXIT_CODE=0
    echo
    echo "Running ${TEST_MODE_DESCRIPTION}"
    echo
    echo "    $(quoteArgs "${COMMAND[@]}")"
    echo
    echo "Output written to '${RESULTS_FILE}'"
    echo

    START="$(date +%s)"
    if ! "${COMMAND[@]}"; then
        LOCAL_EXIT_CODE=1
        echo "FAIL: Invocation of '${COMMAND[0]}' failed"
    fi
    END="$(date +%s)"
    DURATION=$(( END - START ))

    if [ "${TEST_MODE}" == "${TEST_MODE_GATLING}" ] || [ "${TEST_MODE}" == "${TEST_MODE_VERIFY_GATLING}" ] || [ "${TEST_MODE}" == "${TEST_MODE_KARATE}" ] || [ "${TEST_MODE}" == "${TEST_MODE_UNIT}" ]; then
        if [ -d "${CUCUMBER_HTML_FOLDER}" ] || [ -d "${GATLING_FOLDER}" ] || [ -d "${SUREFIRE_FOLDER}" ]; then
            mkdir -p "${TIMESTAMPED_RESULTS_FOLDER}"

            if [ "${TEST_MODE}" == "${TEST_MODE_KARATE}" ] || [ "${TEST_MODE}" == "${TEST_MODE_VERIFY_KARATE}" ] || [ "${TEST_MODE}" == "${TEST_MODE_GATLING}" ] || [ "${TEST_MODE}" == "${TEST_MODE_VERIFY_GATLING}" ]; then
                echo
                if [ -f "${OUTPUT_LOG_FILE}" ]; then
                    cp "${OUTPUT_LOG_FILE}" "${TIMESTAMPED_RESULTS_FOLDER}"
                    echo "Output log file saved to '${TIMESTAMPED_RESULTS_FOLDER}/$(basename "${OUTPUT_LOG_FILE}")'"
                else
                    echo "WARN: Output log file '${OUTPUT_LOG_FILE}' does not exist"
                fi  
            fi

            if [[ "${TEST_MODE}" == "${TEST_MODE_KARATE}" || "${TEST_MODE}" == "${TEST_MODE_VERIFY_KARATE}" ]] && [ "${HTML_REPORT}" -ne 0 ]; then
                echo
                if [ -d "${CUCUMBER_HTML_FOLDER}" ]; then
                    cp -r "${CUCUMBER_HTML_FOLDER}/" "${TIMESTAMPED_RESULTS_FOLDER}"
                    echo "HTML report saved to '${TIMESTAMPED_RESULTS_FOLDER}/$(basename "${CUCUMBER_HTML_FOLDER}")'"
                else
                    echo "WARN: HTML report folder '${CUCUMBER_HTML_FOLDER}' does not exist"
                fi
            fi

            if [ "${TEST_MODE}" != "${TEST_MODE_GATLING}" ] && [ "${TEST_MODE}" != "${TEST_MODE_VERIFY_GATLING}" ]; then
                echo
                if [ -d "${SUREFIRE_FOLDER}" ]; then
                    cp -r "${SUREFIRE_FOLDER}/" "${TIMESTAMPED_RESULTS_FOLDER}"
                    echo "Surefire results saved to '${TIMESTAMPED_RESULTS_FOLDER}/$(basename "${SUREFIRE_FOLDER}")'"
                else
                    echo "WARN: Surefire results folder '${SUREFIRE_FOLDER}' does not exist"
                fi
            fi

            if [ "${TEST_MODE}" == "${TEST_MODE_GATLING}" ] || [ "${TEST_MODE}" == "${TEST_MODE_VERIFY_GATLING}" ]; then
                echo
                if [ -d "${GATLING_FOLDER}" ]; then
                    cp -r "${GATLING_FOLDER}/" "${TIMESTAMPED_RESULTS_FOLDER}"
                    echo "Gatling results saved to '${TIMESTAMPED_RESULTS_FOLDER}/$(basename "${GATLING_FOLDER}")'"
                else
                    echo "WARN: Gatling results folder '${GATLING_FOLDER}' does not exist"
                fi
            fi

            if isUnix; then
                # Create link to latest results folder (relative within results folder)
                # NOTE: When linking directories, use -n so links to directories can be replaced
                # The -n option works on Mac OSX and Linux (Mac's -h does not)
                ln -f -s -n "${TIMESTAMPED_RESULTS_FOLDER_NAME}" "${HTML_RESULTS_LATEST_LINK}"
            fi
        fi
    fi

    if isUnix; then
        # Create link to latest results (relative within results folder)
        ln -f -s "./${RESULTS_FILE_NAME}" "${RESULTS_LATEST_LINK}"
    fi

    echo
    echo "Output saved to '${RESULTS_FILE}' (took $(formatDuration "${DURATION}"))"
    exit "${LOCAL_EXIT_CODE}"
} | tee "${RESULTS_FILE}"; then
    EXIT_CODE=1
fi

if [ "${TEST_MODE}" == "${TEST_MODE_KARATE}" ] || [ "${TEST_MODE}" == "${TEST_MODE_VERIFY_KARATE}" ]; then
    #
    # Show summary details displayed by Karate and exit with non-zero value if failures reported
    # NOTE #1: Multiple summaries can be present, if multiple test runners are specified
    # NOTE #2: Git Base for Windows does not like '\d' within extended grep expressions to match a digit - use '[0-9]' instead
    #
    if OUTPUT=$(grep --after-context=5 --extended-regexp -- '^Karate version: [0-9]+\.[0-9]+\.[0-9]+' "${RESULTS_FILE}"); then
        echo
        echo "${OUTPUT}"
        FAILURES_TOTAL=0
        while IFS='' read -r FAILURES; do
            #
            # NOTE: Git Base for Windows does not like either of the following statements:
            #
            #       (( FAILURES_TOTAL += FAILURES ))
            #       (( FAILURES_TOTAL = FAILURES_TOTAL + FAILURES ))
            #
            FAILURES_TOTAL=$(( FAILURES_TOTAL + FAILURES ))
        done < <(echo "${OUTPUT}" | grep --only-matching --extended-regexp -- 'failed:\s*[0-9]+' | grep --only-matching --extended-regexp -- '[0-9]+')

        if [ "${FAILURES_TOTAL}" -gt 0 ]; then
            echo
            echo "FAIL: Failures: ${FAILURES_TOTAL}"
            EXIT_CODE=1
        fi
    fi

    if [ "${HTML_REPORT}" -ne 0 ]; then
        HTML_REPORTS=()
        while IFS='' read -r HTML_REPORT; do
            HTML_REPORTS+=("${HTML_REPORT}");
        done < <(find "${TIMESTAMPED_RESULTS_FOLDER}" -name "overview-*.html" 2> /dev/null | sort)

        if [ "${#HTML_REPORTS[@]}" -gt 0 ]; then
            echo
            echo "HTML reports:"
            for HTML_REPORT in "${HTML_REPORTS[@]}"; do
                echo "  ${HTML_REPORT}"
            done
        else
            echo 'No HTML reports available!'
        fi
    fi
fi

if [ "${TEST_MODE}" == "${TEST_MODE_GATLING}" ] || [ "${TEST_MODE}" == "${TEST_MODE_VERIFY_GATLING}" ]; then
    #
    # Show list of Gatling HTML reports
    #
    HTML_REPORTS=()
    while IFS='' read -r HTML_REPORT; do
        HTML_REPORTS+=("${HTML_REPORT}");
    done < <(find "${TIMESTAMPED_RESULTS_FOLDER}" -name "index.html" 2> /dev/null | sort)

    if [ "${#HTML_REPORTS[@]}" -gt 0 ]; then
        echo
        echo "HTML reports:"
        for HTML_REPORT in "${HTML_REPORTS[@]}"; do
            echo "  ${HTML_REPORT}"
        done
    else
        echo 'No HTML reports available!'
    fi
fi

if [ "${EXIT_CODE}" -ne 0 ]; then
    echo
    echo "Exit code: ${EXIT_CODE}"
fi

echo
exit "${EXIT_CODE}"
