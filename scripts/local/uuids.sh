#!/bin/sh

if [ -n "$1" ]; then
  NUM_UUIDS="$1"
else
  echo "The parameter = '$1' must be provided"
  exit 1
fi

# cd to the current directory as it runs other shell scripts
cd "$(dirname "$0")" || exit

# Populate the uuids.json file
echo "[" > ../../data/uuids.json

for i in $(seq 1 "$NUM_UUIDS")
do
  if [ "$i" -lt "$NUM_UUIDS" ]; then
    echo "\"$(uuidgen)\"," >> ../../data/uuids.json
  else
    echo "\"$(uuidgen)\"" >> ../../data/uuids.json
  fi
done

echo "]" >> ../../data/uuids.json
