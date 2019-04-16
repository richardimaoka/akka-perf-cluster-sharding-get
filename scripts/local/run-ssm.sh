#!/bin/sh

if [ -n "$1" ]; then
  EXEC_UUID="$1"
else
  echo "The first parameter = '$1' is empty but must be passed!"
  exit 1
fi

if [ -n "$2" ]; then
  CURRENT_DIR=$(dirname "$0")
  EC2_SETTINGS=$(cat "$CURRENT_DIR"/ec2-instances.json)
elif [ -f "$2" ]; then
  EC2_SETTINGS=$(cat "$2")
else
  echo "The second parameter = '$2' is provided but not a file"
  exit 1
fi

# cd to the current directory as it runs other shell scripts
cd "$(dirname "$0")"

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

SEED_NODE_IPV4=$(echo "$EC2_SETTINGS" | jq -r ".akka_backend_instances[] | select(.seed_node == true) | .ip_address_v4")
for AKKA_BACKEND_INSTANCE_ID in $(aws ec2 describe-instances --filters "Name=tag:role,Values=backend" "Name=tag:exec-id,Values=${EXEC_UUID}" --query "Reservations[*].Instances[*].InstanceId" --output text)
do
  aws ec2 wait instance-status-ok --instance-ids "${AKKA_BACKEND_INSTANCE_ID}"
  aws ssm send-command \
    --instance-ids "${AKKA_BACKEND_INSTANCE_ID}" \
    --document-name "AWS-RunShellScript" \
    --comment "running akka backend for benchmarking" \
    --parameters commands="[ /home/ec2-user/akka-perf-cluster-sharding-get/scripts/remote/backend.sh ${SEED_NODE_IPV4} ]" \
    --output text \
    --query "Command.CommandId"
done

for AKKA_FRONTEND_INSTANCE_ID in $(aws ec2 describe-instances --filters "Name=tag:role,Values=backend"  "Name=tag:exec-id,Values=${EXEC_UUID}" --query "Reservations[*].Instances[*].InstanceId" --output text)
do
  aws ec2 wait instance-status-ok --instance-ids "${AKKA_FRONTEND_INSTANCE_ID}"
  aws ssm send-command \
    --instance-ids "${AKKA_FRONTEND_INSTANCE_ID}" \
    --document-name "AWS-RunShellScript" \
    --comment "running akka frontend for benchmarking" \
    --parameters commands="[ /home/ec2-user/akka-perf-cluster-sharding-get/scripts/remote/frontend.sh ${SEED_NODE_IPV4} ]" \
    --output text \
    --query "Command.CommandId"
done
