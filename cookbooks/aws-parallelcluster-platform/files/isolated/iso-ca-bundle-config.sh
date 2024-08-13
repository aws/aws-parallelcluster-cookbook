#!/bin/bash
set -ex

function get_instance_region {
  local _token=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 3600")
  curl -H "X-aws-ec2-metadata-token: $_token" -v "http://169.254.169.254/latest/meta-data/placement/region" 2> /dev/null
}

REGION="$(get_instance_region)"

echo "export AWS_CA_BUNDLE=/etc/pki/${REGION}/certs/ca-bundle.pem" >> /etc/profile.d/aws-cli-default-config.sh

echo "export AWS_DEFAULT_REGION=${REGION}" >> /etc/profile.d/aws-cli-default-config.sh

echo "export REQUESTS_CA_BUNDLE=${AWS_CA_BUNDLE}" >> /etc/profile.d/aws-cli-default-config.sh

echo "export SSL_CERT_FILE=${AWS_CA_BUNDLE}" >> /etc/profile.d/aws-cli-default-config.sh

echo "Defaults env_keep += \"AWS_DEFAULT_REGION AWS_CA_BUNDLE REQUESTS_CA_BUNDLE SSL_CERT_FILE\"" > /etc/sudoers.d/pcluster-aws-cli-envkeep

source /etc/profile.d/aws-cli-default-config.sh

sudo aws configure set ca_bundle "$CA_BUNDLE"