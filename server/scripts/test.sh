#!/usr/bin/env bash
set -ex

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cd "${SCRIPT_DIR}/.."
export VERNI_PROJECT_ROOT=$(pwd)
mkdir -p ./config/test/
echo '{"host":"localhost","port":5432,"user":"root","password":"verni_pwd","dbName":"verni_test_db"}' > ./config/test/postgres_storage.json
cd cmd/utilities
go build .
./utilities --command create-tables --config-path ./config/test/postgres_storage.json
cd "${SCRIPT_DIR}/.."
go test ./...
