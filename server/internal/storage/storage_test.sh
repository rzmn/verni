set -e -x

mkdir -p ~/ydbd && cd ~/ydbd
curl https://install.ydb.tech | bash

./start.sh ram &
go test -v .
