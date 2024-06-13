# frozen_string_literal: true

#
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

return if on_docker?

if node['cluster']['node_type'] == 'HeadNode'
  # Restore the shared storage home data if it doesn't already exist
  # This is necessary to preserve any data in these directories that was
  # generated during the node bootstrap after converting to shared storage.
  # Before removing the backup, ensure the data in the new home is the same
  # as the original to avoid any data loss or inconsistency. This is done
  # by using rsync to copy the data and diff to check for differences.
  # The diff command excludes files that were originally in /home to focus on
  # the newly synchronized files. This approach is necessary because the /home
  # directory may contain pre-existing files such as slurm-*.out generated by
  # running SLURM jobs and the automatically created lost+found directory.
  # Remove the backup after the copy is done and the data integrity is verified.
  bash "Restore /home" do
    user 'root'
    group 'root'
    code <<-EOH
      # Generate a list of existing files and dirs in /home before the sync
      find /home -mindepth 1 > /tmp/home_existing_files.txt

      # Initialize an empty set for exclude options and directories to exclude
      declare -A exclude_dirs
      
      touch /tmp/exclude_options.txt

      # Process each file and directory in the list to determine which paths should be excluded from the diff check
      while IFS= read -r file; do
        # Remove the /home/ prefix
        relative_path=${file#/home/}
        current_path="/tmp/home"

        # Split the relative path by /
        IFS='/' read -ra parts <<< "$relative_path"

        for part in "${parts[@]}"; do
          current_path="$current_path/$part"
          if [ ! -e "$current_path" ]; then
            # If the path does not exist in /tmp/home, add the last part of path to the exclude list
            if [ -z "${exclude_dirs[$part]}" ]; then
              exclude_dirs[$part]=1
              echo $part >> /tmp/exclude_options.txt
            fi
            break
          else
            if [ -f "$current_path" ]; then
              # If the path is a file, add it to the exclude list
              echo $part >> /tmp/exclude_options.txt
              break
            fi
            # If the path is a directory, continue checking subdirectories
          fi
        done
      done < /tmp/home_existing_files.txt

      # Sync data from /tmp/home to /home
      rsync -a --ignore-existing /tmp/home/ /home

      # Perform the diff check, excluding the original files
      diff_output=$(diff -r --exclude-from=/tmp/exclude_options.txt /tmp/home /home)
      if [ $? -eq 0 ]; then
        rm -rf /tmp/home/
        rm -rf /tmp/home_existing_files.txt
        rm -rf /tmp/exclude_options.txt
      else
        echo "Data integrity check failed comparing /home and /tmp/home: $diff_output"
        exit 1
      fi
    EOH
  end
end
