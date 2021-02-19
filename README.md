# prometheus-alerts

[![Build Status](https://drone.osshelp.ru/api/badges/drone/drone-prometheus-alerts/status.svg?ref=refs/heads/master)](https://drone.osshelp.ru/drone/drone-prometheus-alerts)

## About

Docker image for testing alerting and recording rules in Prometheus.

## Settings

| Param | Default | Description |
| -------- | -------- | -------- |
| `alertrules_dir` | `alerts` | Directory with alertrules files |
| `alertrules_files` | `""` | If empty string files will be searched in the `alertrules_dir` |
| `alertrules_tests_dir` | `tests` | Directory with tests |
| `alertrules_tests` | `""` | If empty string files will be searched in the `alertrules_tests_dir` |
| `exclude_regex` | `^NO_EXCLUDE_FILES\$` | Regular expression to exclude files from checking and testing|
| `verbose` | `false` | Show verbose output, including promtool results |

## Usage examples

### Find and lint files automatically

``` yaml
steps:
  - name: check and test alertrules
    image: osshelp/drone-prometheus-alerts
```

### Specific files to check and specific tests

``` yaml
steps:
  - name: check and test alertrules
    image: osshelp/drone-prometheus-alerts
    settings:
      alertrules_files:
        - alerts/file1.yml
        - alerts/file2.yml
      alertrules_tests:
        - tests/test1.yml
```

### Exclude files by exclude_regex

``` yaml
steps:
  - name: check and test alertrules
    image: osshelp/drone-prometheus-alerts
    settings:
      exclude_regex: '(regex1|regex2)'
```

### Internal usage

For internal purposes and OSSHelp customers we have an alternative image url:

``` yaml
  image: oss.help/drone/prometheus-alerts
```

There is no difference between the DockerHub image and the oss.help/drone image.

## FAQ

### Why it fails with alerts without tests?

Using alerting rules without corresponding testing is considered a very bad idea. One day you can break your alerting without even noticing it. The consequences you can imagine by yourself. So, read the [official docs on promtool](https://prometheus.io/docs/prometheus/latest/configuration/unit_testing_rules/) and add tests for your alerting rules.

## Links

- [Prometheus documentation](https://prometheus.io/docs/prometheus/latest/configuration/unit_testing_rules/)

## TODO

...
