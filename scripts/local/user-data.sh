#!/bin/bash
yum update -y
amazon-linux-extras install docker
service docker start
usermod -a -G docker ec2-user

yum -y install git
cd /home/ec2-user
git clone https://github.com/richardimaoka/akka-perf-cluster-sharding-get
cd akka-perf-cluster-sharding-get

docker build -f Dockerfile-seed -t richard-perf-seed:latest  .
docker build -f Dockerfile-backend  -t richard-perf-backend:latest  .
docker build -f Dockerfile-http -t richard-perf-http:latest .
docker build -f Dockerfile-wrk -t richard-perf-wrk:latest .
docker build -f Dockerfile-create-sharding-actors -t richard-perf-create-sharding-actors:latest .

docker images