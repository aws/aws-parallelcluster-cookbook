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
import argparse
import json
import logging
import re
import subprocess
from os import makedirs, path
from socket import gethostname

import yaml
from jinja2 import Environment, FileSystemLoader

log = logging.getLogger()
instance_types_data = {}


def generate_slurm_config_files(output_directory, template_directory, input_file, instance_types_data_path, dryrun):
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
    head_node_config = _get_head_node_config()
    queues = cluster_config["Scheduling"]["Queues"]

    global instance_types_data
    with open(instance_types_data_path) as input_file:
        instance_types_data = json.load(input_file)

    # Generate slurm_parallelcluster_{QueueName}_partitions.conf and slurm_parallelcluster_{QueueName}_gres.conf
    is_default_queue = True  # The first queue in the queues list is the default queue
    for queue in queues:
        for file_type in ["partition", "gres"]:
            _generate_queue_config(
                queue["Name"], queue, is_default_queue, file_type, env, pcluster_subdirectory, dryrun
            )
        is_default_queue = False

    # Generate slurm_parallelcluster.conf and slurm_parallelcluster_gres.conf
    for template_name in ["slurm_parallelcluster.conf", "slurm_parallelcluster_gres.conf"]:
        _generate_slurm_parallelcluster_configs(
            queues,
            head_node_config,
            cluster_config["Scheduling"]["SlurmSettings"],
            template_name,
            env,
            output_directory,
            dryrun,
        )

    generate_instance_type_mapping_file(pcluster_subdirectory, queues)

    log.info("Finished.")


def _load_cluster_config(input_file_path):
    """
    Load queues_info and add information used to render templates.

    :return: queues_info containing id for first queue, head_node_hostname and queue_name
    """
    with open(input_file_path) as input_file:
        return yaml.load(input_file, Loader=yaml.SafeLoader)


def _get_head_node_config():
    return {
        "head_node_hostname": gethostname(),
        "head_node_ip": _get_head_node_private_ip(),
    }


def _get_head_node_private_ip():
    """Get head node private ip from EC2 metadata."""
    try:
        private_ip = subprocess.run(  # nosec nosemgrep
            "curl --retry 3 http://169.254.169.254/latest/meta-data/local-ipv4",
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=True,
            encoding="utf-8",
            shell=True,
        ).stdout
        return private_ip
    except Exception:
        log.error("Encountered exception when retrieving head node private IP.")
        raise


def _generate_queue_config(queue_name, queue_config, is_default_queue, file_type, jinja_env, output_dir, dryrun):
    log.info("Generating slurm_parallelcluster_%s_%s.conf", queue_name, file_type)
    rendered_template = jinja_env.get_template(f"slurm_parallelcluster_queue_{file_type}.conf").render(
        queue_name=queue_name, queue_config=queue_config, is_default_queue=is_default_queue
    )
    if not dryrun:
        filename = path.join(output_dir, f"slurm_parallelcluster_{queue_name}_{file_type}.conf")
        _write_rendered_template_to_file(rendered_template, filename)


def _generate_slurm_parallelcluster_configs(
    queues, head_node_config, scaling_config, template_name, jinja_env, output_dir, dryrun
):
    log.info("Generating %s", template_name)
    rendered_template = jinja_env.get_template(f"{template_name}").render(
        queues=queues,
        head_node_config=head_node_config,
        scaling_config=scaling_config,
        output_dir=output_dir,
    )
    if not dryrun:
        filename = f"{output_dir}/{template_name}"
        _write_rendered_template_to_file(rendered_template, filename)


def _get_jinja_env(template_directory):
    """Return jinja environment with trim_blocks/lstrip_blocks set to True."""
    file_loader = FileSystemLoader(template_directory)
    # A nosec comment is appended to the following line in order to disable the B701 check.
    # The contents of the default templates are known and the input configuration data is
    # validated by the CLI.
    env = Environment(loader=file_loader, trim_blocks=True, lstrip_blocks=True)  # nosec nosemgrep
    env.filters["sanify_instance_type"] = lambda value: re.sub(r"[^A-Za-z0-9]", "", value)
    env.filters["gpus"] = lambda instance_type: _gpu_count(instance_type)
    env.filters["gpu_type"] = lambda instance_type: _gpu_type(instance_type)
    env.filters["vcpus"] = lambda compute_resource: _vcpus(compute_resource)

    return env


def _gpu_count(instance_type):
    """Return the number of GPUs for the instance."""
    gpu_info = instance_types_data[instance_type].get("GpuInfo", None)

    gpu_count = 0
    if gpu_info:
        for gpus in gpu_info.get("Gpus", []):
            gpu_manufacturer = gpus.get("Manufacturer", "")
            if gpu_manufacturer.upper() == "NVIDIA":
                gpu_count += gpus.get("Count", 0)
            else:
                log.info(
                    f"ParallelCluster currently does not offer native support for '{gpu_manufacturer}' GPUs. "
                    "Please make sure to use a custom AMI with the appropriate drivers in order to leverage "
                    "GPUs functionalities"
                )

    return gpu_count


def _gpu_type(instance_type):
    """Return name or type of the GPU for the instance."""
    gpu_info = instance_types_data[instance_type].get("GpuInfo", None)
    # Remove space and change to all lowercase for name
    return "no_gpu_type" if not gpu_info else gpu_info.get("Gpus")[0].get("Name").replace(" ", "").lower()


def _vcpus(compute_resource) -> int:
    """Get the number of vcpus for the instance according to disable_hyperthreading and instance features."""
    instance_type = compute_resource["InstanceType"]
    disable_simultaneous_multithreading = compute_resource["DisableSimultaneousMultithreading"]
    instance_type_info = instance_types_data[instance_type]
    vcpus_info = instance_type_info.get("VCpuInfo", {})
    vcpus_count = vcpus_info.get("DefaultVCpus")
    threads_per_core = vcpus_info.get("DefaultThreadsPerCore")
    if threads_per_core is None:
        supported_architectures = instance_type_info.get("ProcessorInfo", {}).get("SupportedArchitectures", [])
        threads_per_core = 2 if "x86_64" in supported_architectures else 1
    return vcpus_count if not disable_simultaneous_multithreading else (vcpus_count // threads_per_core)


def _write_rendered_template_to_file(rendered_template, filename):
    log.info("Writing contents of %s", filename)
    with open(filename, "w") as output_file:
        output_file.write(rendered_template)


def _setup_logger():
    logging.basicConfig(
        level=logging.INFO, format="%(asctime)s - [%(name)s:%(funcName)s] - %(levelname)s - %(message)s"
    )


def generate_instance_type_mapping_file(output_dir, queues):
    """Generate a mapping file to retrieve the Instance Type related to the instance key used in the slurm nodename."""
    instance_name_type_mapping = {}
    for queue in queues:
        compute_resources = queue["ComputeResources"]
        hostname_regex = re.compile("[^A-Za-z0-9]")
        for compute_resource in compute_resources:
            instance_type = compute_resource.get("InstanceType")
            # Remove all characters excepts letters and numbers
            sanitized_instance_type = re.sub(hostname_regex, "", instance_type)
            instance_name_type_mapping[sanitized_instance_type] = instance_type

    filename = f"{output_dir}/instance_name_type_mappings.json"
    log.info("Generating %s", filename)
    with open(filename, "w") as output_file:
        output_file.write(json.dumps(instance_name_type_mapping, indent=4))


def main():
    try:
        _setup_logger()
        log.info("Running ParallelCluster Slurm Config Generator")
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
            # Todo: is the default necessary?
            default="/opt/parallelcluster/slurm_config.json",
            help="Yaml file containing pcluster configuration file",
        )
        parser.add_argument(
            "--instance-types-data",
            type=str,
            help="JSON file containing info about instance types",
        )
        parser.add_argument(
            "--dryrun",
            action="store_true",
            help="dryrun",
            required=False,
            default=False,
        )
        args = parser.parse_args()
        generate_slurm_config_files(
            args.output_directory, args.template_directory, args.input_file, args.instance_types_data, args.dryrun
        )
    except Exception as e:
        log.exception("Failed to generate slurm configurations, exception: %s", e)
        raise


if __name__ == "__main__":
    main()
