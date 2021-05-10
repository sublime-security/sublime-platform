#!/bin/bash

if [ -z $AWS_REGION ]
then
  echo "Missing AWS_REGION environment variable. Exiting"
  exit
fi

# if this SSM value exists, abort script
CERT_EXISTS_ALREADY=$(aws ssm get-parameter --region $AWS_REGION --name /sublime-security/self-signed-acm-certificate-for-sublime-platform | jq -r .Parameter.Value)

if [[ -z $CERT_EXISTS_ALREADY || $CERT_EXISTS_ALREADY == "placeholder" ]]
then
    echo "Creating ACM and SSM parameter for ACM certificate"

    # there can be up to 15 minutes of time lag between the EC2 instance
    # and ACM. to avoid issues with "certs in the future" according to ACM,
    # we reset the date briefly by 2 days, generate the cert, then restart the
    # time daemon to reset the clock back to normal
    CERT_START_DATE=$(date -d "$date -2 days" +"%y%m%d")
    sudo systemctl stop systemd-timesyncd
    sudo date -s $CERT_START_DATE

    openssl genrsa -out platform-ca.key 2048
    openssl req -x509 -new -nodes -key platform-ca.key -sha256 -days 800 -out platform-ca.crt -subj "/C=US/O=Sublime Security/OU=Sublime Platform"
    openssl genrsa -out platform.key 2048
    openssl req -new -key platform.key -config self_signed_cert_config.cnf -out platform.csr
    openssl x509 -req -in platform.csr -CA platform-ca.crt -CAkey platform-ca.key -CAcreateserial -out platform.crt -days 800 -sha256 -extfile self_signed_cert_config.cnf -extensions req_ext

    sudo systemctl start systemd-timesyncd

    CERT_ARN="$(aws acm import-certificate --certificate fileb://platform.crt --private-key fileb://platform.key --certificate-chain fileb://platform-ca.crt --region $AWS_REGION --tags '[{"Key":"Function", "Value": "Self-signed certificate for Sublime Security on-prem deployment"}]' | jq -r .CertificateArn)"
    echo "CERT_ARN: $CERT_ARN"

    OUTPUT=$(aws ssm put-parameter --overwrite --name "/sublime-security/self-signed-acm-certificate-for-sublime-platform"  --region $AWS_REGION --description "ARN for self-signed SSL certificate created for Sublime Security self-hosted deployment" --value $CERT_ARN --type "String")
    echo "SSM Parameter output: $OUTPUT"

    rm platform-ca.crt platform-ca.key platform-ca.srl platform.crt platform.csr platform.key;

    CERT_EXISTS_ALREADY=$(aws ssm get-parameter --region $AWS_REGION --name /sublime-security/self-signed-acm-certificate-for-sublime-platform | jq -r .Parameter.Value)

    if [[ -z $CERT_EXISTS_ALREADY || $CERT_EXISTS_ALREADY == "placeholder" ]]
    then
        echo "ERROR: ACM and SSM parameter for ACM certificate did not create successfully"
    else
        echo "ACM and SSM parameter for ACM certificate were succesfully created"
    fi

else
    echo "ACM and SSM parameter for ACM certificate already exists. Exiting"
fi
