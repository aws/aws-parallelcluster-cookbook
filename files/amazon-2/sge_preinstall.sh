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

# See patch files for descriptions of the changes.
patch --ignore-whitespace -p2 < /tmp/sge-armhf-java.patch
patch --ignore-whitespace -p2 < /tmp/sge-compiler-flags.patch
patch --ignore-whitespace -p2 < /tmp/sge-java-paths.patch
patch --ignore-whitespace -p2 < /tmp/sge-m32_m64.patch
patch --ignore-whitespace -p2 < /tmp/sge-openssl-1.1.patch
patch --ignore-whitespace -p2 < /tmp/sge-qmake-glob-glibc227.patch
patch --ignore-whitespace -p2 < /tmp/sge-skip-jgdi-with-recent-java.patch
patch --ignore-whitespace -p2 < /tmp/sge-source-dependencies.patch
patch --ignore-whitespace -p2 < /tmp/sge-union-wait.patch
patch --ignore-whitespace -p2 < /tmp/sge-x32.patch

# Re-create the archive in the right folder
cd ../..
tar cvfz ${TARBALL_PATH} ${TARBALL_ROOT_DIR}
echo "Artifact ${TARBALL_ROOT_DIR}.tar.gz correctly created"
