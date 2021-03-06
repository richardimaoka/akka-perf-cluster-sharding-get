#!/bin/sh

if [ -n "$1" ]; then
  AKKA_HTTP_NODE="$1"
else
  echo "The parameter = '$1' was empty but should be provided"
  exit 1
fi

# cd to the current directory as it runs other shell scripts
cd "$(dirname "$0")"

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

docker run richard-perf-wrk:latest \
  -t 2 -c 10 -d 30 \
  "http://${AKKA_HTTP_NODE}:8080" \
  "$(pwd)/../../data/uuids.txt"
