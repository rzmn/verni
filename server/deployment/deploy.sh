#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cd "${SCRIPT_DIR}/.."

docker build . \
	--tag nrzmn.cr.cloud.ru/sharedexpenses \
	--platform linux/amd64

docker push "nrzmn.cr.cloud.ru/sharedexpenses"