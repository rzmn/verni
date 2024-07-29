set -e -x

echo $YDB_ADMIN_KEYS_JSON >> ./ydbStorage/key.json
go test -v .

