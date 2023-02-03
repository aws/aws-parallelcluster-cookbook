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

control 'jwt_dependencies_installed' do
  title "JWT dependencies are installed"

  packages = []
  if os.redhat?
    # Skipping redhat on docker since ubi-appstream repo is not aligned with the main repo
    packages.concat %w(jansson-devel) unless os_properties.redhat_ubi?
  elsif os.debian?
    packages.concat %w(libjansson-dev)
  else
    describe "unsupported OS" do
      pending "support for #{os.name}-#{os.release} needs to be implemented"
    end
  end

  packages.each do |pkg|
    describe package(pkg) do
      # Skipping check on docker/redhat since the ubi-8-appstream repository
      it { should be_installed }
    end
  end
end
