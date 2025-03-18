#!/usr/bin/env bash
set -ex

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

find "${SCRIPT_DIR}/../Packages" \
    -type f \
    -name "Package.swift" \
    -exec "${SCRIPT_DIR}/package_swift_autogen.sh" {} \;
