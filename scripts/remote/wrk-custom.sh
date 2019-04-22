#!/bin/sh

if [ -n "$1" ]; then
  SEED_NODE_IPV4="$1"
else
  echo "The parameter = '$1' was empty but should be provided"
  exit 1
fi

# cd to the current directory as it runs other shell scripts
cd "$(dirname "$0")"

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

wrk -s "${pwd}/wrk_custom_request.lua" -t 2 -c 10 -d 30 "http://${SEED_NODE_IPV4}:8080" "$(pwd)/../../data/uuids.txt"