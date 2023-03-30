# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

# Checks that the recipe is able to retrieve a Custom SlurmSettings files from S3
# using the remote_object resource both with the S3 protocol and the HTTPS protocol
# Since the content of the file can be "anything" we only check that it exists
# To keep the test as simple as possible, keeping the dependency at its minimum
# and set the destination folder to /tmp that already exists
# So we only check that the file exists
control 'custom_settings_file_retrieved' do
  title 'Checks that customs settings file has been retrieved if specified in the config'

  describe file("/tmp/custom_slurm_settings_include_slurm.conf") do
    it { should exist }
  end
end
