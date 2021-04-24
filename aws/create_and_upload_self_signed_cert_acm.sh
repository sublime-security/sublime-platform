#!/bin/bash

# if this SSM value exists, abort script
CERT_EXISTS_ALREADY=$(aws ssm get-parameter --name /sublime-security/self-signed-acm-certificate-for-sublime-security-on-prem-deployment | jq .Parameter.Value)

if [ -z $CERT_EXISTS_ALREADY ]
then
    echo "ACM and SSM parameter for ACM certificate need to be created"
    openssl genrsa 2048 > my-aws-private.key
    openssl req -new -x509 -nodes -sha1 -days 36500 -extensions v3_ca -key my-aws-private.key -subj "/C=US/ST=DC/L=Washington, DC/O=Sublime Security/OU=Sublime Security on-prem deployment/CN=sublime-security-self-hosted-platform.local/emailAddress=support@sublimesecurity.com/" > my-aws-public.crt
    CERT_ARN="$(aws acm import-certificate --certificate fileb://my-aws-public.crt --private-key fileb://my-aws-private.key --tags '[{"Key":"Function", "Value": "Self-signed certificate for Sublime Security on-prem deployment"}]' | jq -r .CertificateArn)"
    aws ssm put-parameter --name "/sublime-security/self-signed-acm-certificate-for-sublime-security-on-prem-deployment" --description "ARN for self-signed SSL certificate created for Sublime Security self-hosted deployment" --value $CERT_ARN --type "String" --tags '[{"Key":"Function","Value": "ARN for self-signed SSL certificate created for Sublime Security self-hosted deployment"}, {"Key":"Purpose", "Value": "Used for the Sublime Security self-hosted deployment"}, {"Key": "Date created", "Value":  "April 21 2021"}]'
    rm my-aws-private.key;
    rm my-aws-public.crt;

    CERT_EXISTS_ALREADY=$(aws ssm get-parameter --name /sublime-security/self-signed-acm-certificate-for-sublime-security-on-prem-deployment | jq .Parameter.Value)

    if [ -z $CERT_EXISTS_ALREADY ]
    then
        echo "ACM and SSM parameter for ACM certificate were succesfully created"
    else
        echo "ERROR: ACM and SSM parameter for ACM certificate did not create successfully"
    fi

else
    echo "ACM and SSM parameter for ACM certificate already exists"
fi
