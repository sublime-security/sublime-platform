#!/bin/bash

if [ -z $AWS_REGION ]
then
  echo "Missing AWS_REGION environment variable. Exiting"
  exit
fi

# if this SSM value exists, abort script
CERT_EXISTS_ALREADY=$(aws ssm get-parameter --region $AWS_REGION --name /sublime-security/self-signed-acm-certificate-for-sublime-security-on-prem-deployment | jq -r .Parameter.Value)

if [[ -z $CERT_EXISTS_ALREADY || $CERT_EXISTS_ALREADY == "placeholder" ]]
then
    echo "Creating ACM and SSM parameter for ACM certificate"

    openssl genrsa 2048 > my-aws-private.key
    openssl req -new -x509 -nodes -sha1 -days 36500 -extensions v3_ca -key my-aws-private.key -subj "/C=US/ST=DC/L=Washington, DC/O=Sublime Security/OU=Sublime Security on-prem deployment/CN=sublime-security-self-hosted-platform.local/emailAddress=support@sublimesecurity.com/" > my-aws-public.crt

    CERT_ARN="$(aws acm import-certificate --certificate fileb://my-aws-public.crt --private-key fileb://my-aws-private.key --region $AWS_REGION --tags '[{"Key":"Function", "Value": "Self-signed certificate for Sublime Security on-prem deployment"}]' | jq -r .CertificateArn)"
    echo "CERT_ARN: $CERT_ARN"

    OUTPUT=$(aws ssm put-parameter --overwrite --name "/sublime-security/self-signed-acm-certificate-for-sublime-security-on-prem-deployment"  --region $AWS_REGION --description "ARN for self-signed SSL certificate created for Sublime Security self-hosted deployment" --value $CERT_ARN --type "String")
    echo "SSM Parameter output: $OUTPUT"

    rm my-aws-private.key;
    rm my-aws-public.crt;

    CERT_EXISTS_ALREADY=$(aws ssm get-parameter --region $AWS_REGION --name /sublime-security/self-signed-acm-certificate-for-sublime-security-on-prem-deployment | jq -r .Parameter.Value)

    if [[ -z $CERT_EXISTS_ALREADY || $CERT_EXISTS_ALREADY == "placeholder" ]]
    then
        echo "ERROR: ACM and SSM parameter for ACM certificate did not create successfully"
    else
        echo "ACM and SSM parameter for ACM certificate were succesfully created"
    fi

else
    echo "ACM and SSM parameter for ACM certificate already exists. Exiting"
fi
