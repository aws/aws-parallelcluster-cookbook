#!/bin/sh
set -e
curl --retry 3 --retry-delay 5 -v -L -o $TARBALL_PATH $TARBALL_URL
