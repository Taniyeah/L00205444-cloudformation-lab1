#!/bin/bash
# Lab 1b: deletes the three tier stack and everything in it.
# Run it from the root of the repo: ./scripts/destroy-3-tier.sh
#
# Source: Dhandala (2026b) OneUptime and my own scripts/destroy.sh from Lab 1a. Same logic: check
# the stack exists, ask for confirmation, delete the stack and wait.
#
# What is different from destroy.sh:
# - there is no bucket to empty, because this stack has no bucket
# - I left out the termination protection check and the resource list to
#   keep it simple
#
set -e

STACK_NAME=lab1b-three-tier
REGION=eu-west-1

# Step 1: check the stack exists
if ! OUTPUT=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" --region "$REGION" 2>&1); then
  if echo "$OUTPUT" | grep -q "does not exist"; then
    echo "Stack $STACK_NAME does not exist in $REGION. Nothing to delete."
    exit 0
  fi
  echo "$OUTPUT"
  exit 1
fi

# Step 2: ask before doing anything
echo "This will delete stack $STACK_NAME and all its resources."
read -r -p "Type yes to continue: " ANSWER
if [ "$ANSWER" != "yes" ]; then
  echo "Cancelled. Nothing was deleted."
  exit 0
fi

# Step 3: delete the stack
aws cloudformation delete-stack --stack-name "$STACK_NAME" --region "$REGION"

# Step 4: wait until the stack is gone (the database takes a few minutes)
if aws cloudformation wait stack-delete-complete \
  --stack-name "$STACK_NAME" --region "$REGION"; then
  echo "Stack $STACK_NAME is deleted."
else
  echo "The delete did not finish. Check the CloudFormation console."
  exit 1
fi