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


def generate_slurm_config_files(output_directory, template_directory, input_file, dryrun):
    """
    Generate Slurm configuration files.

    For each queue, generate slurm_parallelcluster_{QueueName}_partitions.conf
    and slurm_parallelcluster_{QueueName}_gres.conf, which contain node info.

    Generate slurm_parallelcluster.conf and slurm_parallelcluster_gres.conf,
    which includes queue specifc configuration files.

    slurm_parallelcluster.conf is included in main slurm.conf
    and slurm_parallelcluster_gres.conf is included in gres.conf.
    """
    # Make output directories
    output_directory = path.abspath(output_directory)
    pcluster_subdirectory = path.join(output_directory, "pcluster")
    makedirs(pcluster_subdirectory, exist_ok=True)
    env = _get_jinja_env(template_directory)

    cluster_config = _load_cluster_config(input_file)
    master_config = _get_master_config()
    queue_settings = cluster_config["cluster"]["queue_settings"]

    # Generate slurm_parallelcluster_{QueueName}_partitions.conf and slurm_parallelcluster_{QueueName}_gres.conf
    for queue_name, queue_config in queue_settings.items():
        is_default_queue = cluster_config["cluster"]["default_queue"] == queue_name
        for file_type in ["partition", "gres"]:
            _generate_queue_config(
                queue_name, queue_config, is_default_queue, file_type, env, pcluster_subdirectory, dryrun
            )

    # Generate slurm_parallelcluster.conf and slurm_parallelcluster_gres.conf
    for template_name in ["slurm_parallelcluster.conf", "slurm_parallelcluster_gres.conf"]:
        _generate_slurm_parallelcluster_configs(
            queue_settings,
            master_config,
            cluster_config["cluster"]["scaling"],
            template_name,
            env,
            output_directory,
            dryrun,
        )

    print("Finished.")


def _load_cluster_config(input_file_path):
    """
    Load queues_info and add information used to render templates.

    :return: queues_info containing id for first queue, master_hostname and queue_name
    """
    with open(input_file_path) as input_file:
        return json.load(input_file)


def _get_master_config():
    return {
        "master_hostname": gethostname(),
        "master_ip": getfqdn(),
    }


def _generate_queue_config(queue_name, queue_config, is_default_queue, file_type, jinja_env, output_dir, dryrun):
    print(f"Generating slurm_parallelcluster_{queue_name}_{file_type}.conf")
    rendered_template = jinja_env.get_template(f"slurm_parallelcluster_queue_{file_type}.conf").render(
        queue_name=queue_name, queue_config=queue_config, is_default_queue=is_default_queue
    )
    if not dryrun:
        filename = path.join(output_dir, f"slurm_parallelcluster_{queue_name}_{file_type}.conf")
        _write_rendered_template_to_file(rendered_template, filename)


def _generate_slurm_parallelcluster_configs(
    queues_config, master_config, scaling_config, template_name, jinja_env, output_dir, dryrun
):
    print(f"Generating {template_name}")
    rendered_template = jinja_env.get_template(f"{template_name}").render(
        queues_config=queues_config, master_config=master_config, scaling_config=scaling_config, output_dir=output_dir
    )
    if not dryrun:
        filename = f"{output_dir}/{template_name}"
        _write_rendered_template_to_file(rendered_template, filename)


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
    generate_slurm_config_files(args.output_directory, args.template_directory, args.input_file, args.dryrun)


if __name__ == "__main__":
    main()
