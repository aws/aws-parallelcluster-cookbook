#!/bin/sh
set -e

url_base_file() {
  local url=$1
  if [ -z "$url" ]; then
    echo Must pass URL
    exit 1
  fi
  echo "${url##*/}"
}

# Following is the URL under which are stored the sources and binaries
DEB_SGE_URL_BASE=http://deb.debian.org/debian/pool/main/g/gridengine

# Download source archive
SRC_ARCHIVE_OUTFILE=`url_base_file $TARBALL_URL`
curl -o $SRC_ARCHIVE_OUTFILE $TARBALL_URL

# Download file containing changes to make to the original source
MODS_OUTFILE=gridengine_${VERSION}.debian.tar.xz
curl -o $MODS_OUTFILE $DEB_SGE_URL_BASE/$MODS_OUTFILE

# Download Debian source control file used to apply the required changes to the original source
DSC_OUTFILE=gridengine_${VERSION}.dsc
curl -o $DSC_OUTFILE $DEB_SGE_URL_BASE/$DSC_OUTFILE

# Use dpkg-source to extract the source and apply the changes to original source
# Import key used to sign the package for purposes of verification.
# Import to the keyring that debian packages examine by default
gpg --no-default-keyring --keyring trustedkeys.gpg --keyserver keyring.debian.org --recv-keys 3AF9DDC1
SRC_DIR=`pwd`/$TARBALL_ROOT_DIR
dpkg-source -x --require-valid-signature --require-strong-checksums $DSC_OUTFILE $SRC_DIR


tar cvzf $TARBALL_PATH $TARBALL_ROOT_DIR
