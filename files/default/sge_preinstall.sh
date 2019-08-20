#!/bin/sh
set -e
curl --retry 3 -v -L -o $TARBALL_PATH $TARBALL_URL
