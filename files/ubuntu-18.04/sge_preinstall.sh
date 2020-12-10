#!/bin/sh
set -e
echo "Downloading and extracting source packages for $TARBALL_ROOT_DIR"

pkg_version="$VERSION"

#adds focal source packages
src_bionic=`sed -n '/#\s*deb-src .* bionic universe/p' /etc/apt/sources.list`

# FIXME: if China region use US repository
if [ "${REGION}" != "${REGION#cn-*}" ]; then
  src_focal="deb-src http://us-east-1.ec2.archive.ubuntu.com/ubuntu/ focal universe"
else
  src_focal=`echo "${src_bionic}" | sed -e 's/#//' -e 's/bionic/focal/'`
fi
echo $src_focal >> /etc/apt/sources.list
apt update

mkdir /tmp/gridengine && cd /tmp/gridengine
apt source gridengine=$pkg_version
root_dir=`ls -d */`
mv "$root_dir" $TARBALL_ROOT_DIR
tar cvfz $TARBALL_PATH $TARBALL_ROOT_DIR

#removes focal source packages
sed -i '$d' /etc/apt/sources.list
apt update
echo "Artifact $TARBALL_ROOT_DIR.tar.gz correctly created"
