#!/bin/sh

# cd to the current directory as it runs other shell scripts
cd "$(dirname "$0")"

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

# Create a Cloudformation stack from the local template `cloudformation-vpc.yaml`
VPC_STACK_NAME="bench-vpc"
SSH_LOCATION="$(curl ifconfig.co 2> /dev/null)/32"

echo "Creating the VPC"
aws cloudformation create-stack \
  --stack-name "${VPC_STACK_NAME}" \
  --template-body file://../../cloudformation-vpc.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters ParameterKey=SSHLocation,ParameterValue="${SSH_LOCATION}"

aws cloudformation wait stack-create-complete --stack-name "${VPC_STACK_NAME}"

