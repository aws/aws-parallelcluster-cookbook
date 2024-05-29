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

# This control is generic enough to be applied to all types of nodes in ParallelCluster
control 'tag:config_log_rotation_all_nodes' do
  title 'Check that log rotation has been properly configured'

  # This should be enough at least to verify that the logrotate overall configuration is valid.
  # WARNING: do not use the `--force` option, because running multiple times the command with the
  # `--force` option will cause the command to fail (defeating the purpose of the test)
  describe "Log rotation command runs successfully" do
    subject { command("sudo logrotate /etc/logrotate.conf") }
    its('exit_status') { should eq 0 }
  end

end
