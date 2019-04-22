#!/bin/sh

# cd to the current directory as it runs other shell scripts
cd "$(dirname "$0")"

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

# parse options, note that whitespace is needed (e.g. -c 4) between an option and the option argument
#  --seed-node-ipv4: The IPv4 address of the Akka Cluster seed node
#  --akka-http-ipv4: The IPv4 address of the Akka HTTP server
while [ $# -gt 0 ]
do
    case "$1" in
        '--seed-node-ipv4' )
            if [ -z "$2" ] || [ $(echo "$2" | cut -c 1) = "-" ] ; then
                echo "option --seed-node-ipv4 requires an argument" 1>&2
                exit 1
            fi
            SEED_NODE_IPV4="$2"
            shift 2
            ;;
        '--akka-http-ipv4' )
            if [ -z "$2" ] || [ $(echo "$2" | cut -c 1) = "-" ] ; then
                echo "option --akka-http-ipv4 requires an argument" 1>&2
                exit 1
            fi
            AKKA_HTTP_IPV4="$2"
            shift 2
            ;;
        -*)
            echo "illegal option -- '$(echo "$1" | sed 's/^-*//')'" 1>&2
            exit 1
            ;;
        *)
            if [ -n "$1" ] ; then
                EXEC_UUID="$1"
                break
            fi
            ;;
    esac
done

COMMAND_ERROR=""
if [ -z "$SEED_NODE_IPV4" ]; then
  COMMAND_ERROR="${COMMAND_ERROR}ERROR: --seed-node-ipv4 must be provided.\n"
fi
if [ -z "$AKKA_HTTP_IPV4" ]; then
  COMMAND_ERROR="${COMMAND_ERROR}ERROR: --akka-http-ipv4 must be provided.\n"
fi
if [ -z "$EXEC_UUID" ]; then
  COMMAND_ERROR="${COMMAND_ERROR}ERROR: the argument for test execution UUID must be provided.\n"
fi
if [ -n "${COMMAND_ERROR}" ]; then
  echo "${COMMAND_ERROR}" 1>&2
  exit 1
fi


echo "starting the seed node"
AKKA_SEED_NODE_INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:role,Values=seed-node"  "Name=tag:exec-id,Values=${EXEC_UUID}" --query "Reservations[*].Instances[*].InstanceId" --output text)
aws ec2 wait instance-status-ok --instance-ids "${AKKA_SEED_NODE_INSTANCE_ID}"
aws ssm send-command \
  --instance-ids "${AKKA_SEED_NODE_INSTANCE_ID}" \
  --document-name "AWS-RunShellScript" \
  --comment "starting seed node for exec id = ${EXEC_UUID}" \
  --parameters commands="[ /home/ec2-user/akka-perf-cluster-sharding-get/scripts/remote/seed-node.sh ${SEED_NODE_IPV4} ]" \
  --output text \
  --query "Command.CommandId"

echo "sleeping to give the seed node enough warm-up time..."
sleep 30

echo "starting backend"
for AKKA_BACKEND_INSTANCE_ID in $(aws ec2 describe-instances --filters "Name=tag:role,Values=backend" "Name=tag:exec-id,Values=${EXEC_UUID}" --query "Reservations[*].Instances[*].InstanceId" --output text)
do
  aws ec2 wait instance-status-ok --instance-ids "${AKKA_BACKEND_INSTANCE_ID}"
  aws ssm send-command \
    --instance-ids "${AKKA_BACKEND_INSTANCE_ID}" \
    --document-name "AWS-RunShellScript" \
    --comment "running akka backend for benchmarking for exec id = ${EXEC_UUID}" \
    --parameters commands="[ /home/ec2-user/akka-perf-cluster-sharding-get/scripts/remote/backend.sh ${SEED_NODE_IPV4} ]" \
    --output text \
    --query "Command.CommandId"
done

echo "sleeping to give the backend enough warm-up time..."
sleep 30

echo "creating sharding actors"
# Use the wrk EC2 instance as other Akka backend/http instances might be short on memory
# if instances <= t2.medium
WRK_INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:role,Values=wrk"  "Name=tag:exec-id,Values=${EXEC_UUID}" --query "Reservations[*].Instances[*].InstanceId" --output text)
aws ec2 wait instance-status-ok --instance-ids "${WRK_INSTANCE_ID}"
aws ssm send-command \
  --instance-ids "${WRK_INSTANCE_ID}" \
  --document-name "AWS-RunShellScript" \
  --comment "creating sharding actors for exec id = ${EXEC_UUID}" \
  --parameters commands="[ /home/ec2-user/akka-perf-cluster-sharding-get/scripts/remote/create-sharding-actors.sh ${SEED_NODE_IPV4} ]" \
  --output text \
  --query "Command.CommandId"

echo "starting http"
for AKKA_HTTP_INSTANCE_ID in $(aws ec2 describe-instances --filters "Name=tag:role,Values=http"  "Name=tag:exec-id,Values=${EXEC_UUID}" --query "Reservations[*].Instances[*].InstanceId" --output text)
do
  aws ec2 wait instance-status-ok --instance-ids "${AKKA_HTTP_INSTANCE_ID}"
  aws ssm send-command \
    --instance-ids "${AKKA_HTTP_INSTANCE_ID}" \
    --document-name "AWS-RunShellScript" \
    --comment "running akka http for benchmarking for exec id = ${EXEC_UUID}" \
    --parameters commands="[ /home/ec2-user/akka-perf-cluster-sharding-get/scripts/remote/http.sh ${SEED_NODE_IPV4} ]" \
    --output text \
    --query "Command.CommandId"
done

echo "sleeping until everything is ready..."
sleep 30

echo "running wrk"
WRK_INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:role,Values=wrk"  "Name=tag:exec-id,Values=${EXEC_UUID}" --query "Reservations[*].Instances[*].InstanceId" --output text)
aws ssm send-command \
  --instance-ids "${WRK_INSTANCE_ID}" \
  --document-name "AWS-RunShellScript" \
  --comment "running akka wrk for benchmarking for exec id = ${EXEC_UUID}" \
  --parameters commands="[ docker run richard-perf-wrk:latest ${AKKA_HTTP_IPV4} ]" \
  --output text \
  --query "Command.CommandId"
