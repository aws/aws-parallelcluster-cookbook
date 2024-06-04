# frozen_string_literal: true

# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

include_recipe "aws-parallelcluster-platform::sudo_install"
include_recipe "aws-parallelcluster-platform::users"
include_recipe "aws-parallelcluster-platform::disable_services"
package_repos 'setup the repositories'
include_recipe "aws-parallelcluster-platform::directories"
install_packages 'Install OS and extra packages'
include_recipe "aws-parallelcluster-platform::cookbook_virtualenv"
include_recipe "aws-parallelcluster-platform::awscli"
unless alinux2023_on_docker? # Running this recipe on Alinux 2023 docker generates false failure.
  # Example failure https://github.com/aws/aws-parallelcluster-cookbook/actions/runs/9373643185/job/25807894209?pr=2692
  include_recipe "openssh"
end
include_recipe "aws-parallelcluster-platform::disable_selinux"
include_recipe "aws-parallelcluster-platform::license_readme"
include_recipe "aws-parallelcluster-platform::gc_thresh_values"
include_recipe "aws-parallelcluster-platform::supervisord_install"
include_recipe "aws-parallelcluster-platform::ami_cleanup"
include_recipe "aws-parallelcluster-platform::cron"

chrony 'install Amazon Time Sync'
c_states 'disable x86_64 C states'
include_recipe "aws-parallelcluster-platform::nvidia_install"
include_recipe "aws-parallelcluster-platform::intel_mpi"
arm_pl 'Install ARM Performance Library'
intel_hpc 'Setup Intel HPC'
