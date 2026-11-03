# frozen_string_literal: true

# Copyright:: 2026 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# Name of the bundle of Python wheels for the given virtualenv type (cookbook, node, cfn),
# which is also the name of the directory the bundle extracts to.
def pypi_dependencies_package_name(dependency_type)
  "pypi-#{dependency_type}-dependencies-#{node['cluster']['python-major-minor-version']}-#{node['kernel']['machine']}"
end
