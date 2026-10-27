# Copyright 2026 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

"""Reading the AWS resources the cluster configuration references, as AWS describes them.

The resources are the security groups, the subnets with their route tables, network ACLs and VPC endpoints, the IAM
instance profiles, roles and policies, the scripts of the custom actions and the existing shared storage the cluster
configuration references, plus the security groups, the subnet and the IAM role of the node itself, the security
groups the cluster stack manages, and the launch templates of the compute resources and login node pools, with the
security groups and the instance profiles the nodes launch with. Each resource is read on its own: one that
cannot be read, e.g. because the credentials do not allow it, is recorded with its error, and the others are still
read.
"""

import http.client
import json
import logging
from typing import Any, Dict, Iterator, List, NamedTuple, Optional, Set, Tuple
from urllib.parse import urljoin, urlparse

import boto3
from botocore.config import Config
from botocore.exceptions import BotoCoreError, ClientError

from pcluster_diag.core.constants import (
    AWS_READ_TIMEOUT_SECONDS,
    CUSTOM_ACTION_SCRIPT_MAX_BYTES,
    CUSTOM_ACTION_SCRIPT_TIMEOUT_SECONDS,
    MANAGED_SECURITY_GROUP_LOGICAL_IDS,
)
from pcluster_diag.util import imds
from pcluster_diag.util.config_files import redact_secrets

logger = logging.getLogger(__name__)

_CLIENT_CONFIG = Config(
    connect_timeout=AWS_READ_TIMEOUT_SECONDS, read_timeout=AWS_READ_TIMEOUT_SECONDS, retries={"max_attempts": 3}
)
# The IAM service prefix of the boto3 clients whose name differs from it.
_IAM_SERVICE_PREFIXES = {"efs": "elasticfilesystem"}
# The keys of the cluster configuration, at any depth, listing security groups and subnets.
_SECURITY_GROUP_KEYS = ("SecurityGroups", "AdditionalSecurityGroups")
_SUBNET_KEYS = ("SubnetId", "SubnetIds")
# The existing shared storage, by StorageType: the settings holding its id, the id key, and how to describe it (the
# boto3 client and operation, the parameter taking the id, which is a list when plural, and the response list key).
_SHARED_STORAGE = {
    "Ebs": ("EbsSettings", "VolumeId", "ec2", "describe_volumes", "VolumeIds", "Volumes"),
    "Efs": ("EfsSettings", "FileSystemId", "efs", "describe_file_systems", "FileSystemId", "FileSystems"),
    "FsxLustre": ("FsxLustreSettings", "FileSystemId", "fsx", "describe_file_systems", "FileSystemIds", "FileSystems"),
    "FsxOntap": ("FsxOntapSettings", "VolumeId", "fsx", "describe_volumes", "VolumeIds", "Volumes"),
    "FsxOpenZfs": ("FsxOpenZfsSettings", "VolumeId", "fsx", "describe_volumes", "VolumeIds", "Volumes"),
    "FileCache": ("FileCacheSettings", "FileCacheId", "fsx", "describe_file_caches", "FileCacheIds", "FileCaches"),
}
# A custom action script is downloaded as the custom action executor does, with requests.get: it follows up to 30
# redirects (the requests default), to HTTPS or HTTP URLs.
_MAX_REDIRECTS = 30
_REDIRECT_STATUSES = (301, 302, 303, 307, 308)
_CONNECTIONS = {"https": http.client.HTTPSConnection, "http": http.client.HTTPConnection}
# The prefix of the ARNs of the AWS managed policies: their documents are public, so they are not read.
_AWS_MANAGED_POLICY_PREFIX = ":iam::aws:policy/"


class ReadFailure(NamedTuple):
    """A resource that could not be read: the IAM action (e.g. ``ec2:DescribeSecurityGroups``) and the error code."""

    action: str
    error: str


class ResourceReader:
    """Read the resources referenced by a cluster configuration, recording the reads that fail in ``failures``."""

    def __init__(self, region: str) -> None:
        """Create a reader of the resources in ``region``."""
        self._region = region
        self._clients: Dict[str, Any] = {}
        self.failures: List[ReadFailure] = []
        # The route tables and network ACLs of the subnets, by id: subnets often share them, so they are listed once.
        self._route_tables: Dict[str, dict] = {}
        self._network_acls: Dict[str, dict] = {}

    def read(
        self,
        cluster_config: dict,
        stack_name: Optional[str],
        instance_id: Optional[str],
        launch_templates_path: Optional[str] = None,
    ) -> dict:
        """Return the resources referenced by ``cluster_config``, the cluster stack and the instance ``instance_id``.

        ``launch_templates_path`` is the launch templates config the head node keeps, listing the launch template of
        every compute resource and login node pool; without it, no launch template is read.
        """
        launch_templates = self._launch_templates(launch_templates_path) if launch_templates_path else []
        launch_template_data = [template.get("LaunchTemplateData") or {} for template in launch_templates]
        shared_storage = self._shared_storage(cluster_config)
        instance_security_groups, instance_subnet = self._instance_network(instance_id)
        security_group_ids = set(_config_values(cluster_config, _SECURITY_GROUP_KEYS)) | instance_security_groups
        security_group_ids |= {group_id for data in launch_template_data for group_id in _launch_security_groups(data)}
        security_group_ids |= self._managed_security_groups(stack_name)
        security_group_ids |= {
            group_id
            for storage in shared_storage
            for mount_target in storage.get("MountTargets", [])
            for group_id in mount_target.get("SecurityGroups", [])
        }
        policy_arns = {
            policy.get("Policy")
            for policies in _config_values(cluster_config, ("AdditionalIamPolicies",))
            for policy in (policies if isinstance(policies, list) else [])
            if isinstance(policy, dict) and policy.get("Policy")
        }
        instance_profile_names = {_arn_name(arn) for arn in _config_values(cluster_config, ("InstanceProfile",))}
        instance_profile_names |= {
            _arn_name(profile.get("Arn") or profile.get("Name") or "")
            for profile in (data.get("IamInstanceProfile") or {} for data in launch_template_data)
            if profile.get("Arn") or profile.get("Name")
        }
        instance_profiles = [self._instance_profile(name) for name in sorted(instance_profile_names)]
        role_names = {role for profile in instance_profiles for role in profile.get("Roles", [])}
        role_names |= {_arn_name(arn) for arn in _config_values(cluster_config, ("InstanceRole",))}
        role_names |= self._instance_role()
        roles = [self._role(name, policy_arns) for name in sorted(role_names)]
        subnet_ids = set(_config_values(cluster_config, _SUBNET_KEYS)) | (
            {instance_subnet} if instance_subnet else set()
        )
        subnets = [self._subnet(subnet_id) for subnet_id in sorted(subnet_ids)]
        vpc_ids = sorted({subnet["VpcId"] for subnet in subnets if subnet.get("VpcId")})
        return {
            "launch_templates": launch_templates,
            "security_groups": [self._security_group(group_id) for group_id in sorted(security_group_ids)],
            "subnets": subnets,
            "route_tables": [self._route_tables[table_id] for table_id in sorted(self._route_tables)],
            "network_acls": [self._network_acls[acl_id] for acl_id in sorted(self._network_acls)],
            "vpcs": [self._vpc(vpc_id) for vpc_id in vpc_ids],
            "iam_instance_profiles": instance_profiles,
            "iam_roles": roles,
            "iam_policies": [self._policy(arn) for arn in sorted(policy_arns)],
            "custom_action_scripts": [self._script(url) for url in sorted(set(_custom_action_scripts(cluster_config)))],
            "shared_storage": shared_storage,
        }

    def _security_group(self, group_id: str) -> dict:
        """Return the security group ``group_id`` with its rules."""
        entry = {"GroupId": group_id}
        response = self._call(entry, "ec2", "describe_security_groups", GroupIds=[group_id])
        if response:
            entry.update(_first(response, "SecurityGroups"))
        return entry

    def _instance_network(self, instance_id: Optional[str]) -> Tuple[Set[str], Optional[str]]:
        """Return the ids of the security groups and of the subnet of the instance ``instance_id``."""
        if not instance_id:
            return set(), None
        response = self._call({}, "ec2", "describe_instances", InstanceIds=[instance_id])
        instance = _first(_first(response or {}, "Reservations"), "Instances")
        return {group["GroupId"] for group in instance.get("SecurityGroups", [])}, instance.get("SubnetId")

    def _subnet(self, subnet_id: str) -> dict:
        """Return the subnet ``subnet_id`` with the ids of its route table and network ACL, which are kept apart.

        The associations of the route table and network ACL are left out: they list every subnet using them.
        """
        entry: Dict[str, Any] = {"SubnetId": subnet_id}
        response = self._call(entry, "ec2", "describe_subnets", SubnetIds=[subnet_id])
        if response:
            entry.update(_first(response, "Subnets"))
        associated = [{"Name": "association.subnet-id", "Values": [subnet_id]}]
        route_tables = self._call(entry, "ec2", "describe_route_tables", Filters=associated)
        if route_tables is not None and not route_tables.get("RouteTables") and entry.get("VpcId"):
            # A subnet without an explicit association uses the main route table of its VPC.
            main = [{"Name": "vpc-id", "Values": [entry["VpcId"]]}, {"Name": "association.main", "Values": ["true"]}]
            route_tables = self._call(entry, "ec2", "describe_route_tables", Filters=main)
        if route_tables and route_tables.get("RouteTables"):
            route_table = _without(_first(route_tables, "RouteTables"), "Associations")
            entry["RouteTableId"] = route_table.get("RouteTableId")
            self._route_tables.setdefault(entry["RouteTableId"], route_table)
        network_acls = self._call(entry, "ec2", "describe_network_acls", Filters=associated)
        if network_acls and network_acls.get("NetworkAcls"):
            network_acl = _without(_first(network_acls, "NetworkAcls"), "Associations")
            entry["NetworkAclId"] = network_acl.get("NetworkAclId")
            self._network_acls.setdefault(entry["NetworkAclId"], network_acl)
        return entry

    def _vpc(self, vpc_id: str) -> dict:
        """Return the VPC ``vpc_id`` with its VPC endpoints, through which the nodes may reach the AWS services."""
        entry: Dict[str, Any] = {"VpcId": vpc_id}
        response = self._call(entry, "ec2", "describe_vpc_endpoints", Filters=[{"Name": "vpc-id", "Values": [vpc_id]}])
        if response:
            entry["VpcEndpoints"] = response.get("VpcEndpoints", [])
        return entry

    def _managed_security_groups(self, stack_name: Optional[str]) -> Set[str]:
        """Return the ids of the security groups the cluster stack creates, when it creates them."""
        group_ids = set()
        for logical_id in MANAGED_SECURITY_GROUP_LOGICAL_IDS if stack_name else ():
            try:
                response = self._client("cloudformation").describe_stack_resource(
                    StackName=stack_name, LogicalResourceId=logical_id
                )
            except ClientError as error:
                # The stack has no such resource when the cluster configuration sets its own security groups.
                if _error_code(error) != "ValidationError":
                    self.failures.append(ReadFailure("cloudformation:DescribeStackResource", _error_code(error)))
                continue
            except BotoCoreError as error:
                self.failures.append(ReadFailure("cloudformation:DescribeStackResource", str(error)))
                continue
            group_ids.add(response["StackResourceDetail"]["PhysicalResourceId"])
        return group_ids

    def _launch_templates(self, path: str) -> List[dict]:
        """Return the launch template of every compute resource and login node pool listed in the config at ``path``.

        The user data is left out: it is the same bootstrap script for every node, and the largest part of a template.
        """
        try:
            with open(path, encoding="utf-8") as config_file:
                config = json.load(config_file) or {}
        except (OSError, ValueError) as error:
            logger.warning("Could not read the launch templates config %s: %s", path, error)
            self.failures.append(ReadFailure(path, type(error).__name__))
            return []
        entries = []
        for queue, queue_config in sorted((config.get("Queues") or {}).items()):
            for compute_resource, resource_config in sorted((queue_config.get("ComputeResources") or {}).items()):
                entry = {"Queue": queue, "ComputeResource": compute_resource}
                entries.append(self._launch_template(entry, resource_config.get("LaunchTemplate") or {}))
        for pool, pool_config in sorted((config.get("LoginPools") or {}).items()):
            entries.append(self._launch_template({"LoginPool": pool}, pool_config.get("LaunchTemplate") or {}))
        return entries

    def _launch_template(self, entry: dict, template: dict) -> dict:
        """Return ``entry`` with the version of the launch ``template`` (its Id or Name, and Version) the nodes use."""
        selector = (
            {"LaunchTemplateId": template["Id"]} if template.get("Id") else {"LaunchTemplateName": template.get("Name")}
        )
        entry.update(selector, Version=str(template.get("Version") or "$Latest"))
        response = self._call(
            entry, "ec2", "describe_launch_template_versions", Versions=[entry["Version"]], **selector
        )
        if response:
            data = dict(_first(response, "LaunchTemplateVersions").get("LaunchTemplateData") or {})
            data.pop("UserData", None)
            entry["LaunchTemplateData"] = data
        return entry

    def _instance_profile(self, name: str) -> dict:
        """Return the instance profile ``name`` with its ARN and the names of its roles."""
        entry: Dict[str, Any] = {"InstanceProfileName": name}
        response = self._call(entry, "iam", "get_instance_profile", InstanceProfileName=name)
        if response:
            entry["Arn"] = response["InstanceProfile"].get("Arn")
            entry["Roles"] = [role["RoleName"] for role in response["InstanceProfile"].get("Roles", [])]
        return entry

    def _instance_role(self) -> Set[str]:
        """Return the name of the IAM role of the node, from IMDS, or nothing if it cannot be read."""
        try:
            role = imds.get_iam_role_name()
        except Exception as error:  # noqa: B902 - best-effort: the roles of the configuration are still read
            logger.warning("Could not read the IAM role of the node from IMDS: %s", error)
            return set()
        return {role} if role else set()

    def _role(self, name: str, policy_arns: Set[str]) -> dict:
        """Return the role ``name`` with its trust policy and policies, adding its attached policies to ``policy_arns``.

        The documents of the attached policies are in ``iam_policies``, so that a policy attached to several roles is
        read once; the documents of the inline policies are here.
        """
        entry: Dict[str, Any] = {"RoleName": name}
        response = self._call(entry, "iam", "get_role", RoleName=name)
        if not response:
            return entry
        entry["Role"] = response["Role"]
        attached = self._call(entry, "iam", "list_attached_role_policies", RoleName=name)
        if attached:
            entry["AttachedPolicies"] = [policy["PolicyArn"] for policy in attached.get("AttachedPolicies", [])]
            policy_arns.update(entry["AttachedPolicies"])
        inline = self._call(entry, "iam", "list_role_policies", RoleName=name)
        if inline:
            entry["InlinePolicies"] = []
            for policy_name in inline.get("PolicyNames", []):
                policy = {"PolicyName": policy_name}
                document = self._call(policy, "iam", "get_role_policy", RoleName=name, PolicyName=policy_name)
                if document:
                    policy["PolicyDocument"] = document.get("PolicyDocument")
                entry["InlinePolicies"].append(policy)
        return entry

    def _policy(self, arn: str) -> dict:
        """Return the managed policy ``arn`` with its document, except for AWS managed policies."""
        entry: Dict[str, Any] = {"PolicyArn": arn}
        if _AWS_MANAGED_POLICY_PREFIX in arn:
            return entry
        response = self._call(entry, "iam", "get_policy", PolicyArn=arn)
        if response:
            version = self._call(
                entry, "iam", "get_policy_version", PolicyArn=arn, VersionId=response["Policy"]["DefaultVersionId"]
            )
            if version:
                entry["PolicyDocument"] = version["PolicyVersion"].get("Document")
        return entry

    def _script(self, url: str) -> dict:
        """Return the script of a custom action at ``url`` (S3 or HTTPS), as lines with the secrets redacted."""
        entry: Dict[str, Any] = {"Url": url}
        parsed = urlparse(url)
        content: Optional[bytes] = None
        if parsed.scheme == "s3":
            response = self._call(entry, "s3", "get_object", Bucket=parsed.netloc, Key=parsed.path.lstrip("/"))
            if response:
                content = response["Body"].read(CUSTOM_ACTION_SCRIPT_MAX_BYTES + 1)
        elif parsed.scheme == "https":
            try:
                content = _download_https(url, CUSTOM_ACTION_SCRIPT_MAX_BYTES + 1)
            except (OSError, ValueError, http.client.HTTPException) as error:
                entry.setdefault("Errors", []).append(str(error))
                self.failures.append(ReadFailure("https:GET", type(error).__name__))
        else:
            entry.setdefault("Errors", []).append("the URL must be an S3 or HTTPS URL")
        if content is not None:
            entry["Truncated"] = len(content) > CUSTOM_ACTION_SCRIPT_MAX_BYTES
            text = content[:CUSTOM_ACTION_SCRIPT_MAX_BYTES].decode("utf-8", errors="replace")
            entry["Content"] = redact_secrets(text).splitlines()
        return entry

    def _shared_storage(self, cluster_config: dict) -> List[dict]:
        """Return the existing shared storage of the configuration, the storage the cluster did not create."""
        storages = []
        for storage in cluster_config.get("SharedStorage") or []:
            if not isinstance(storage, dict) or storage.get("StorageType") not in _SHARED_STORAGE:
                continue
            settings_key, id_key, service, operation, parameter, list_key = _SHARED_STORAGE[storage["StorageType"]]
            resource_id = (storage.get(settings_key) or {}).get(id_key)
            if not resource_id:
                continue
            entry: Dict[str, Any] = {
                "Name": storage.get("Name"),
                "StorageType": storage["StorageType"],
                id_key: resource_id,
            }
            response = self._call(
                entry, service, operation, **{parameter: [resource_id] if parameter.endswith("s") else resource_id}
            )
            if response:
                entry["Description"] = _first(response, list_key)
            if service == "efs":
                entry["MountTargets"] = self._efs_mount_targets(entry, resource_id)
            storages.append(entry)
        return storages

    def _efs_mount_targets(self, entry: dict, file_system_id: str) -> List[dict]:
        """Return the mount targets of the EFS file system ``file_system_id``, with their security groups."""
        response = self._call(entry, "efs", "describe_mount_targets", FileSystemId=file_system_id)
        mount_targets = (response or {}).get("MountTargets", [])
        for mount_target in mount_targets:
            groups = self._call(
                mount_target,
                "efs",
                "describe_mount_target_security_groups",
                MountTargetId=mount_target["MountTargetId"],
            )
            if groups:
                mount_target["SecurityGroups"] = groups.get("SecurityGroups", [])
        return mount_targets

    def _call(self, entry: dict, service: str, operation: str, **kwargs) -> Optional[dict]:
        """Return the response of ``service``'s ``operation``, or None, adding the error to ``entry``, if it fails."""
        action = "{}:{}".format(
            _IAM_SERVICE_PREFIXES.get(service, service), "".join(part.capitalize() for part in operation.split("_"))
        )
        try:
            response = getattr(self._client(service), operation)(**kwargs)
        except (ClientError, BotoCoreError) as error:
            code = _error_code(error) if isinstance(error, ClientError) else type(error).__name__
            entry.setdefault("Errors", []).append("{}: {}".format(action, error))
            self.failures.append(ReadFailure(action, code))
            return None
        response.pop("ResponseMetadata", None)
        return response

    def _client(self, service: str):
        """Return the boto3 client of ``service``, created once."""
        if service not in self._clients:
            self._clients[service] = boto3.client(service, region_name=self._region, config=_CLIENT_CONFIG)
        return self._clients[service]


def _config_values(config: Any, keys) -> Iterator[Any]:
    """Yield the values of ``keys`` at any depth of ``config``; the items of a list value are yielded one by one.

    The list of AdditionalIamPolicies is yielded whole, since its items are not ids.
    """
    if isinstance(config, dict):
        for key, value in config.items():
            if key in keys:
                if isinstance(value, list) and key != "AdditionalIamPolicies":
                    yield from (item for item in value if item)
                elif value:
                    yield value
            else:
                yield from _config_values(value, keys)
    elif isinstance(config, list):
        for item in config:
            yield from _config_values(item, keys)


def _custom_action_scripts(config: Any) -> Iterator[str]:
    """Yield the URLs of the scripts of the custom actions in ``config``, single scripts and sequences."""
    for custom_actions in _config_values(config, ("CustomActions",)):
        for action in custom_actions.values() if isinstance(custom_actions, dict) else ():
            for script in [action] + list((action or {}).get("Sequence") or []):
                if isinstance(script, dict) and script.get("Script"):
                    yield script["Script"]


def _download_https(url: str, limit: int) -> bytes:
    """Return up to ``limit`` bytes of the HTTPS ``url``, following its redirects as the custom action executor does.

    The download goes through an HTTP(S) connection, so that no other scheme, e.g. ``file://``, can be read.

    Raises:
        OSError: If the URL cannot be downloaded, e.g. it answers with an error status or redirects too many times.
    """
    for _ in range(_MAX_REDIRECTS + 1):
        parsed = urlparse(url)
        if parsed.scheme not in _CONNECTIONS or not parsed.hostname:
            raise OSError("the URL must be an HTTPS or HTTP URL: {}".format(url))
        connection = _CONNECTIONS[parsed.scheme](
            parsed.hostname, parsed.port, timeout=CUSTOM_ACTION_SCRIPT_TIMEOUT_SECONDS
        )
        try:
            connection.request("GET", (parsed.path or "/") + ("?" + parsed.query if parsed.query else ""))
            response = connection.getresponse()
            if response.status in _REDIRECT_STATUSES and response.getheader("Location"):
                url = urljoin(url, response.getheader("Location"))
                continue
            if response.status != 200:
                raise OSError("HTTP {} {}".format(response.status, response.reason))
            return response.read(limit)
        finally:
            connection.close()
    raise OSError("too many redirects")


def _launch_security_groups(data: dict) -> Iterator[str]:
    """Yield the ids of the security groups in launch template data, set on the template or on its interfaces."""
    yield from data.get("SecurityGroupIds") or []
    for interface in data.get("NetworkInterfaces") or []:
        yield from interface.get("Groups") or []


def _without(item: dict, key: str) -> dict:
    """Return a copy of ``item`` without ``key``."""
    return {name: value for name, value in item.items() if name != key}


def _first(response: dict, key: str) -> dict:
    """Return the first item of the list ``key`` of ``response``, or an empty dict if it has none."""
    items = response.get(key) or [{}]
    return items[0]


def _arn_name(arn: str) -> str:
    """Return the name of an IAM resource from its ARN, e.g. ``my-role`` from ``arn:aws:iam::1:role/path/my-role``."""
    return arn.rsplit("/", 1)[-1]


def _error_code(error: ClientError) -> str:
    """Return the code of an AWS error, e.g. ``AccessDenied``."""
    return error.response.get("Error", {}).get("Code") or "Unknown"
