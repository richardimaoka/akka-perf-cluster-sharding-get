#!/bin/sh

# cd to the current directory as it runs other shell scripts
cd "$(dirname "$0")"

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

# parse options, note that whitespace is needed (e.g. -c 4) between an option and the option argument
#  --vpc-stack: The Cloudformation stack name for defining VPC
VPC_STACK_NAME="bench-vpc"
EC2_SETTINGS=$(cat ../../data/ec2-instances.json)
for OPT in "$@"
do
    case "$OPT" in
        '--vpc-stack' )
            if [ -z "$2" ] ; then
                echo "option --vpc-stack requires an argument -- $1" 1>&2
                exit 1
            fi
            VPC_STACK_NAME="$2"
            shift 2
            ;;
        -*)
            echo "illegal option -- '$(echo "$1" | sed 's/^-*//')'" 1>&2
            exit 1
            ;;
        *)
            if [ -f "$1" ] ; then
                EC2_SETTINGS=$(cat "$1")
                break
            fi
            ;;
    esac
done

aws cloudformation wait stack-create-complete --stack-name "${VPC_STACK_NAME}"

EXEC_UUID=$(uuidgen)

# Variables to be passed upon EC2 creation in the next step
DESCRIBED=$(aws cloudformation describe-stacks --stack-name "${VPC_STACK_NAME}")
SECURITY_GROUP=$(echo "${DESCRIBED}" | jq -c '.Stacks[0].Outputs[] | select(.OutputKey == "SecurityGroup") | .OutputValue')
IAM_INSTANCE_PROFILE_SSM=$(echo "${DESCRIBED}" | jq -c '.Stacks[0].Outputs[] | select(.OutputKey == "InstanceProfile") | .OutputValue')

# Create EC2 instances. Since CloudFormation doesn't support creation of a variable number of EC2 instances,
# you need to create the instances via CLI.

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
for AKKA_HTTP_SETTINGS in $(echo "$EC2_SETTINGS" | jq -c '.akka_http_instances[]')
do
  AKKA_HTTP_INSTANCE_TYPE=$(echo "$AKKA_HTTP_SETTINGS" | jq -r '.instance_type')
  AKKA_HTTP_INSTANCE_IP_ADDRESS_V4=$(echo "$AKKA_HTTP_SETTINGS" | jq -r '.ip_address_v4')
  AKKA_HTTP_INSTANCE_SUBNET=$(echo "$AKKA_HTTP_SETTINGS" | jq -c '.subnet')
  AKKA_HTTP_INSTANCE_SUBNET_ID=$(echo "${DESCRIBED}" | jq -c ".Stacks[0].Outputs[] | select(.OutputKey == $AKKA_HTTP_INSTANCE_SUBNET) | .OutputValue")
  # If you are using a command line tool, base64-encoding is performed for you, and you can load the text from a file., https://docs.aws.amazon.com/cli/latest/reference/ec2/run-instances.html
  aws ec2 run-instances \
    --image-id "ami-0d7ed3ddb85b521a6" \
    --instance-type "${AKKA_HTTP_INSTANCE_TYPE}"  \
    --key-name "demo-key-pair" \
    --iam-instance-profile "Name=${IAM_INSTANCE_PROFILE_SSM}" \
    --user-data "file://user-data.sh" \
    --network-interfaces "AssociatePublicIpAddress=true,DeviceIndex=0,PrivateIpAddress=${AKKA_HTTP_INSTANCE_IP_ADDRESS_V4},Groups=${SECURITY_GROUP},SubnetId=${AKKA_HTTP_INSTANCE_SUBNET_ID}" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=akka-http-${AKKA_HTTP_INSTANCE_IP_ADDRESS_V4}},{Key=role,Value=http},{Key=exec-id,Value=${EXEC_UUID}}]"
done

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

# Print out the next instruction
SEED_NODE_IPV4=$(echo "$EC2_SETTINGS" | jq -r ".akka_backend_instances[] | select(.seed_node == true) | .ip_address_v4")
AKKA_HTTP_IPV4=$(echo "$EC2_SETTINGS" | jq -r ".akka_http_instances[0].ip_address_v4")

echo "Successfully finished creating EC2 instances. The following command will start up the test on EC2."
echo "cd // to the root directory of this repository"
echo "scripts/local/run-ssm.sh --seed-node-ipv4 ${SEED_NODE_IPV4} --akka-http-ipv4 ${AKKA_HTTP_IPV4} ${EXEC_UUID}"