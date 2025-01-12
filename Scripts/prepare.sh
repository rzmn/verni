#!/usr/bin/env bash
set -ex

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
REPOSITORY_ROOT=$(cd "${SCRIPT_DIR}" && cd $(git rev-parse --show-toplevel) && pwd)

find "${SCRIPT_DIR}/../Packages" \
    -type f \
    -name "Package.swift" \
    -exec "${SCRIPT_DIR}/package_swift_autogen.sh" {} \;

OPENAPI_AUTOGEN_LINK="${SCRIPT_DIR}/../Packages/Data/Api/Interface/Api/Sources/openapi.yaml"
rm -f "${OPENAPI_AUTOGEN_LINK}"

ln -s \
    "${REPOSITORY_ROOT}/openapi.yaml" \
    "${OPENAPI_AUTOGEN_LINK}"
