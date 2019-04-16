#!/bin/sh

if [ "$1" = "" ]; then
  EXEC_UUID="$1"
else
  echo "The first parameter = '$1' is empty but must be passed!"
  exit 1
fi

if [ "$2" = "" ]; then
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
AKKA_BACKEND_INSTANCE_IDS=$(aws ec2 describe-instances --filters "Name=tag:role,Values=backend" "Name=tag:exec-id,Values=${EXEC_ID}" --query "Reservations[*].Instances[*].InstanceId" --output text)
for AKKA_BACKEND_INSTANCE_ID in "${AKKA_BACKEND_INSTANCE_IDS}"
do
  set -x # Enables a mode of the shell where all executed commands are printed to the terminal
  aws ec2 wait instance-status-ok --instance-ids "${AKKA_BACKEND_INSTANCE_ID}"
  aws ssm send-command \
    --instance-ids "${AKKA_BACKEND_INSTANCE_ID}" \
    --document-name "AWS-RunShellScript" \
    --comment "running akka backend for benchmarking" \
    --parameters commands="[ /home/ec2-user/akka-perf-cluster-sharding-get/scripts/remote/backend.sh ${SEED_NODE_IPV4} ]" \
    --output text \
    --query "Command.CommandId"
  set +x # Disables the previous `set -x`
done

AKKA_BACKEND_INSTANCE_IDS=$(aws ec2 describe-instances --filters "Name=tag:role,Values=backend"  "Name=tag:exec-id,Values=${EXEC_ID}" --query "Reservations[*].Instances[*].InstanceId" --output text)
for AKKA_BACKEND_INSTANCE_ID in "${AKKA_BACKEND_INSTANCE_IDS}"
do
  set -x # Enables a mode of the shell where all executed commands are printed to the terminal
  aws ec2 wait instance-status-ok --instance-ids "${AKKA_BACKEND_INSTANCE_ID}"
  aws ssm send-command \
    --instance-ids "${AKKA_BACKEND_INSTANCE_ID}" \
    --document-name "AWS-RunShellScript" \
    --comment "running akka backend for benchmarking" \
    --parameters commands="[ /home/ec2-user/akka-perf-cluster-sharding-get/scripts/remote/backend.sh ${SEED_NODE_IPV4} ]" \
    --output text \
    --query "Command.CommandId"
  set +x # Disables the previous `set -x`
done