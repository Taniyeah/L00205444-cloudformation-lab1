#!/bin/bash
# Lab 1a: deletes the S3 website stack and everything in it.
# Run it from the root of the repo: ./scripts/destroy.sh
#
# Source: Dhandala (2026) "How to Delete CloudFormation Stacks Safely",
# oneuptime. I kept the same logic: check the stack exists, show what
# will be deleted, ask for confirmation, delete the stack.
#
# What I changed from the article:
# - I empty the bucket first, because CloudFormation cannot delete a
#   bucket that still has files in it
# - I read the bucket name from the stack outputs, like in deploy.sh
# - I left out the export check because my stack has no exports

set -e

STACK_NAME=lab1a-s3-website
REGION=eu-west-1

# Step 1: check the stack exists
if ! OUTPUT=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" --region "$REGION" 2>&1); then
  if echo "$OUTPUT" | grep -q "does not exist"; then
    echo "Stack $STACK_NAME does not exist in $REGION. Does not to delete."
    exit 0
  fi
  echo "$OUTPUT"
  exit 1
fi

# Step 2: Check termination protection status
PROTECTED=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" --region "$REGION" \
  --query "Stacks[0].EnableTerminationProtection" --output text)
if [ "$PROTECTED" = "True" ]; then
  echo "Termination protection is on. Turn it off first."
  exit 1
fi

# Step 3: get the bucket name from the stack outputs
BUCKET=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" --region "$REGION" \
  --query "Stacks[0].Outputs[?OutputKey=='BucketName'].OutputValue" \
  --output text)

# Step 4: show what will be deleted
echo "This will delete stack $STACK_NAME and these resources:"
aws cloudformation list-stack-resources \
  --stack-name "$STACK_NAME" --region "$REGION" \
  --query "StackResourceSummaries[].[LogicalResourceId,ResourceType]" \
  --output table
echo "All files in bucket $BUCKET will be deleted for good."

# Step 5: ask before doing anything
read -r -p "Type yes to continue: " ANSWER
if [ "$ANSWER" != "yes" ]; then
  echo "Cancelled. Nothing was deleted."
  exit 0
fi

# Step 6: empty the bucket, because a stack cannot delete a bucket with files in it
if [ -n "$BUCKET" ] && [ "$BUCKET" != "None" ]; then
  aws s3 rm "s3://$BUCKET" --recursive
fi

# Step 7: delete the stack
aws cloudformation delete-stack --stack-name "$STACK_NAME" --region "$REGION"

# Step 8: wait until the stack is gone
if aws cloudformation wait stack-delete-complete \
  --stack-name "$STACK_NAME" --region "$REGION"; then
  echo "Stack $STACK_NAME is deleted."
else
  echo "The delete did not finish. Check the CloudFormation console."
  exit 1
fi