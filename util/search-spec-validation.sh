#!/bin/bash

# This script requires yq. https://github.com/mikefarah/yq/#install
# The script shows the differences between the suite of validators in kitchen.validate.yml and the inspec controls in the specified directory
# The script searches inspec control in directories test/recipes/ and test/resources/
# The script have to be run in the root of the repository
# Example util/search-spec-validation.sh <suite> <inspec_folder>

CONTROLS_FROM_KITCHEN_YML=$(yq '... comments="" | .suites[select(.name == "$1")].verifier.controls[]' kitchen.validate.yml | sort -u)
CONTROLS_FROM_TEST_DIRECTORY=$(grep -Rh "control " test/*/*/$1 | awk -F\' '{print $2}' | grep . | sort -u)
diff <(echo "$CONTROLS_FROM_KITCHEN_YML") <(echo "$CONTROLS_FROM_TEST_DIRECTORY")
