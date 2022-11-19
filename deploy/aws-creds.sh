#!/usr/bin/env bash

ACCOUNT_ID=$(echo "$1" | tr -d '[:space:]')
AUTH_DETAILS=$(aws sts assume-role --role-arn "arn:aws:iam::$ACCOUNT_ID:role/OrganizationAccountAccessRole" --role-session-name AWSCLI-Session --duration-seconds 3600)

AWS_ACCESS_KEY_ID=$(jq -r .Credentials.AccessKeyId <<< "$AUTH_DETAILS")
AWS_SECRET_ACCESS_KEY=$(jq -r .Credentials.SecretAccessKey <<< "$AUTH_DETAILS")
AWS_SESSION_TOKEN=$(jq -r .Credentials.SessionToken <<< "$AUTH_DETAILS")

echo ""
echo "bash:"
echo "export AWS_ACCESS_KEY_ID=\"$AWS_ACCESS_KEY_ID\""
echo "export AWS_SECRET_ACCESS_KEY=\"$AWS_SECRET_ACCESS_KEY\""
echo "export AWS_SESSION_TOKEN=\"$AWS_SESSION_TOKEN\""

echo ""
echo "pwsh:"
echo "\$env:AWS_ACCESS_KEY_ID=\"$AWS_ACCESS_KEY_ID\""
echo "\$env:AWS_SECRET_ACCESS_KEY=\"$AWS_SECRET_ACCESS_KEY\""
echo "\$env:AWS_SESSION_TOKEN=\"$AWS_SESSION_TOKEN\""

echo ""
