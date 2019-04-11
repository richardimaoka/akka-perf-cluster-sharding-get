#!/bin/bash
yum update -y
amazon-linux-extras install docker
service docker start
usermod -a -G docker ec2-user
yum -y install git
cd /home/ec2-user
git clone https://github.com/richardimaoka/akka-cluster-sharding-perf
cd akka-cluster-sharding-perf
docker build .