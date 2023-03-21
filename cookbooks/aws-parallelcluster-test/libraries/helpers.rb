# frozen_string_literal: true

# Copyright:: 2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

def check_process_running_as_user(process, user)
  bash "check #{process} running as #{user}" do
    cwd Chef::Config[:file_cache_path]
    code <<-TEST
      pgrep -x #{process} 1>/dev/null
      if [[ $? != 0 ]]; then
        >&2 echo "Expected #{process} to be running"
        exit 1
      fi

      pgrep -x #{process} -u #{user} 1>/dev/null
      if [[ $? != 0 ]]; then
        >&2 echo "Expected #{process} to be running as #{user}"
        exit 1
      fi
    TEST
  end
end

def check_user_definition(user, uid, gid, description, shell = "/bin/bash")
  bash "check user definition for user #{user}" do
    cwd Chef::Config[:file_cache_path]
    code <<-TEST
    expected_passwd_line="#{user}:x:#{uid}:#{gid}:#{description}:/home/#{user}:#{shell}"
    actual_passwd_line=$(grep #{user} /etc/passwd)
    if [[ "$actual_passwd_line" != "$expected_passwd_line" ]]; then
      >&2 echo "Expected user #{user} in /etc/passwd: $expected_passwd_line"
      >&2 echo "Actual user #{user} in /etc/passwd: $actual_passwd_line"
      exit 1
    fi
    TEST
  end
end

def check_group_definition(group, gid)
  bash "check group definition for group #{group}" do
    cwd Chef::Config[:file_cache_path]
    code <<-TEST
    expected_group_line="#{group}:x:#{gid}:"
    actual_group_line=$(grep #{group} /etc/group)
    if [[ "$actual_group_line" != "$expected_group_line" ]]; then
      >&2 echo "Expected group #{group} in /etc/group: $expected_passwd_line"
      >&2 echo "Actual group #{group} in /etc/group: $actual_passwd_line"
      exit 1
    fi
    TEST
  end
end

def check_path_permissions(path, user, group, permissions)
  bash "check permissions on path #{path}" do
    cwd Chef::Config[:file_cache_path]
    code <<-TEST
      if [[ ! -d "#{path}" ]]; then
        >&2 echo "Expected path does not exist: #{path}"
        exit 1
      fi

      expected_permissions="#{permissions} #{user} #{group}"
      actual_permissions=$(stat "#{path}" -c "%A %U %G")
      if [[ "$actual_permissions" != "$expected_permissions" ]]; then
        >&2 echo "Expected permissions on path #{path}: $expected_permissions"
        >&2 echo "Actual permissions on path #{path}: $actual_permissions"
        exit 1
      fi
    TEST
  end
end

def check_sudoers_permissions(sudoers_file, user, run_as, command_alias, *commands)
  bash "check user #{user} can sudo as user #{run_as} on commands #{commands.join(',')}" do
    cwd Chef::Config[:file_cache_path]
    code <<-TEST
      if [[ ! -f "#{sudoers_file}" ]]; then
        >&2 echo "Expected sudoers file does not exist: #{sudoers_file}"
        exit 1
      fi

      expected_user_line="#{user} ALL = (#{run_as}) NOPASSWD: #{command_alias}"
      actual_user_line=$(grep "^#{user} .* #{command_alias}" "#{sudoers_file}")
      if [[ "$actual_user_line" != "$expected_user_line" ]]; then
        >&2 echo "Expected user line in #{sudoers_file}: $expected_user_line"
        >&2 echo "Actual user line in #{sudoers_file}: $actual_user_line"
        exit 1
      fi

      expected_commands_line="Cmnd_Alias #{command_alias} = #{commands.join(',')}"
      actual_commands_line=$(grep "Cmnd_Alias #{command_alias}" "#{sudoers_file}")
      if [[ "$actual_commands_line" != "$expected_commands_line" ]]; then
        >&2 echo "Expected commands line in #{sudoers_file}: $expected_commands_line"
        >&2 echo "Actual commands line in #{sudoers_file}: $actual_commands_line"
        exit 1
      fi
    TEST
  end
end

def check_imds_access(user, is_allowed)
  bash "check IMDS access for user #{user}" do
    cwd Chef::Config[:file_cache_path]
    code <<-TEST
      sudo -u #{user} curl -H "X-aws-ec2-metadata-token-ttl-seconds: 900" -X PUT "http://169.254.169.254/latest/api/token" 1>/dev/null 2>/dev/null
      [[ $? = 0 ]] && actual_is_allowed="true" || actual_is_allowed="false"
      if [[ "$actual_is_allowed" != "#{is_allowed}" ]]; then
        >&2 echo "User #{is_allowed ? 'should' : 'should not'} have access to IMDS (IPv4): #{user}"
        exit 1
      fi

      token=$(sudo curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
      region=$(sudo curl -H "X-aws-ec2-metadata-token: ${token}" -v http://169.254.169.254/latest/meta-data/placement/region)
      instance_id=$(sudo curl -H "X-aws-ec2-metadata-token: ${token}" -v http://169.254.169.254/latest/meta-data/instance-id)
      http_protocol_ipv6=$(aws --region ${region} ec2 describe-instances --instance-ids "${instance_id}" --query "Reservations[*].Instances[*].MetadataOptions.HttpProtocolIpv6" --output text)

      if [[ "$http_protocol_ipv6" == "enabled" ]]; then
        sudo -u #{user} curl -g -6 -H "X-aws-ec2-metadata-token-ttl-seconds: 900" -X PUT "http://[fd00:ec2::254]/latest/api/token" 1>/dev/null 2>/dev/null
        [[ $? = 0 ]] && actual_is_allowed="true" || actual_is_allowed="false"
        if [[ "$actual_is_allowed" != "#{is_allowed}" ]]; then
          >&2 echo "User #{is_allowed ? 'should' : 'should not'} have access to IMDS (IPv6): #{user}"
          exit 1
        fi
      else
        >&2 echo "http protocol ipv6 is: ${http_protocol_ipv6}, skipping imds ipv6 test"
      fi
    TEST
  end
end

# Check that the iptables backup file exists
def check_iptables_rules_file(file)
  bash "check iptables rules backup file exists: #{file}" do
    cwd Chef::Config[:file_cache_path]
    code <<-TEST
      if [[ ! -f #{file} ]]; then
        >&2 echo "Missing expected iptables rules file: #{file}"
        exit 1
      fi
    TEST
  end
end

# Check that PATH includes directories for the given user.
# If user is specified, PATH is checked in the login shell for that user.
# Otherwise, PATH is checked in the current recipes context.
def check_directories_in_path(directories, user = nil)
  context = user.nil? ? 'recipes context' : "user #{user}"
  bash "check PATH for #{context} contains #{directories}" do
    cwd Chef::Config[:file_cache_path]
    code <<-TEST
      #{user.nil? ? nil : "sudo su - #{user}"}

      for directory in #{directories.join(' ')}; do
        [[ ":$PATH:" == *":$directory:"* ]] || missing_directories="$missing_directories $directory"
      done

      if [[ ! -z $missing_directories ]]; then
        >&2 echo "Missing expected directories in PATH for #{context}: $missing_directories"
        exit 1
      fi
    TEST
  end
end

def check_run_level_script(script_name, levels_on, levels_off)
  bash "check run level script #{script_name}" do
    cwd Chef::Config[:file_cache_path]
    code <<-TEST
      set -x
      set -o pipefail

      for level in #{levels_on.join(' ')}; do
        ls /etc/rc$level.d/ | egrep '^S[0-9]+#{script_name}$' > /dev/null
        [[ $? == 0 ]] || missing_levels_on="$missing_levels_on $level"
      done

      for level in #{levels_off.join(' ')}; do
        ls /etc/rc$level.d/ | egrep '^K[0-9]+#{script_name}$' > /dev/null
        [[ $? == 0 ]] || missing_levels_off="$missing_levels_off $level"
      done

      if [[ ! -z $missing_levels_on || ! -z $missing_levels_off ]]; then
        >&2 echo "Misconfigured run level script #{script_name}"
        >&2 echo "Expected levels on are (#{levels_on.join(' ')}). Missing levels on are ($missing_levels_on)"
        >&2 echo "Expected levels off are (#{levels_off.join(' ')}). Missing levels off are ($missing_levels_off)"
        exit 1
      fi
    TEST
  end
end

#
# Check if a service is disabled
#
def is_service_disabled(service, platform_families = node['platform_family'])
  if platform_family?(platform_families)
    execute "check #{service} service is disabled" do
      command "systemctl is-enabled #{service} && exit 1 || exit 0"
    end
  end
end

def validate_package_source(package, expected_source)
  case node['platform']
  when 'amazon', 'centos'
    test_expression = "$(yum info #{package} | grep 'From repo' | awk '{print $4}')"
  when 'ubuntu'
    test_expression = "$(apt show #{package} | grep 'APT-Sources:' | awk '{print $2}')"
  else
    raise "Platform not supported: #{node['platform']}"
  end

  bash "Check that package #{package} is installed" do
    cwd Chef::Config[:file_cache_path]
    code <<-TEST
      echo "Testing package #{package} source"
      actual_source=#{test_expression}
      if [ "#{expected_source}" != "${actual_source}" ]; then
        echo "ERROR Expected package source #{expected_source} for #{package} does not match actual source: ${actual_source}"
        exit 1
      fi
      echo "#{package} correctly installed from #{expected_source}"
    TEST
  end
end

def validate_package_version(package, expected_version)
  case node['platform']
  when 'amazon', 'centos', 'redhat'
    test_expression = "$(yum info installed #{package} | grep 'Version' | awk '{print $3}')"
  when 'ubuntu'
    test_expression = "$(apt list --installed #{package} | awk '{printf \"%s\", $2}')"
  else
    raise "Platform not supported: #{node['platform']}"
  end

  bash "Check that package #{package} v#{expected_version} is installed" do
    cwd Chef::Config[:file_cache_path]
    code <<-TEST
      echo "Testing package #{package} version"
      actual_version=#{test_expression}
      if [ "#{expected_version}" != "${actual_version}" ]; then
        echo "ERROR Expected package source #{expected_version} for #{package} does not match actual source: ${actual_version}"
        exit 1
      fi
      echo "#{package} correctly installed version #{expected_version}"
    TEST
  end
end
