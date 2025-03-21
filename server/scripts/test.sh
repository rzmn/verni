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

OPENAPI_DIR="${SCRIPT_DIR}/../internal/openapi"
go test -v -coverpkg=./... -coverprofile=profile.cov -ignore="${OPENAPI_DIR}/*" ./...
COVERAGE=$(go tool cover -func profile.cov | tail -n 1 | awk '{print $3}')
echo "📈 Total Coverage: ${COVERAGE}"

curl --location --request PUT 'https://api.jsonbin.io/v3/b/67dd1f9c8960c979a575ac87' \
    --header "X-Master-Key: ${JSONBINS_KEY}" \
    --header "Content-Type: application/json" \
    --data "{\"coverage\":\"total: ${COVERAGE}\"}"