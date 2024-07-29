set -e -x

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

mkdir -p ~/ydbd && cd ~/ydbd
curl https://install.ydb.tech | bash

./start.sh ram

CURRENT_DIR=$(pwd)
cd "${SCRIPT_DIR}"
go test -v .
cd "${CURRENT_DIR}"

./stop.sh
