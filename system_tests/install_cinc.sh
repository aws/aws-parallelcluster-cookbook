#!/bin/bash
set -v

ChefVersion=17.2.29
BerkshelfVersion=7.2.0
AWS_Region=us-east-2
AWS_URLSuffix=amazonaws.com

CINC_URL="https://${AWS_Region}-aws-parallelcluster.s3.${AWS_Region}.${AWS_URLSuffix}/archives/cinc/cinc-install-1.1.0.sh"
CINC_URL="https://omnitruck.cinc.sh/install.sh"

. /etc/os-release
RELEASE="${ID}${VERSION_ID:+.${VERSION_ID}}"

if [ `echo "${RELEASE}" | grep -w '^amzn\.2'` ]; then
  OS='alinux2'
elif [ `echo "${RELEASE}" | grep '^centos\.7'` ]; then
  OS='centos7'
elif [ `echo "${RELEASE}" | grep '^ubuntu\.18'` ]; then
  OS='ubuntu1804'
elif [ `echo "${RELEASE}" | grep '^ubuntu\.20'` ]; then
  OS='ubuntu2004'
else
  echo "Operating System '${RELEASE}' is not supported. Failing build."
  exit 1
fi

if [ `echo "${OS}" | grep -E '^(alinux|centos)'` ]; then
  PLATFORM='RHEL'
elif [ `echo "${OS}" | grep -E '^ubuntu'` ]; then
  PLATFORM='DEBIAN'
fi

AWS_DOMAIN="amazonaws.com"
[[ ${AWS_Region} =~ ^cn- ]] && AWS_DOMAIN="amazonaws.com.cn"
[[ ${AWS_Region} =~ ^us-iso- ]] && AWS_DOMAIN="c2s.ic.gov"
[[ ${AWS_Region} =~ ^us-isob- ]] && AWS_DOMAIN="sc2s.sgov.gov"

S3_ENDPOINT="s3.${AWS_Region}.${AWS_DOMAIN}"

BUCKET="cloudformation-examples"
[[ ${AWS_DOMAIN} != "amazonaws.com" ]] && BUCKET="${AWS_Region}-aws-parallelcluster/cloudformation-examples"
if [[ ${OS} =~ ^(ubuntu2004)$ ]]; then
  CfnBootstrapUrl="https://${S3_ENDPOINT}/${BUCKET}/aws-cfn-bootstrap-py3-latest.tar.gz"
else
  CfnBootstrapUrl="https://${S3_ENDPOINT}/${BUCKET}/aws-cfn-bootstrap-latest.tar.gz"
fi

ARCH=$(uname -m)
if [ "$ARCH" == "aarch64" ]; then
    ARCH=arm64
fi

if [[ ${PLATFORM} == RHEL ]]; then
  if [[ ${OS} == centos7 ]]; then
    yum -y install epel-release
  fi
  yum -y groupinstall development && yum -y install curl wget jq
  if [[ ${OS} =~ ^centos ]]; then
    /bin/sed -r -i -e 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
    grub2-mkconfig -o /boot/grub2/grub.cfg
  fi
elif [[ ${PLATFORM} == DEBIAN ]]; then
  if [[ "${CfnParamUpdateOsAndReboot}" == "false" ]]; then
    flock $(apt-config shell StateDir Dir::State/d | sed -r "s/.*'(.*)\/?'$/\1/")/daily_lock systemctl disable --now apt-daily.timer apt-daily.service apt-daily-upgrade.timer apt-daily-upgrade.service
    sed "/Update-Package-Lists/s/\"1\"/\"0\"/; /Unattended-Upgrade/s/\"1\"/\"0\"/;" /etc/apt/apt.conf.d/20auto-upgrades > "/etc/apt/apt.conf.d/51pcluster-unattended-upgrades"
  fi
  apt-get clean
  apt-get -y update
  apt-get -y install build-essential curl wget jq
fi

if [[ ${PLATFORM} == RHEL ]]; then
  CA_CERTS_FILE=/etc/ssl/certs/ca-bundle.crt
  yum -y upgrade ca-certificates
elif [[ ${PLATFORM} == DEBIAN ]]; then
  CA_CERTS_FILE=/etc/ssl/certs/ca-certificates.crt
  apt-get -y --only-upgrade install ca-certificates
fi

curl --retry 3 -L $CINC_URL | bash -s -- -v ${ChefVersion}

if [[ -e ${CA_CERTS_FILE} ]]; then
  ln -sf ${CA_CERTS_FILE} /opt/cinc/embedded/ssl/certs/cacert.pem
fi

/opt/cinc/embedded/bin/gem install --no-document berkshelf:${BerkshelfVersion}

mkdir -p /etc/chef && chown -R root:root /etc/chef
