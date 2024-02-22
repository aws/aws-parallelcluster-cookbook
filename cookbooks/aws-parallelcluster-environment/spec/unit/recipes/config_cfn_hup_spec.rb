# frozen_string_literal: true

# Copyright:: 2024 Amazon.com, Inc. and its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

require "spec_helper"

describe "aws-parallelcluster-environment::config_cfn_hup" do
  AWS_REGION = "AWS_REGION"
  AWS_DOMAIN = "AWS_DOMAIN"
  STACK_ID = "STACK_ID"
  CLOUDFORMATION_URL = "https://cloudformation.#{AWS_REGION}.#{AWS_DOMAIN}"
  INSTANCE_ROLE_NAME = "INSTANCE_ROLE_NAME"
  LAUNCH_TEMPLATE_ID = "LAUNCH_TEMPLATE_ID"

  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      for_all_node_types do |node_type|
        context "when #{node_type}" do
          cached(:chef_run) do
            runner = runner(platform: platform, version: version) do |node|
              allow_any_instance_of(Object).to receive(:get_metadata_token).and_return("IMDS_TOKEN")
              allow_any_instance_of(Object).to receive(:get_metadata_with_token)
                .with("IMDS_TOKEN", URI("http://169.254.169.254/latest/meta-data/iam/security-credentials"))
                .and_return(INSTANCE_ROLE_NAME)

              node.override["cluster"]["node_type"] = node_type
              node.override["cluster"]["region"] = AWS_REGION
              node.override["cluster"]["aws_domain"] = AWS_DOMAIN
              # TODO: We inject the stack id into the attribute stack_arn when generating the dna.json in the CLI.
              #  This should be fixed at the CLI level first and adapt the cookbook accordingly.
              node.override["cluster"]["stack_arn"] = STACK_ID
              node.override["cluster"]["launch_template_id"] = LAUNCH_TEMPLATE_ID
            end
            runner.converge(described_recipe)
          end
          cached(:node) { chef_run.node }

          %w(/etc/cfn /etc/cfn/hooks.d).each do |dir|
            it "creates the directory #{dir}" do
              is_expected.to create_directory(dir).with(
                owner: "root",
                group: "root",
                mode:  "0770",
                recursive: true
              )
            end
          end

          it "creates the file /etc/cfn/cfn-hup.conf" do
            is_expected.to create_template("/etc/cfn/cfn-hup.conf")
              .with(source: 'cfn_bootstrap/cfn-hup.conf.erb')
              .with(user: "root")
              .with(group: "root")
              .with(mode: "0400")
              .with(variables: {
               stack_id: STACK_ID,
               region: AWS_REGION,
               cloudformation_url: CLOUDFORMATION_URL,
               cfn_init_role: INSTANCE_ROLE_NAME,
             })
          end

          it "creates the file /etc/cfn/hooks.d/pcluster-update.conf" do
            is_expected.to create_template("/etc/cfn/hooks.d/pcluster-update.conf")
              .with(source: 'cfn_bootstrap/cfn-hook-update.conf.erb')
              .with(user: "root")
              .with(group: "root")
              .with(mode: "0400")
              .with(variables: {
               stack_id: STACK_ID,
               region: AWS_REGION,
               cloudformation_url: CLOUDFORMATION_URL,
               cfn_init_role: INSTANCE_ROLE_NAME,
               launch_template_resource_id: LAUNCH_TEMPLATE_ID,
             })
          end
        end
      end
    end
  end
end
