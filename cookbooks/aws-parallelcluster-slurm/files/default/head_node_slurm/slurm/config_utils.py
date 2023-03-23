import math
from typing import List, Tuple


def _get_instance_types(compute_resource_config) -> List[str]:
    """Return the InstanceTypes defined in the ComputeResource always as list."""
    if compute_resource_config.get("Instances"):
        return [instance.get("InstanceType") for instance in compute_resource_config["Instances"]]
    else:
        return [compute_resource_config["InstanceType"]]


def _get_efa_settings(compute_resource_config) -> Tuple[bool, bool]:
    """Return a Tuple with EFA flags."""
    if "Efa" in compute_resource_config:
        efa = compute_resource_config["Efa"]
        return efa["Enabled"], efa["GdrSupport"]
    else:
        return False, False


def _get_real_memory(compute_resource_config, instance_types, instance_types_data, memory_ratio) -> int:
    """Get the RealMemory parameter to be added to the Slurm compute node configuration."""
    schedulable_memory = compute_resource_config.get("SchedulableMemory", None)
    if schedulable_memory is None:
        ec2_memory = _get_min_ec2_memory(instance_types, instance_types_data)
        return math.floor(ec2_memory * memory_ratio)
    else:
        return schedulable_memory


def _get_min_ec2_memory(instance_types, instance_types_data) -> int:
    """Return min value for EC2 memory in the instance type list."""
    min_ec2_memory = None
    for instance_type in instance_types:
        instance_type_info = instance_types_data[instance_type]
        # The instance_types_data does not have memory information for the requested instance type.
        # In this case we set RealMemory to 1 (Slurm default value for RealMemory)
        ec2_memory = instance_type_info.get("MemoryInfo", {}).get("SizeInMiB", 1)
        if min_ec2_memory is None or ec2_memory < min_ec2_memory:
            min_ec2_memory = ec2_memory
        if min_ec2_memory == 1:
            # ec2 memory lower bound
            break
    return min_ec2_memory


def _get_min_vcpus(instance_types, instance_types_data) -> Tuple[int, int]:
    """Return min value for vCPUs and threads per core in the instance type list."""
    min_vcpus_count = None
    min_threads_per_core = None
    for instance_type in instance_types:
        instance_type_info = instance_types_data[instance_type]
        vcpus_info = instance_type_info.get("VCpuInfo", {})
        # The instance_types_data does not have vCPUs information for the requested instance type.
        # In this case we set vCPUs to 1
        vcpus_count = vcpus_info.get("DefaultVCpus", 1)
        if min_vcpus_count is None or vcpus_count < min_vcpus_count:
            min_vcpus_count = vcpus_count
        threads_per_core = vcpus_info.get("DefaultThreadsPerCore")
        if threads_per_core is None:
            supported_architectures = instance_type_info.get("ProcessorInfo", {}).get("SupportedArchitectures", [])
            threads_per_core = 2 if "x86_64" in supported_architectures else 1
        if min_threads_per_core is None or threads_per_core < min_threads_per_core:
            min_threads_per_core = threads_per_core
        if min_vcpus_count == 1 and min_threads_per_core == 1:
            # vcpus and threads numbers lower bound
            break
    return min_vcpus_count, min_threads_per_core


def _get_min_gpu_count_and_type(instance_types, instance_types_data, log) -> Tuple[int, str]:
    """Return min value for GPU and associated type in the instance type list."""
    min_gpu_count = None
    gpu_type_min_count = "no_gpu_type"
    for instance_type in instance_types:
        gpu_info = instance_types_data[instance_type].get("GpuInfo", None)
        gpu_count = 0
        gpu_type = "no_gpu_type"
        if gpu_info:
            for gpus in gpu_info.get("Gpus", []):
                gpu_manufacturer = gpus.get("Manufacturer", "")
                if gpu_manufacturer.upper() == "NVIDIA":
                    gpu_count += gpus.get("Count", 0)
                    gpu_type = gpus.get("Name").replace(" ", "").lower()
                else:
                    log.info(
                        "ParallelCluster currently does not offer native support for '%s' GPUs. "
                        "Please make sure to use a custom AMI with the appropriate drivers in order to leverage "
                        "GPUs functionalities",
                        gpu_manufacturer,
                    )
        if min_gpu_count is None or gpu_count < min_gpu_count:
            min_gpu_count = gpu_count
            gpu_type_min_count = gpu_type
        if min_gpu_count == 0:
            # gpu number lower bound
            break
    return min_gpu_count, gpu_type_min_count
