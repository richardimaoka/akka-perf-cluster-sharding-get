#!/bin/bash
yum update -y
amazon-linux-extras install docker
service docker start
usermod -a -G docker ec2-user
yum -y install git
cd /home/ec2-user
git clone https://github.com/richardimaoka/akka-perf-cluster-sharding-get
cd akka-perf-cluster-sharding-get
docker build -f Dockerfile-backend  -t richard-perf-backend:latest  .
docker build -f Dockerfile-frontend -t richard-perf-frontend:latest .
docker build -f Dockerfile-datagen  -t richard-perf-datagen:latest  .
