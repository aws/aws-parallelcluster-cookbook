# Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
import json
from os import makedirs, path
from socket import getfqdn, gethostname

import argparse

from jinja2 import Environment, FileSystemLoader


def generate_slurm_config_files(args):
    """
    Generate Slurm configuration files.

    For each queue, generate slurm_parallelcluster_{QueueName}_partitions.conf
    and slurm_parallelcluster_{QueueName}_gres.conf, which contain node info.

    Generate slurm_parallelcluster.conf and slurm_parallelcluster_gres.conf,
    which includes queue specifc configuration files.

    slurm_parallelcluster.conf is included in main slurm.conf
    and slurm_parallelcluster_gres.conf is included in gres.conf.
    """
    queues_info = _load_queues_info(args.input_file)

    # Make output directories
    args.output_directory = path.abspath(args.output_directory)
    pcluster_subdirectory = path.join(args.output_directory, "pcluster")
    makedirs(pcluster_subdirectory, exist_ok=True)
    env = _get_jinja_env(args.template_directory)

    # Generate slurm_parallelcluster_{QueueName}_partitions.conf and slurm_parallelcluster_{QueueName}_gres.conf
    for queue in queues_info["queues_config"]:
        for file_type in ["partition", "gres"]:
            print(f"Generating slurm_parallelcluster_{queue}_{file_type}.conf")
            rendered_template = _render_queue_configs(queues_info, queue, file_type, env, pcluster_subdirectory)
            if not args.dryrun:
                filename = queues_info["queues_config"][queue][f"queue_{file_type}_filename"]
                _write_rendered_template_to_file(rendered_template, filename)

    # Generate slurm_parallelcluster.conf and slurm_parallelcluster_gres.conf
    for template_name in ["slurm_parallelcluster.conf", "slurm_parallelcluster_gres.conf"]:
        print(f"Generating {template_name}")
        rendered_template = _render_slurm_parallelcluster_configs(queues_info, template_name, env)
        if not args.dryrun:
            filename = f"{args.output_directory}/{template_name}"
            _write_rendered_template_to_file(rendered_template, filename)

    print("Finished.")


def _load_queues_info(input_file_path):
    """
    Load queues_info and add information used to render templates.

    :return: queues_info containing id for first queue, master_hostname and queue_name
    """
    with open(input_file_path) as input_file:
        queues_info = json.load(input_file)
        queues_info["master_hostname"] = gethostname()
        queues_info["master_ip"] = getfqdn()
        for queue in queues_info["queues_config"]:
            queues_info["queues_config"][queue]["queue_name"] = queue
        return queues_info


def _render_queue_configs(queues_info, queue, file_type, env, pcluster_subdirectory):
    """
    Render queue-specific config based on queues_info, and sets queue filename in queues_info.

    :return: rendered queue-specific templates
    """
    queues_info["queues_config"][queue][f"queue_{file_type}_filename"] = path.join(
        pcluster_subdirectory, f"slurm_parallelcluster_{queue}_{file_type}.conf"
    )
    return env.get_template(f"slurm_parallelcluster_queue_{file_type}.conf").render(
        queue=queues_info["queues_config"][queue]
    )


def _render_slurm_parallelcluster_configs(queues_info, template_name, env):
    """
    Render slurm_parallelcluster config based on queues_info.

    :return: rendered slurm_parallelcluster templates
    """
    return env.get_template(f"{template_name}").render(queues_info)


def _get_jinja_env(template_directory):
    """Return jinja environment with trim_blocks/lstrip_blocks set to True."""
    file_loader = FileSystemLoader(template_directory)
    return Environment(loader=file_loader, trim_blocks=True, lstrip_blocks=True)


def _write_rendered_template_to_file(rendered_template, filename):
    print(f"Writing contents of {filename}")
    with open(filename, "w") as output_file:
        output_file.write(rendered_template)


def main():
    print("Running ParallelCluster Slurm Config Generator")
    parser = argparse.ArgumentParser(description="Take in slurm configuration generator related parameters")
    parser.add_argument(
        "--output-directory", type=str, help="The output directory for generated slurm configs", required=True
    )
    parser.add_argument(
        "--template-directory", type=str, help="The directory storing slurm config templates", required=True
    )
    parser.add_argument(
        "--input-file",
        type=str,
        default="/opt/parallelcluster/slurm_config.json",
        help="JSON file containing info about queues",
    )
    parser.add_argument(
        "--dryrun", action="store_true", help="dryrun", required=False, default=False,
    )
    args = parser.parse_args()
    generate_slurm_config_files(args)


if __name__ == "__main__":
    main()
