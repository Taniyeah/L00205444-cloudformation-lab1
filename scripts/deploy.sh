#!/bin/bash
# Lab 1a: deploys the S3 website stack and uploads the page.
# Run it from the root of the repo: ./scripts/deploy.sh
#
# Source: the deploy.sh in Davra (2022) "Deploy a website with AWS S3 +
# CloudFront using CloudFormation", Canopas. I kept the same idea:
# check the template, deploy the stack, then upload the page.
# The --query and --output text options come from the AWS CLI reference
# for describe-stacks.
#
# What I changed from the blog:
# - I read the bucket name from the stack outputs, because my template
#   lets AWS choose the name
# - The script stops if any step fails
# - It prints the website address at the end


# Stop straight away if any command fails
set -e

STACK_NAME=lab1a-s3-website
REGION=eu-west-1

# Step 1: check the template is valid before I deploy it
aws cloudformation validate-template \
  --template-body file://templates/s3-website/s3-website.yaml \
  --region "$REGION"

# Step 2: create or update the bucket and hosting from the template
aws cloudformation deploy \
  --template-file templates/s3-website/s3-website.yaml \
  --stack-name "$STACK_NAME" \
  --region "$REGION"

# Step 3: get the bucket name from the stack outputs
# I cannot type it in myself because AWS makes up the name
BUCKET=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$REGION" \
  --query "Stacks[0].Outputs[?OutputKey=='BucketName'].OutputValue" \
  --output text)

# Step 4: upload the page into the bucket
aws s3 cp src/website/index.html "s3://$BUCKET/index.html"

# Step 5: print the website address
aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$REGION" \
  --query "Stacks[0].Outputs[?OutputKey=='WebsiteURL'].OutputValue" \
  --output text