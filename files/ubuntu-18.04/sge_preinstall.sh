#!/bin/sh
set -e
echo "Downloading and extracting source packages for $TARBALL_ROOT_DIR"

pkg_version="$VERSION"

#adds eon source packages
src_bionic=`sed -n '/#\s*deb-src .* bionic universe/p' /etc/apt/sources.list`
src_eoan=`echo $src_bionic|sed -e 's/#//' -e 's/bionic/eoan/'`
echo $src_eoan >> /etc/apt/sources.list
apt update

mkdir /tmp/gridengine && cd /tmp/gridengine
apt source gridengine=$pkg_version
root_dir=`ls -d */`
mv "$root_dir" $TARBALL_ROOT_DIR
tar cvfz $TARBALL_PATH $TARBALL_ROOT_DIR

#removes eon source packages
sed -i '$d' /etc/apt/sources.list
apt update
echo "Artifact $TARBALL_ROOT_DIR.tar.gz correctly created"
