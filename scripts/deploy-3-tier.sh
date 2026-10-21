#!/bin/bash
# Lab 1b: deploys the three tier stack.
# Run it from the root of the repo: ./scripts/deploy-3-tier.sh
#
# Based on the deployment script in "How to Deploy CloudFormation Templates
# with the AWS CLI" (Dhandala on OneUptime, 2026) and on my own scripts/deploy.sh from
# Lab 1a: validate the template, deploy the stack, print the outputs.
#
# What is different from deploy.sh:
# - there is no file to upload, because the web page is in the template
# - the stack gets tags, and CloudFormation copies them to the resources
#

set -euo pipefail

STACK_NAME=lab1b-three-tier
REGION=eu-west-1
TEMPLATE=templates/three-tier/three-tier.yaml

# Step 1: check the template
aws cloudformation validate-template \
  --template-body "file://$TEMPLATE" --region "$REGION" > /dev/null
echo "Template validation passed"

# Step 2: deploy the stack (the database takes 5 to 10 minutes)
aws cloudformation deploy \
  --template-file "$TEMPLATE" \
  --stack-name "$STACK_NAME" \
  --region "$REGION" \
  --tags Project=CloudFormationLab Student=L00205444 ManagedBy=CloudFormation

# Step 3: print the outputs
aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" --region "$REGION" \
  --query "Stacks[0].Outputs[].[OutputKey,OutputValue]" \
  --output text