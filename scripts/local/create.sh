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


CMD="aws cloudformation create-stack" \
  "--stack-name ${VPC_STACK_NAME}" \
  "--template-body file://cloudformation-vpc.yaml" \
  "--capabilities CAPABILITY_NAMED_IAM" \
  "--parameters ParameterKey=SSHLocation,ParameterValue=${SSH_LOCATION}"
echo "running:\n${CMD}"

aws cloudformation create-stack \
  --stack-name "${VPC_STACK_NAME}" \
  --template-body file://cloudformation-vpc.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters ParameterKey=SSHLocation,ParameterValue="${SSH_LOCATION}"

echo "Waiting until the Cloudformation stack is CREATE_COMPLETE"
aws cloudformation wait stack-create-complete --stack-name "${VPC_STACK_NAME}"

# Variables to be passed upon EC2 creation in the next step
DESCRIBED=$(aws cloudformation describe-stacks --stack-name "${VPC_STACK_NAME}")
SECURITY_GROUP=$("${DESCRIBED}" | jq -c '.Stacks[0].Outputs[] | select(.OutputKey == "SecurityGroup") | .OutputValue')
IAM_INSTANCE_PROFILE_SSM=$("${DESCRIBED}" | jq -c '.Stacks[0].Outputs[] | select(.OutputKey == "InstanceProfile") | .OutputValue')

# Create EC2 instances. Since CloudFormation doesn't support creation of a variable number of EC2 instances,
# you need to create the instances via CLI.
WRK_INSTANCE_SETTINGS=$(jq -c '.wrk_instance' "$EC2_SETTINGS")
WRK_INSTANCE_TYPE=$(jq -c '.instance_type' "$WRK_INSTANCE_SETTINGS")
WRK_INSTANCE_IP_ADDRESS_V4=$(jq -c '.ip_address_v4' "$WRK_INSTANCE_SETTINGS")
WRK_INSTANCE_SUBNET=$(jq -c '.subnet' "$WRK_INSTANCE_SETTINGS")
WRK_INSTANCE_SUBNET_ID=$("${DESCRIBED}" | jq -c ".Stacks[0].Outputs[] | select(.OutputKey == ${WRK_INSTANCE_SUBNET}) | .OutputValue")
# If you are using a command line tool, base64-encoding is performed for you, and you can load the text from a file., https://docs.aws.amazon.com/cli/latest/reference/ec2/run-instances.html
aws ec2 run-instances \
  --image-id "ami-0d7ed3ddb85b521a6" \
  --instance-type "${WRK_INSTANCE_TYPE}" \
  --key-name "demo-key-pair" \
  --iam-instance-profile "Name=${IAM_INSTANCE_PROFILE_SSM}" \
  - -user-data "file://user-data.sh" \
  --network-interfaces "AssociatePublicIpAddress=true,DeviceIndex=0,PrivateIpAddress=${WRK_INSTANCE_IP_ADDRESS_V4},Groups=${SECURITY_GROUP},SubnetId=${WRK_INSTANCE_SUBNET_ID}" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=role,Value=wrk}]"

for AKKA_BACKEND_SETTINGS in $(jq -c '.akka_backend_instances' "$EC2_SETTINGS")
do
  AKKA_BACKEND_INSTANCE_TYPE=$(jq -c '.instance_type' "$AKKA_BACKEND_SETTINGS")
  AKKA_BACKEND_INSTANCE_IP_ADDRESS_V4=$(jq -c '.ip_address_v4' "$AKKA_BACKEND_SETTINGS")
  AKKA_BACKEND_INSTANCE_SUBNET=$(jq -c '.subnet' "$AKKA_BACKEND_SETTINGS")
  AKKA_BACKEND_INSTANCE_SUBNET_ID=$("${DESCRIBED}"  | jq -c ".Stacks[0].Outputs[] | select(.OutputKey == ${AKKA_BACKEND_INSTANCE_SUBNET}) | .OutputValue")
  # If you are using a command line tool, base64-encoding is performed for you, and you can load the text from a file., https://docs.aws.amazon.com/cli/latest/reference/ec2/run-instances.html
  aws ec2 run-instances \
    --image-id "ami-0d7ed3ddb85b521a6" \
    --instance-type "${AKKA_BACKEND_INSTANCE_TYPE}" \
    --key-name "demo-key-pair" \
    --iam-instance-profile "Name=${IAM_INSTANCE_PROFILE_SSM}" \
    --user-data "file://user-data.sh" \
    --network-interfaces "AssociatePublicIpAddress=true,DeviceIndex=0,PrivateIpAddress=${AKKA_BACKEND_INSTANCE_IP_ADDRESS_V4},Groups=${SECURITY_GROUP},SubnetId=${AKKA_BACKEND_INSTANCE_SUBNET_ID}" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=role,Value=backend}]"
done

for AKKA_HTTP_SETTINGS in $(jq -c '.akka_backend_instances' "$EC2_SETTINGS")
do
  AKKA_HTTP_INSTANCE_TYPE=$(jq -c '.instance_type' "$AKKA_HTTP_SETTINGS")
  AKKA_HTTP_INSTANCE_IP_ADDRESS_V4=$(jq -c '.ip_address_v4' "$AKKA_HTTP_SETTINGS")
  AKKA_HTTP_INSTANCE_SUBNET=$(jq -c '.subnet' "$AKKA_HTTP_SETTINGS")
  AKKA_HTTP_INSTANCE_SUBNET_ID=$("${DESCRIBED}"  | jq -c ".Stacks[0].Outputs[] | select(.OutputKey == ${AKKA_HTTP_INSTANCE_SUBNET}) | .OutputValue")
  # If you are using a command line tool, base64-encoding is performed for you, and you can load the text from a file., https://docs.aws.amazon.com/cli/latest/reference/ec2/run-instances.html
  aws ec2 run-instances \
    --image-id "ami-0d7ed3ddb85b521a6" \
    --instance-type "${AKKA_HTTP_INSTANCE_TYPE}"  \
    --key-name "demo-key-pair" \
    --iam-instance-profile "Name=${IAM_INSTANCE_PROFILE_SSM}" \
    --user-data "file://user-data.sh" \
    --network-interfaces "AssociatePublicIpAddress=true,DeviceIndex=0,PrivateIpAddress=${AKKA_HTTP_INSTANCE_IP_ADDRESS_V4},Groups=${SECURITY_GROUP},SubnetId=${AKKA_HTTP_INSTANCE_SUBNET_ID}" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=role,Value=wrk}]"
done
