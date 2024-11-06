#!/bin/sh

prog=$(basename "$0")
if ! [ -S /var/run/docker.sock ]
then
	echo "$prog: there are no running docker" >&2
	exit 2
fi

cd "$(dirname "$0")" || exit
PATH=$(pwd):$PATH
plugin=$(basename "$(pwd)")
if ! which "$plugin" >/dev/null
then
	echo "$prog: $plugin is not installed" >&2
	exit 2
fi

password=passpass
port=16379
image=redis:5

RET=$($plugin reachable --port $port --password $password)
# check-redis should return CRITICAL (exit code 2) when the server is unreachable
if [ $? -ne 2 ]; then
	echo "$prog: $plugin returned $? (2 is expected)" >&2
	exit 2
fi
echo "$RET"

docker run --name "test-$plugin" -p "$port:6379" -d "$image" --requirepass "$password"
trap 'docker stop test-$plugin; docker rm test-$plugin; exit' EXIT
sleep 10

exec $plugin reachable --port $port --password $password
