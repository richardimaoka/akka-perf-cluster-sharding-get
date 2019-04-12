#!/bin/bash

docker run \
  -e HOST_IPV4_ADDRESS="$(curl http://169.254.169.254/latest/meta-data/local-ipv4)" \
  -e AKKA_CLUSTER_SEED_NODES="10.0.0.5" \ # See https://github.com/lightbend/config/issues/163
  richard-perf-frontend:latest