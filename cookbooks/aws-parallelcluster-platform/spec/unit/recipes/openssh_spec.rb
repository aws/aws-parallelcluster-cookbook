require 'spec_helper'

describe 'aws-parallelcluster-platform::openssh' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = runner(platform: platform, version: version) do |node|
          node.override['ec2']['mac'] = "mac1"
          node.override['ec2']['network_interfaces_macs']["mac1"]['vpc_ipv4_cidr_blocks'] = "cidr1\ncidr2"
        end
        runner.converge(described_recipe)
      end
      cached(:node) { chef_run.node }

      it 'installs the ssh target checker with the correct attributes' do
        is_expected.to create_template('/usr/bin/ssh_target_checker.sh').with(
          source: "openssh/ssh_target_checker.sh.erb",
          owner: 'root',
          group: 'root',
          mode:  '0755',
          variables: {
            vpc_cidr_list: get_vpc_cidr_list,
          }
        )
      end

      it 'has the correct content' do
        is_expected.to render_file("/usr/bin/ssh_target_checker.sh")
          .with_content("VPC_CIDR_LIST=(cidr1 cidr2)")
      end
    end
  end
end
