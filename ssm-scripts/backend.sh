#!/bin/bash

docker run \
  -e HOST_IPV4_ADDRESS="$(curl http://169.254.169.254/latest/meta-data/local-ipv4)" \
  -e AKKA_CLUSTER_SEED_NODE_IPV4="10.0.0.5" \ # See https://github.com/lightbend/config/issues/163
  --network host # to make EC2 IP Address same as Container's IP address
  -d richard-perf-backend:latest