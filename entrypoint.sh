#!/bin/bash
# shellcheck disable=SC2015

[ "${PLUGIN_DEBUG}" = "true" ] && { set -x; env; }

errors_found=0

function show_notice()  { echo -e "\e[34m[NOTICE. $(date '+%Y/%m/%d-%H:%M:%S')]\e[39m ${1}"; }
function show_warning() { echo -e "\e[33m[WARNING. $(date '+%Y/%m/%d-%H:%M:%S')]\e[39m ${1}" >&2; }
function show_error()   { echo -e "\e[31m[ERROR. $(date '+%Y/%m/%d-%H:%M:%S')]\e[39m ${1}" >&2; exit 1; }

function find_files() {
  local target_dir=$1
  test -d "${target_dir}" && \
    find "${target_dir}" -name '*.yml' 2>/dev/null | grep -vE "$exclude_regex"
}

function check_rules() {
  local files="${1}"
  for target_file in ${files//,/ }; do
    check_output=$(promtool check rules "${target_file}" 2>&1)
    check_result=${?}
    test ${check_result} -eq 0 && \
      show_notice "Validating rules in ${target_file} - \e[32mOK\e[39m"
    test ${check_result} -ne 0 && {
      show_warning "Validating rules in ${target_file} - \e[33mFAIL\e[39m"
      errors_found=1
    }
    test "${verbose}" != "false" -o ${check_result} -ne 0 && \
      echo "${check_output}"
  done
}

function test_rules() {
  local files="${1}"
  for target_file in ${files//,/ }; do
      test_output=$(promtool test rules "${target_file}" 2>&1)
      test_result=${?}
      test "${test_result}" -eq 0 && \
        show_notice "Testing rules in ${target_file} - \e[32mOK\e[39m"
      test "${test_result}" -ne 0 && {
        show_warning "Testing rules in ${target_file} - \e[33mFAIL\e[39m"
        errors_found=1
      }
    test "${verbose}" != "false" -o ${test_result} -ne 0 && \
      echo "${test_output}"
  done
}

function check_and_set_vars() {
  show_notice "Preparing variables for the build"

  alerting_rules_dir="alerts"
  alerting_rules_files=""
  alerting_tests_dir="tests"
  alerting_rules_tests=""
  exclude_regex="^NO_EXCLUDE_FILES\$"
  verbose=false

  for var in "${!PLUGIN_@}"; do
    case "${var}" in
      PLUGIN_ALERTRULES_DIR)       alerting_rules_dir="${PLUGIN_ALERTRULES_DIR}" ;;
      PLUGIN_ALERTRULES_FILES)     alerting_rules_files="${PLUGIN_ALERTRULES_FILES}" ;;
      PLUGIN_ALERTRULES_TESTS_DIR) alerting_tests_dir="${PLUGIN_ALERTRULES_TESTS_DIR}" ;;
      PLUGIN_ALERTRULES_TESTS)     alerting_rules_tests="${PLUGIN_ALERTRULES_TESTS}" ;;
      PLUGIN_EXCLUDE_REGEX)        exclude_regex="${PLUGIN_EXCLUDE_REGEX}" ;;
      PLUGIN_VERBOSE)              verbose="${PLUGIN_VERBOSE}" ;;
      PLUGIN_DEBUG)                : ;; # to avoid warning below
      PLUGIN_*) show_warning "Setting $(echo "${var#PLUGIN_}" | tr '[:upper:]' '[:lower:]') does not exist. Will do nothing." ;;
    esac
  done
}

check_and_set_vars
test -z "${alerting_rules_files}" && alerting_rules_files=$(find_files "${alerting_rules_dir}")
test -z "${alerting_rules_tests}" && alerting_rules_tests=$(find_files "${alerting_tests_dir}")

test -n "${alerting_rules_files}" -a -z "${alerting_rules_tests}" && show_error "Found some rules, but no tests. Aborting"

check_rules "${alerting_rules_files}"
test_rules "${alerting_rules_tests}"

exit ${errors_found}
