#!/bin/sh
set -e
echo "Downloading and extracting source packages for ${TARBALL_ROOT_DIR}"

if [ -z ${TARBALL_URL} ]; then
  echo "TARBALL_URL must be set"
  exit 1
elif [ -z ${TARBALL_ROOT_DIR} ]; then
  echo "TARBALL_ROOT_DIR must be set"
  exit 1
elif [ -z ${TARBALL_PATH} ]; then
  echo "TARBALL_PATH must be set"
  exit 1
fi

# Download source archive
SRC_ARCHIVE_OUTFILE=${TARBALL_URL##*/}
curl --retry 3 --retry-delay 5 -o ${SRC_ARCHIVE_OUTFILE} ${TARBALL_URL}

# Extract source code to apply required patches
tar xf ${SRC_ARCHIVE_OUTFILE}
cd ${SRC_ARCHIVE_OUTFILE%.tar*}/source
# Apply changes to source code to support OpenSSL 1.1
patch --ignore-whitespace -p2 < /tmp/sge-openssl.patch
# Apply changes to TCSH 3rd party library included on SGE
# to support newer versions of glibc
patch --ignore-whitespace -p2 < /tmp/sge-tcsh.patch
# Apply changes to gmake 3rd code to build with newer versions of automake
patch --ignore-whitespace -p2 < /tmp/sge-qmake.patch

# Re-create the archive in the right folder
cd ../..
tar cvfz ${TARBALL_PATH} ${TARBALL_ROOT_DIR}
echo "Artifact ${TARBALL_ROOT_DIR}.tar.gz correctly created"
