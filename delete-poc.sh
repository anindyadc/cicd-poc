#!/bin/bash

STACK_NAME="cicd-poc-stack"
REGION="us-east-1"

echo "⚠️ Deleting CloudFormation stack: $STACK_NAME..."

aws cloudformation delete-stack \
  --stack-name $STACK_NAME \
  --region $REGION

echo "⏳ Waiting for stack deletion to complete..."
aws cloudformation wait stack-delete-complete \
  --stack-name $STACK_NAME \
  --region $REGION

if [ $? -eq 0 ]; then
  echo "✅ Stack $STACK_NAME deleted successfully."
else
  echo "❌ Failed to delete stack."
  exit 1
fi