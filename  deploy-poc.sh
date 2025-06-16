#!/bin/bash

STACK_NAME="cicd-poc-stack"
TEMPLATE_FILE="poc-template.yml"
REGION="us-east-1"

echo "🚀 Deploying CloudFormation stack: $STACK_NAME"

aws cloudformation deploy \
  --stack-name $STACK_NAME \
  --template-file $TEMPLATE_FILE \
  --capabilities CAPABILITY_IAM \
  --region $REGION

if [ $? -eq 0 ]; then
  echo "✅ Stack $STACK_NAME deployed successfully."
else
  echo "❌ Stack deployment failed."
  exit 1
fi