#!/bin/bash

# cd to the current directory as it runs other shell scripts
cd "$(dirname "$0")"

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

# Create a Cloudformation stack from the local template `cloudformation-vpc.yaml`
VPC_STACK_NAME="bench-vpc"
SSH_LOCATION="$(curl ifconfig.co 2> /dev/null)/32"
INSTANCE_TYPE="t2.micro"

aws cloudformation create-stack \
  --stack-name "${VPC_STACK_NAME}" \
  --template-body file://cloudformation-vpc.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters ParameterKey=SSHLocation,ParameterValue="${SSH_LOCATION}"

echo "Waiting until the Cloudformation stack is CREATE_COMPLETE"
aws cloudformation wait stack-create-complete --stack-name "${VPC_STACK_NAME}"

# Variables to be passed upon EC2 creation in the next step
DESCRIBED=$(aws cloudformation describe-stacks --stack-name "${VPC_STACK_NAME}")
SUBNET=$(echo $DESCRIBED | jq -c '.Stacks[0].Outputs[] | select(.OutputKey == "Subnet") | .OutputValue')
SECURITY_GROUP=$(echo $DESCRIBED | jq -c '.Stacks[0].Outputs[] | select(.OutputKey == "SecurityGroup") | .OutputValue')
IAM_INSTANCEPROFILE_SSM=$(echo $DESCRIBED | jq -c '.Stacks[0].Outputs[] | select(.OutputKey == "InstanceProfile") | .OutputValue')

# Create EC2 instances. Since CloudFormation doesn't support creation of a variable number of EC2 instances,
# you need to create the instances via CLI.
# If you are using a command line tool, base64-encoding is performed for you, and you can load the text from a file., https://docs.aws.amazon.com/cli/latest/reference/ec2/run-instances.html
aws ec2 run-instances \
  --image-id "ami-0d7ed3ddb85b521a6" \
  --instance-type "${INSTANCE_TYPE}" \
  --key-name "demo-key-pair" \
  --iam-instance-profile "Name=${IAM_INSTANCEPROFILE_SSM}" \
  --user-data "file://user-data.sh" \
  --network-interfaces "AssociatePublicIpAddress=true,DeviceIndex=0,PrivateIpAddress=10.0.0.5,Groups=${SECURITY_GROUP},SubnetId=${SUBNET}" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=role,Value=frontend}]"

#aws ec2 run-instances \
#  --image-id "ami-0d7ed3ddb85b521a6" \
#  --instance-type "${INSTANCE_TYPE}" \
#  --key-name "demo-key-pair" \
#  --iam-instance-profile "Name=${IAM_INSTANCEPROFILE_SSM}" \
#  --user-data "file://user-data.sh" \
#  --network-interfaces "AssociatePublicIpAddress=true,DeviceIndex=0,PrivateIpAddress=10.0.0.5,Groups=${SECURITY_GROUP},SubnetId=${SUBNET}" \
#  --tag-specifications "ResourceType=instance,Tags=[{Key=role,Value=backend}]"

#aws ec2 run-instances \
#  --image-id "ami-0d7ed3ddb85b521a6" \
#  --instance-type "${INSTANCE_TYPE}" \
#  --key-name "demo-key-pair" \
#  --iam-instance-profile "Name=${IAM_INSTANCEPROFILE_SSM}" \
#  --user-data "file://user-data.sh" \
#  --network-interfaces "AssociatePublicIpAddress=true,DeviceIndex=0,PrivateIpAddress=10.0.0.5,Groups=${SECURITY_GROUP},SubnetId=${SUBNET}" \
#  --tag-specifications "ResourceType=instance,Tags=[{Key=role,Value=wrk}]"
