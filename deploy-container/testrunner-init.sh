#!/usr/bin/env bash

set -euo pipefail

dnf install -y --nogpgcheck osbuild-composer-tests

/usr/libexec/tests/osbuild-composer/base_tests.sh
