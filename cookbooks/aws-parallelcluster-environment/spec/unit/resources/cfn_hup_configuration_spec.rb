require 'spec_helper'

class ConvergeCfnHupConfiguration
  def self.configure(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-environment') do
      cfn_hup_configuration 'configure' do
        action :configure
      end
    end
  end
end

AWS_REGION = "AWS_REGION".freeze
AWS_DOMAIN = "AWS_DOMAIN".freeze
STACK_ID = "STACK_ID".freeze
CLOUDFORMATION_URL = "https://cloudformation.#{AWS_REGION}.#{AWS_DOMAIN}".freeze
INSTANCE_ROLE_NAME = "INSTANCE_ROLE_NAME".freeze
LAUNCH_TEMPLATE_ID = "LAUNCH_TEMPLATE_ID".freeze
SCRIPT_DIR = "SCRIPT_DIR".freeze
DNA_DIR = "DNA_DIR".freeze
NODE_BOOTSTRAP_TIMEOUT = "1800".freeze

describe 'cfn_hup_configuration:configure' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = runner(platform: platform, version: version, step_into: ['cfn_hup_configuration']) do |node|
          allow_any_instance_of(Object).to receive(:get_metadata_token).and_return("IMDS_TOKEN")
          allow_any_instance_of(Object).to receive(:get_metadata_with_token)
            .with("IMDS_TOKEN", URI("http://169.254.169.254/latest/meta-data/iam/security-credentials"))
            .and_return(INSTANCE_ROLE_NAME)
          node.override["cluster"]["node_type"] = 'HeadNode'
          node.override["cluster"]["region"] = AWS_REGION
          node.override["cluster"]["aws_domain"] = AWS_DOMAIN
          # TODO: We inject the stack id into the attribute stack_arn when generating the dna.json in the CLI.
          #  This should be fixed at the CLI level first and adapt the cookbook accordingly.
          node.override["cluster"]["stack_arn"] = STACK_ID
          node.override["cluster"]["launch_template_id"] = LAUNCH_TEMPLATE_ID
          node.override['cluster']['scripts_dir'] = SCRIPT_DIR
          node.override['cluster']['update']['dna_dir'] = DNA_DIR
          node.override['cluster']['compute_node_bootstrap_timeout'] = NODE_BOOTSTRAP_TIMEOUT
        end
        ConvergeCfnHupConfiguration.configure(runner)
      end
      cached(:node) { chef_run.node }

      %w(/etc/cfn /etc/cfn/hooks.d).each do |dir|
        it "creates the directory #{dir}" do
          is_expected.to create_directory(dir)
            .with(owner: 'root')
            .with(group: 'root')
            .with(mode:  "0700")
            .with(recursive: true)
        end
      end

      it "creates the file /etc/cfn/cfn-hup.conf" do
        is_expected.to create_template("/etc/cfn/cfn-hup.conf")
          .with(source: 'cfn_hup_configuration/cfn-hup.conf.erb')
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
          .with(source: 'cfn_hup_configuration/cfn-hook-update.conf.erb')
          .with(user: "root")
          .with(group: "root")
          .with(mode: "0400")
          .with(variables: {
            launch_template_resource_id: LAUNCH_TEMPLATE_ID,
            stack_id: STACK_ID,
            region: AWS_REGION,
            cloudformation_url: CLOUDFORMATION_URL,
            cfn_init_role: INSTANCE_ROLE_NAME,
         })
      end

      it "creates #{SCRIPT_DIR}/manage_fleet_dna.py" do
        is_expected.to create_if_missing_cookbook_file("#{SCRIPT_DIR}/manage_fleet_dna.py")
          .with(source: 'cfn_hup_configuration/manage_fleet_dna.py')
          .with(user: 'root')
          .with(group: 'root')
          .with(mode: '0700')
      end

      it "creates the directory #{DNA_DIR}" do
        is_expected.to create_directory("#{DNA_DIR}")
      end
    end
  end
end
