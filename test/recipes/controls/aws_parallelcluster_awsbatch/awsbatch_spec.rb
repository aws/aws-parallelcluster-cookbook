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

control 'tag:config_awsbatch_correctly_configured' do
  only_if { node['cluster']['scheduler'] == 'awsbatch' }

  # Test that batch commands can be accessed without absolute path
  %w(awsbkill awsbqueues awsbsub awsbhosts awsbout awsbstat).each do |cli_commmand|
    describe "#{cli_commmand} can be accessed without absolute path" do
      subject { bash("sudo -u #{node['cluster']['cluster_user']} bash -c '. ~/.bash_profile; #{cli_commmand} -h'") }
      its('exit_status') { should eq 0 }
    end
  end
end
