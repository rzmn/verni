#!/usr/bin/env bash
set -e -x

USAGE="DocC generation tool
usage:
./build_spm.sh <PACKAGE_PATH>"

if [ -z "$1" ]; then
	echo 'No package path passed'
	echo "${USAGE}"
	exit 1
fi

CURRENT_DIR=$(pwd)
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PACKAGE_DIR=$(cd "${CURRENT_DIR}" && cd "$1" && pwd)
FRAMEWORK=$(basename "${PACKAGE_DIR}")

DOCC_DIR="${SCRIPT_DIR}/DocC"
BUILD_DIR="${SCRIPT_DIR}/_build_DocC"

rm -rf "${DOCC_DIR}"
mkdir -p "${DOCC_DIR}"

cd "${PACKAGE_DIR}"

xcodebuild docbuild \
	-scheme "${FRAMEWORK}" \
	-destination 'generic/platform=iOS' \
	-configuration 'Release' \
	-derivedDataPath "${BUILD_DIR}"

find "${BUILD_DIR}" -type d -name "${FRAMEWORK}.doccarchive" -exec cp -r {} "${DOCC_DIR}" \;
rm -rf "${BUILD_DIR}"
