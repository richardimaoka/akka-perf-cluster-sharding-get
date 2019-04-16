#!/bin/sh

if [ "$1" = "" ]; then
  CURRENT_DIR=$(dirname "$0")
  EC2_SETTINGS=$(cat "$CURRENT_DIR"/ec2-instances.json)
elif [ -f "$1" ]; then
  EC2_SETTINGS=$(cat "$1")
else
  echo "The parameter = '$1' is not a file"
  exit 1
fi

# cd to the current directory as it runs other shell scripts
cd "$(dirname "$0")"

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

# Create a Cloudformation stack from the local template `cloudformation-vpc.yaml`
VPC_STACK_NAME="bench-vpc"
SSH_LOCATION="$(curl ifconfig.co 2> /dev/null)/32"
EXEC_UUID=$(uuidgen)

echo "Creating the VPC"
# aws cloudformation create-stack \
#   --stack-name "${VPC_STACK_NAME}" \
#   --template-body file://cloudformation-vpc.yaml \
#   --capabilities CAPABILITY_NAMED_IAM \
#   --parameters ParameterKey=SSHLocation,ParameterValue="${SSH_LOCATION}"

aws cloudformation wait stack-create-complete --stack-name "${VPC_STACK_NAME}"

# Variables to be passed upon EC2 creation in the next step
DESCRIBED=$(aws cloudformation describe-stacks --stack-name "${VPC_STACK_NAME}")
SECURITY_GROUP=$(echo "${DESCRIBED}" | jq -c '.Stacks[0].Outputs[] | select(.OutputKey == "SecurityGroup") | .OutputValue')
IAM_INSTANCE_PROFILE_SSM=$(echo "${DESCRIBED}" | jq -c '.Stacks[0].Outputs[] | select(.OutputKey == "InstanceProfile") | .OutputValue')

# Create EC2 instances. Since CloudFormation doesn't support creation of a variable number of EC2 instances,
# you need to create the instances via CLI.
echo "Creating the WRK EC2 instance"
WRK_INSTANCE_SETTINGS=$(echo "$EC2_SETTINGS" | jq -c '.wrk_instance')
WRK_INSTANCE_TYPE=$(echo "$WRK_INSTANCE_SETTINGS" | jq -r '.instance_type')
WRK_INSTANCE_IP_ADDRESS_V4=$(echo "$WRK_INSTANCE_SETTINGS" | jq -r '.ip_address_v4')
WRK_INSTANCE_SUBNET=$(echo "$WRK_INSTANCE_SETTINGS" | jq -c '.subnet')
WRK_INSTANCE_SUBNET_ID=$(echo "${DESCRIBED}" | jq -c ".Stacks[0].Outputs[] | select(.OutputKey == $WRK_INSTANCE_SUBNET) | .OutputValue")
# If you are using a command line tool, base64-encoding is performed for you, and you can load the text from a file., https://docs.aws.amazon.com/cli/latest/reference/ec2/run-instances.html
aws ec2 run-instances \
  --image-id "ami-0d7ed3ddb85b521a6" \
  --instance-type "${WRK_INSTANCE_TYPE}" \
  --key-name "demo-key-pair" \
  --iam-instance-profile "Name=${IAM_INSTANCE_PROFILE_SSM}" \
  --user-data "file://user-data.sh" \
  --network-interfaces "AssociatePublicIpAddress=true,DeviceIndex=0,PrivateIpAddress=${WRK_INSTANCE_IP_ADDRESS_V4},Groups=${SECURITY_GROUP},SubnetId=${WRK_INSTANCE_SUBNET_ID}" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=wrk},{Key=role,Value=wrk},{Key=exec-id,Value=${EXEC_UUID}}]"

echo "Creating the Akka backend EC2 instances"
for AKKA_BACKEND_SETTINGS in $(echo "$EC2_SETTINGS" | jq -c '.akka_backend_instances[]')
do
  AKKA_BACKEND_INSTANCE_TYPE=$(echo "$AKKA_BACKEND_SETTINGS" | jq -r '.instance_type')
  AKKA_BACKEND_INSTANCE_IP_ADDRESS_V4=$(echo "$AKKA_BACKEND_SETTINGS" | jq -r '.ip_address_v4')
  AKKA_BACKEND_INSTANCE_SUBNET=$(echo "$AKKA_BACKEND_SETTINGS" | jq -c '.subnet')
  AKKA_BACKEND_INSTANCE_SUBNET_ID=$(echo "${DESCRIBED}" | jq -c ".Stacks[0].Outputs[] | select(.OutputKey == $AKKA_BACKEND_INSTANCE_SUBNET) | .OutputValue")
  # If you are using a command line tool, base64-encoding is performed for you, and you can load the text from a file., https://docs.aws.amazon.com/cli/latest/reference/ec2/run-instances.html
  aws ec2 run-instances \
    --image-id "ami-0d7ed3ddb85b521a6" \
    --instance-type "${AKKA_BACKEND_INSTANCE_TYPE}" \
    --key-name "demo-key-pair" \
    --iam-instance-profile "Name=${IAM_INSTANCE_PROFILE_SSM}" \
    --user-data "file://user-data.sh" \
    --network-interfaces "AssociatePublicIpAddress=true,DeviceIndex=0,PrivateIpAddress=${AKKA_BACKEND_INSTANCE_IP_ADDRESS_V4},Groups=${SECURITY_GROUP},SubnetId=${AKKA_BACKEND_INSTANCE_SUBNET_ID}" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=akka-backend-${AKKA_BACKEND_INSTANCE_IP_ADDRESS_V4}},{Key=role,Value=backend},{Key=exec-id,Value=${EXEC_UUID}}]"
done

echo "Creating the Akka http EC2 instances"
for AKKA_FRONTEND_SETTINGS in $(echo "$EC2_SETTINGS" | jq -c '.akka_frontend_instances[]')
do
  AKKA_FRONTEND_INSTANCE_TYPE=$(echo "$AKKA_FRONTEND_SETTINGS" | jq -r '.instance_type')
  AKKA_FRONTEND_INSTANCE_IP_ADDRESS_V4=$(echo "$AKKA_FRONTEND_SETTINGS" | jq -r '.ip_address_v4')
  AKKA_FRONTEND_INSTANCE_SUBNET=$(echo "$AKKA_FRONTEND_SETTINGS" | jq -c '.subnet')
  AKKA_FRONTEND_INSTANCE_SUBNET_ID=$(echo "${DESCRIBED}" | jq -c ".Stacks[0].Outputs[] | select(.OutputKey == $AKKA_FRONTEND_INSTANCE_SUBNET) | .OutputValue")
  # If you are using a command line tool, base64-encoding is performed for you, and you can load the text from a file., https://docs.aws.amazon.com/cli/latest/reference/ec2/run-instances.html
  aws ec2 run-instances \
    --image-id "ami-0d7ed3ddb85b521a6" \
    --instance-type "${AKKA_FRONTEND_INSTANCE_TYPE}"  \
    --key-name "demo-key-pair" \
    --iam-instance-profile "Name=${IAM_INSTANCE_PROFILE_SSM}" \
    --user-data "file://user-data.sh" \
    --network-interfaces "AssociatePublicIpAddress=true,DeviceIndex=0,PrivateIpAddress=${AKKA_FRONTEND_INSTANCE_IP_ADDRESS_V4},Groups=${SECURITY_GROUP},SubnetId=${AKKA_FRONTEND_INSTANCE_SUBNET_ID}" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=akka-frontend-${AKKA_FRONTEND_INSTANCE_IP_ADDRESS_V4}},{Key=role,Value=frontend},{Key=exec-id,Value=${EXEC_UUID}}]"
done