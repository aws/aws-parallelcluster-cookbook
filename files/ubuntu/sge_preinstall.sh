#!/bin/bash
set -e

if [ -z ${TARBALL_URL} ]; then
  echo "TARBALL_URL must be set"
  exit 1
elif [ -z ${TARBALL_ROOT_DIR} ]; then
  echo "TARBALL_ROOT_DIR must be set"
  exit 1
elif [ -z ${TARBALL_PATH} ]; then
  echo "TARBALL_PATH must be set"
  exit 1
elif [ -z ${VERSION} ]; then
  echo "VERSION must be set"
  exit 1
fi

url_base_file() {
  local url=$1
  if [ -z "$url" ]; then
    echo Must pass URL
    exit 1
  fi
  echo "${url##*/}"
}

# Import the public key of Afif Elghraoui, the Debian developer whose public key
# was used to sign the .dsc file that will be used.
# Import to the keyring that debian packages examine by default
curl --retry 3 --retry-delay 5 -o afif.key "https://db.debian.org/fetchkey.cgi?fingerprint=8EBD460CB464A67530FF39FBCEAE6AD3AFE826FB"
gpg --no-default-keyring --keyring trustedkeys.gpg --import afif.key

# Following is the URL under which are stored the sources and binaries
DEB_SGE_URL_BASE=https://deb.debian.org/debian/pool/main/g/gridengine

# Download source archive
SRC_ARCHIVE_OUTFILE=`url_base_file $TARBALL_URL`
curl --retry 3 --retry-delay 5 -o $SRC_ARCHIVE_OUTFILE $TARBALL_URL

# Download file containing changes to make to the original source
MODS_OUTFILE=gridengine_${VERSION}.debian.tar.xz
curl --retry 3 --retry-delay 5 -o $MODS_OUTFILE $DEB_SGE_URL_BASE/$MODS_OUTFILE

# Download Debian source control file used to apply the required changes to the original source
DSC_OUTFILE=gridengine_${VERSION}.dsc
curl --retry 3 --retry-delay 5 -o $DSC_OUTFILE $DEB_SGE_URL_BASE/$DSC_OUTFILE

# Use dpkg-source to extract the source and apply the changes to original source
SRC_DIR=`pwd`/$TARBALL_ROOT_DIR
dpkg-source -x --require-valid-signature --require-strong-checksums $DSC_OUTFILE $SRC_DIR


tar cvzf $TARBALL_PATH $TARBALL_ROOT_DIR
