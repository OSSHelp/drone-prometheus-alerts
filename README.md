# prometheus-alerts

[![Build Status](https://drone.osshelp.ru/api/badges/drone/drone-prometheus-alerts/status.svg?ref=refs/heads/master)](https://drone.osshelp.ru/drone/drone-prometheus-alerts)

## About

Docker image for testing alerting and recording rules in Prometheus.

## Settings

| Param | Default | Description |
| -------- | -------- | -------- |
| `alertrules_dir` | `alerts` | Directory with alerting rules files |
| `alertrules_files` | `""` | If empty string files will be searched in the `alertrules_dir` |
| `recordingrules_dir` | `rules` | Directory with recording rules files |
| `recordingrules_files` | `""` | If empty string files will be searched in the `recordingrules_dir` |
| `alertrules_tests_dir` | `tests` | Directory with tests |
| `alertrules_tests` | `""` | If empty string files will be searched in the `alertrules_tests_dir` |
| `scrapetargets_dir` | `tests` | Directory with scrape targets |
| `scrapetargets_files` | `""` | If empty string files will be searched in the `scrapetargets_dir` |
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

### Why do you create temporary prometheus.yml?

There are some scenarios where testing standalone alerting and/or recording rules isn't enough. So, we decided to render temporary prometheus.yml based on the default one from official releases. All found rules and targets are injected into this prometheus.yml, then it's validated by `promtool check config prometheus.yml`. Just another layer of protection from unusual mistakes.

## Links

- [Prometheus documentation](https://prometheus.io/docs/prometheus/latest/configuration/unit_testing_rules/)

## TODO

...
