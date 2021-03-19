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


function test_main_config() {
  local temp_cfg="${DRONE_WORKSPACE_BASE:-/tmp}/prometheus.yml"
  local source_cfg="${PROMETHEUS_CFG:-/etc/prometheus/prometheus.yml}"

  test -r "${source_cfg}" || show_error "Can't find default Prometheus config at ${source_cfg}"
  show_notice "Creating temporary prometheus.yml"
  cp "${source_cfg}" "${temp_cfg}"

  test -n "${alerting_rules_files}" && {
    for target_file in ${alerting_rules_files//,/ }; do
      show_notice "Injecting ${target_file} into alerting rules"
      yq w -i "${temp_cfg}" "rule_files[+]" "${target_file}"
    done
  }

  test -n "${recording_rules_files}" && {
    for target_file in ${recording_rules_files//,/ }; do
      show_notice "Injecting ${target_file} into recording rules"
      yq w -i "${temp_cfg}" "rule_files[+]" "${target_file}"
    done
  }

  test -n "${scrape_targets_files}" && {
    for target_file in ${scrape_targets_files//,/ }; do
      show_notice "Injecting ${target_file} into scrape targets"
      yq w -i "${temp_cfg}" scrape_configs[0].file_sd_configs[0].files[+] "${target_file}"
    done
  }

  test "${verbose}" != "false" && {
    show_notice "Resulting prometheus.yml:"
    yq r "${temp_cfg}"
  }

  test_output=$(promtool check config "${temp_cfg}" 2>&1)
  test_result=${?}

  test "${test_result}" -eq 0 && \
    show_notice "Validating resulting prometheus.yml - \e[32mOK\e[39m"
    test "${verbose}" != "false" && echo "${test_output}"

  test "${test_result}" -ne 0 && {
    show_warning "Validating resulting prometheus.yml - \e[33mFAIL\e[39m"
    echo "${test_output}"
    errors_found=1
  }

  # delete temp file
  test -r "${temp_cfg}" && rm "${temp_cfg}"

}


function check_and_set_vars() {
  show_notice "Preparing variables for the build"

  alerting_rules_dir="alerts"
  alerting_rules_files=""
  alerting_tests_dir="tests"
  alerting_rules_tests=""
  recording_rules_dir="rules"
  recording_rules_files=""
  scrape_targets_dir="targets"
  scrape_targets_files=""
  exclude_regex="^NO_EXCLUDE_FILES\$"
  verbose=false

  for var in "${!PLUGIN_@}"; do
    case "${var}" in
      PLUGIN_ALERTRULES_DIR)       alerting_rules_dir="${PLUGIN_ALERTRULES_DIR}" ;;
      PLUGIN_ALERTRULES_FILES)     alerting_rules_files="${PLUGIN_ALERTRULES_FILES}" ;;
      PLUGIN_ALERTRULES_TESTS_DIR) alerting_tests_dir="${PLUGIN_ALERTRULES_TESTS_DIR}" ;;
      PLUGIN_ALERTRULES_TESTS)     alerting_rules_tests="${PLUGIN_ALERTRULES_TESTS}" ;;
      PLUGIN_RECORDINGRULES_DIR)   recording_rules_dir="${PLUGIN_RECORDINGRULES_DIR}" ;;
      PLUGIN_RECORDINGRULES_FILES) recording_rules_files="${PLUGIN_RECORDINGRULES_FILES}" ;;
      PLUGIN_SCRAPETARGETS_DIR)   scrape_targets_dir="${PLUGIN_SCRAPETARGETS_DIR}" ;;
      PLUGIN_SCRAPETARGETS_FILES) scrape_targets_files="${PLUGIN_SCRAPETARGETS_FILES}" ;;
      PLUGIN_EXCLUDE_REGEX)        exclude_regex="${PLUGIN_EXCLUDE_REGEX}" ;;
      PLUGIN_VERBOSE)              verbose="${PLUGIN_VERBOSE}" ;;
      PLUGIN_DEBUG)                : ;; # to avoid warning below
      PLUGIN_*) show_warning "Setting $(echo "${var#PLUGIN_}" | tr '[:upper:]' '[:lower:]') does not exist. Will do nothing." ;;
    esac
  done
}

check_and_set_vars
test -z "${alerting_rules_files}" && alerting_rules_files=$(find_files "${alerting_rules_dir}")
test -z "${recording_rules_files}" && recording_rules_files=$(find_files "${recording_rules_dir}")
test -z "${alerting_rules_tests}" && alerting_rules_tests=$(find_files "${alerting_tests_dir}")
test -z "${scrape_targets_files}" && scrape_targets_files=$(find_files "${scrape_targets_dir}")

test -n "${alerting_rules_files}" -a -z "${alerting_rules_tests}" && show_error "Found some rules, but no tests. Aborting"

check_rules "${alerting_rules_files}"
test_rules "${alerting_rules_tests}"
test_main_config

exit ${errors_found}
