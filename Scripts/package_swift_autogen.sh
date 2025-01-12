#!/usr/bin/env bash
set -ex

PACKAGE_FILE=${1}
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [ ! -f "${PACKAGE_FILE}" ]; then
    echo "file ${PACKAGE_FILE} not found"
    exit 1
fi

function depth {
    PATH="${1}"
    $(echo "${PATH}" | tr -cd '/' | wc -c)
}

PACKAGE_DIR=$( cd -- "$( dirname -- "${PACKAGE_FILE}" )" &> /dev/null && pwd )
LAYERS_DIR=$( cd "${SCRIPT_DIR}/../Packages" && pwd )

LAYERS_RELATIVE_TO_PACKAGE=""

while true; do
    if [ "$PACKAGE_DIR" = "$LAYERS_DIR" ];
    then
        break
    fi
    if [ "$PACKAGE_DIR" = "/" ];
    then
        break
    fi
    LAYERS_RELATIVE_TO_PACKAGE="${LAYERS_RELATIVE_TO_PACKAGE}../"
    PACKAGE_DIR=$( cd "${PACKAGE_DIR}/.." && pwd )
done

LAYERS_RELATIVE_TO_PACKAGE="${LAYERS_RELATIVE_TO_PACKAGE::-3}"

sed -i '' '/autogen_script_content/,$d' ${PACKAGE_FILE}
sed -i '' '/^$/d' ${PACKAGE_FILE}

TEMP_FILE=$(mktemp)
sed "s|CURRENT_LAYER_ROOT|${LAYERS_RELATIVE_TO_PACKAGE}|g" "${SCRIPT_DIR}/LocalPackages.swift" >> "${TEMP_FILE}"

echo "" >> "${PACKAGE_FILE}"
echo "// autogen_script_content (${BASH_SOURCE[0]}) start - do not modify" >> "${PACKAGE_FILE}"
cat "${TEMP_FILE}" >> "${PACKAGE_FILE}"
echo "// autogen_script_content (${BASH_SOURCE[0]}) end - do not modify" >> "${PACKAGE_FILE}"
