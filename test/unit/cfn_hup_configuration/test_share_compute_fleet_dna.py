# Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance
# with the License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.
import json
import os
from base64 import b64encode
from unittest.mock import MagicMock, patch

import boto3
import pytest
from assertpy import assert_that
from botocore.stub import Stubber
from share_compute_fleet_dna import (
    get_compute_launch_template_ids,
    get_user_data,
    get_write_directives_section,
    parse_proxy_config,
)


@pytest.mark.parametrize(
    ("launch_template_config_content", "errors"),
    [
        (
            """
            {
                "Queues": {
                    "queue-0": {
                        "ComputeResources": {
                            "compute-resource-1": {
                                "LaunchTemplate": {
                                    "Version": "1",
                                    "Id": "lt-037123456747c3bc5"
                                }
                            },
                            "compute-resource-2": {
                                "LaunchTemplate": {
                                    "Version": "1",
                                    "Id": "lt-0fcecb59a3721c0b3"
                                }
                            },
                            "compute-resource-0": {
                                "LaunchTemplate": {
                                    "Version": "1",
                                    "Id": "lt-12345678901234567"
                                }
                            }
                        }
                    }
                }
            }
            """,
            False,
        ),
        ('{"Queues":{"queue-0":}}}', True),
    ],
)
def test_get_compute_launch_template_ids(mocker, launch_template_config_content, errors):
    mocker.patch("builtins.open", mocker.mock_open(read_data=launch_template_config_content))
    actual_op = get_compute_launch_template_ids(launch_template_config_content)
    if errors:
        assert_that(actual_op).is_none()
    else:
        assert_that(actual_op).is_equal_to(json.loads(launch_template_config_content))


@pytest.mark.parametrize(
    ("mime_user_data_file", "write_section"),
    [
        (
            "user_data_1.txt",
            [
                {
                    "path": "/tmp/dna.json",  # nosec B108
                    "permissions": "0644",
                    "owner": "root:root",
                    "content": '{"cluster":{"base_os":"alinux2","cluster_name":"clustername",'
                    '"directory_service":{"domain_read_only_user":"","enabled":"false",'
                    '"generate_ssh_keys_for_users":"false"},'
                    '"launch_template_id":"LoginNodeLaunchTemplate2736fab291f04e69"}}\n',
                },
                {
                    "path": "/tmp/extra.json",  # nosec B108
                    "permissions": "0644",
                    "owner": "root:root",
                    "content": "{}\n",
                },
                {
                    "path": "/tmp/bootstrap.sh",  # nosec B108
                    "permissions": "0744",
                    "owner": "root:root",
                    "content": '#!/bin/bash -x\n\nfunction error_exit\n{\n  echo "Bootstrap failed"\n}\n',
                },
            ],
        ),
        (
            "user_data_2.txt",
            [
                {
                    "content": '{"cluster":{"base_os":"alinux2"}}\n',
                    "owner": "root:root",
                    "path": "/tmp/dna.json",  # nosec B108
                    "permissions": "0644",
                },
                {
                    "content": '{"cluster": {"nvidia": {"enabled": "yes" }, "is_official_ami_build": "true"}}\n',
                    "owner": "root:root",
                    "path": "/tmp/extra.json",  # nosec B108
                    "permissions": "0644",
                },
                {
                    "content": '#!/bin/bash -x\n\necho "Bootstrap failed with error: $1"\n',
                    "owner": "root:root",
                    "path": "/tmp/bootstrap.sh",  # nosec B108
                    "permissions": "0744",
                },
            ],
        ),
        ("", None),
    ],
)
def test_get_write_directives_section(mime_user_data_file, write_section, test_datadir):
    input_mime_user_data = None
    if mime_user_data_file:
        with open(os.path.join(test_datadir, mime_user_data_file), "r", encoding="utf-8") as file:
            input_mime_user_data = file.read().strip()

    assert_that(get_write_directives_section(input_mime_user_data)).is_equal_to(write_section)


@pytest.mark.parametrize(("error", "proxy", "port"), [(True, "myproxy.com", "8080"), (False, "", "")])
def test_parse_proxy_config(error, proxy, port):
    mock_config = MagicMock(return_value=error)
    mock_config.get.side_effect = [proxy, port]
    expected_op = {"https": proxy + ":" + port}
    with patch("configparser.RawConfigParser", return_value=mock_config):
        assert_that(parse_proxy_config().proxies).is_equal_to(expected_op)


def ec2_describe_launch_template_versions_mock(response, lt_id, lt_version):
    e2_client = boto3.client("ec2", region_name="us-east-1")
    stubber = Stubber(e2_client)
    stubber.add_response(
        "describe_launch_template_versions", response, {"LaunchTemplateId": lt_id, "Versions": [lt_version]}
    )
    stubber.activate()
    return e2_client, stubber


@pytest.mark.parametrize(
    ("expected_user_data"),
    [("#!/bin/bash\necho 'Test'"), ("")],
)
def test_get_user_data(expected_user_data):
    lt_id, lt_version = "lt-12345678901234567", "1"
    ec2_response = {
        "LaunchTemplateVersions": [
            {"LaunchTemplateData": {"UserData": b64encode(expected_user_data.encode()).decode("utf-8")}}
        ]
    }

    ec2_client, stubber = ec2_describe_launch_template_versions_mock(ec2_response, lt_id, lt_version)

    with patch("boto3.client") as mock_client:
        mock_client.return_value = ec2_client
        with stubber:
            assert_that(get_user_data(lt_id, lt_version, "us-east-1")).is_equal_to(expected_user_data)
    stubber.deactivate()
