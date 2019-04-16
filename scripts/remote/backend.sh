#!/bin/sh

if [ -n "$1" ]; then
  SEED_NODE_IPV4="$1"
else
  echo "The parameter = '$1' was empty but should be provided"
  exit 1
fi

# See https://github.com/lightbend/config/issues/163
# also, --host to make EC2 IP Address same as Container's IP address
docker run \
  -e HOST_IPV4_ADDRESS="$(curl http://169.254.169.254/latest/meta-data/local-ipv4)" \
  -e AKKA_CLUSTER_SEED_NODE_IPV4="${SEED_NODE_IPV4}" \
  -e AKKA_CLUSTER_SEED_NODE_PORT="2551" \
  -e HOST_AKKA_REMOTING_PORT="2551" \
  --network host \
  -d richard-perf-backend:latest