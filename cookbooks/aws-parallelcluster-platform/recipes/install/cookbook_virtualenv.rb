# frozen_string_literal: true
#
# Copyright:: 2013-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

virtualenv_path = cookbook_virtualenv_path

node.default['cluster']['cookbook_virtualenv_path'] = virtualenv_path
node_attributes "dump node attributes"

# TODO: find a way to make this code work on ubi8
return if redhat_ubi?

install_pyenv_new 'pyenv for default python version'

activate_virtual_env cookbook_virtualenv_name do
  pyenv_path cookbook_virtualenv_path
  python_version cookbook_python_version
  requirements_path "cookbook_virtualenv/requirements.txt"
  not_if { ::File.exist?("#{cookbook_virtualenv_path}/bin/activate") }
end
