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
from manage_fleet_dna import (
    get_compute_launch_template_ids,
    get_latest_dna_data_for_login_nodes,
    get_user_data,
    get_write_directives_section,
    main,
    parse_proxy_config,
    share_compute_fleet_dna,
    share_login_nodes_dna,
    wait_for_login_nodes_lt_update,
    write_dna_files,
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
                },
                "LoginPools": {
                    "pool-0": {
                        "LaunchTemplate": {
                            "Name": "stack-pool-0",
                            "LogicalId": "LoginNodeLaunchTemplate0123456789012345"
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
                    "path": "/opt/parallelcluster/tmp/dna.json",
                    "permissions": "0644",
                    "owner": "root:root",
                    "content": '{"cluster":{"base_os":"alinux2023","cluster_name":"clustername",'
                    '"directory_service":{"domain_read_only_user":"","enabled":"false",'
                    '"generate_ssh_keys_for_users":"false"},'
                    '"launch_template_id":"LoginNodeLaunchTemplate2736fab291f04e69"}}\n',
                },
                {
                    "path": "/opt/parallelcluster/tmp/extra.json",
                    "permissions": "0644",
                    "owner": "root:root",
                    "content": "{}\n",
                },
                {
                    "path": "/opt/parallelcluster/tmp/bootstrap.sh",
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
                    "content": '{"cluster":{"base_os":"alinux2023"}}\n',
                    "owner": "root:root",
                    "path": "/opt/parallelcluster/tmp/dna.json",
                    "permissions": "0644",
                },
                {
                    "content": '{"cluster": {"nvidia": {"enabled": "yes" }, "is_official_ami_build": "true"}}\n',
                    "owner": "root:root",
                    "path": "/opt/parallelcluster/tmp/extra.json",
                    "permissions": "0644",
                },
                {
                    "content": '#!/bin/bash -x\n\necho "Bootstrap failed with error: $1"\n',
                    "owner": "root:root",
                    "path": "/opt/parallelcluster/tmp/bootstrap.sh",
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


def test_get_user_data_by_name_with_default_version():
    """get_user_data can resolve UserData by LaunchTemplate Name and Versions=['$Latest']."""
    lt_name, lt_version = "stack-pool-0", "$Latest"
    expected_user_data = "user-data-by-name"
    ec2_response = {
        "LaunchTemplateVersions": [
            {"LaunchTemplateData": {"UserData": b64encode(expected_user_data.encode()).decode("utf-8")}}
        ]
    }

    ec2_client = boto3.client("ec2", region_name="us-east-1")
    stubber = Stubber(ec2_client)
    stubber.add_response(
        "describe_launch_template_versions",
        ec2_response,
        {"LaunchTemplateName": lt_name, "Versions": [lt_version]},
    )
    stubber.activate()
    try:
        with patch("boto3.client", return_value=ec2_client):
            assert_that(
                get_user_data(lt_id=None, lt_version=lt_version, region_name="us-east-1", lt_name=lt_name)
            ).is_equal_to(expected_user_data)
    finally:
        stubber.deactivate()


@pytest.mark.parametrize(
    ("lt_id", "lt_name"),
    [
        (None, None),
        ("lt-12345678901234567", "stack-pool-0"),
    ],
)
def test_get_user_data_rejects_invalid_selectors(lt_id, lt_name):
    """get_user_data requires exactly one of lt_id or lt_name."""
    with pytest.raises(ValueError):
        get_user_data(lt_id=lt_id, lt_version="1", region_name="us-east-1", lt_name=lt_name)


LT_CONFIG_COMPUTE_ONLY = {
    "Queues": {
        "queue-0": {
            "ComputeResources": {
                "compute-resource-0": {
                    "LaunchTemplate": {
                        "Id": "lt-aaaaaaaaaaaaaaaaa",
                        "Version": "1",
                        "LogicalId": "ComputeLT0",
                    }
                }
            }
        }
    },
}

LT_CONFIG_COMPUTE_AND_LOGIN = {
    **LT_CONFIG_COMPUTE_ONLY,
    "LoginPools": {
        "pool-0": {"LaunchTemplate": {"Name": "stack-pool-0", "LogicalId": "LoginNodeLT0"}},
        "pool-1": {"LaunchTemplate": {"Name": "stack-pool-1", "LogicalId": "LoginNodeLT1"}},
    },
}


def _share_args():
    args = MagicMock()
    args.region = "us-east-1"
    args.cleanup = False
    return args


# ---------------------------------------------------------------------------
# share_compute_fleet_dna / share_login_nodes_dna
# ---------------------------------------------------------------------------


@pytest.mark.parametrize(
    ("lt_config", "expected_compute_ids"),
    [
        pytest.param(LT_CONFIG_COMPUTE_ONLY, ["lt-aaaaaaaaaaaaaaaaa"], id="compute_only"),
        pytest.param(LT_CONFIG_COMPUTE_AND_LOGIN, ["lt-aaaaaaaaaaaaaaaaa"], id="compute_and_login_pools"),
        pytest.param(None, [], id="missing_launch_template_config"),
        pytest.param({}, [], id="empty_launch_template_config"),
    ],
)
def test_share_compute_fleet_dna(lt_config, expected_compute_ids):
    args = _share_args()
    fetched_ids = []

    def fake_get_user_data(lt_id, *_args, **_kwargs):
        fetched_ids.append(lt_id)

    with patch("manage_fleet_dna.get_compute_launch_template_ids", return_value=lt_config):
        with patch("manage_fleet_dna.get_user_data", side_effect=fake_get_user_data):
            share_compute_fleet_dna(args)

    assert_that(sorted(fetched_ids)).is_equal_to(sorted(expected_compute_ids))


@pytest.mark.parametrize(
    ("lt_config", "expected_pools"),
    [
        pytest.param(LT_CONFIG_COMPUTE_ONLY, [], id="compute_only"),
        pytest.param(LT_CONFIG_COMPUTE_AND_LOGIN, ["pool-0", "pool-1"], id="compute_and_login_pools"),
        pytest.param(None, [], id="missing_launch_template_config"),
        pytest.param({}, [], id="empty_launch_template_config"),
    ],
)
def test_share_login_nodes_dna(lt_config, expected_pools):
    args = _share_args()
    fetched_pools = []

    def fake_share_login(pool_name, _pool, *_args, **_kwargs):
        fetched_pools.append(pool_name)

    with patch("manage_fleet_dna.get_compute_launch_template_ids", return_value=lt_config):
        with patch("manage_fleet_dna.get_latest_dna_data_for_login_nodes", side_effect=fake_share_login):
            share_login_nodes_dna(args)

    assert_that(sorted(fetched_pools)).is_equal_to(sorted(expected_pools))


def test_share_login_nodes_dna_propagates_login_pool_failure():
    """A login pool failure propagates so the head-node Chef step retries."""
    args = _share_args()

    with patch("manage_fleet_dna.get_compute_launch_template_ids", return_value=LT_CONFIG_COMPUTE_AND_LOGIN):
        with patch("manage_fleet_dna.get_latest_dna_data_for_login_nodes", side_effect=RuntimeError("boom")):
            with pytest.raises(RuntimeError, match="boom"):
                share_login_nodes_dna(args)


# ---------------------------------------------------------------------------
# get_latest_dna_data_for_login_nodes
# ---------------------------------------------------------------------------


LOGIN_POOL_USER_DATA_TEMPLATE = """Content-Type: multipart/mixed; boundary="==BOUNDARY=="
MIME-Version: 1.0

--==BOUNDARY==
Content-Type: text/cloud-config; charset=us-ascii
MIME-Version: 1.0

write_files:
  - path: /opt/parallelcluster/tmp/dna.json
    permissions: '0644'
    owner: root:root
    content: |
      {dna_content}

--==BOUNDARY==
"""


def _login_user_data(dna_content):
    return LOGIN_POOL_USER_DATA_TEMPLATE.format(dna_content=dna_content)


def test_get_latest_dna_data_for_login_nodes_writes_dna_file(tmp_path):
    args = MagicMock(region="us-east-1")
    output_location = str(tmp_path) + "/"
    pool = {"LaunchTemplate": {"Name": "stack-pool-0", "Version": "$Latest", "LogicalId": "LoginNodeLT0"}}
    user_data = _login_user_data('{"cluster": {"launch_template_id": "LoginNodeLT0"}}')

    with patch("manage_fleet_dna.get_user_data", return_value=user_data):
        get_latest_dna_data_for_login_nodes("pool-0", pool, output_location, args)

    target = tmp_path / "LoginNodeLT0-dna.json"
    assert_that(target.exists()).is_true()
    assert_that(json.loads(target.read_text())).is_equal_to({"cluster": {"launch_template_id": "LoginNodeLT0"}})


@pytest.mark.parametrize(
    ("pool", "user_data"),
    [
        pytest.param(
            {"LaunchTemplate": {"Name": "stack-pool-0", "Version": "$Latest", "LogicalId": "LoginNodeLT0"}},
            None,
            id="raises_when_user_data_missing",
        ),
        pytest.param(
            {"LaunchTemplate": {"Version": "$Latest", "LogicalId": "LoginNodeLT0"}},
            _login_user_data("{}"),
            id="raises_when_lt_name_missing",
        ),
        pytest.param(
            {"LaunchTemplate": {"Name": "stack-pool-0", "LogicalId": "LoginNodeLT0"}},
            _login_user_data("{}"),
            id="raises_when_version_missing",
        ),
        pytest.param(
            {"LaunchTemplate": {"Name": "stack-pool-0", "Version": "$Latest"}},
            _login_user_data("{}"),
            id="raises_when_logical_id_missing",
        ),
        pytest.param(
            {},
            _login_user_data("{}"),
            id="raises_when_launch_template_block_missing",
        ),
    ],
)
def test_get_latest_dna_data_for_login_nodes_raises_on_invalid_input(tmp_path, pool, user_data):
    args = MagicMock(region="us-east-1")
    output_location = str(tmp_path) + "/"

    with patch("manage_fleet_dna.get_user_data", return_value=user_data):
        with pytest.raises(RuntimeError):
            get_latest_dna_data_for_login_nodes("pool-0", pool, output_location, args)

    assert_that(list(tmp_path.iterdir())).is_empty()


def test_get_latest_dna_data_for_login_nodes_uses_version_from_config():
    """get_latest_dna_data_for_login_nodes looks up UserData by Name with the configured Version."""
    args = MagicMock(region="us-east-1")
    pool = {"LaunchTemplate": {"Name": "stack-pool-0", "Version": "$Latest", "LogicalId": "LoginNodeLT0"}}

    with patch("manage_fleet_dna.get_user_data") as mock_get_user_data:
        mock_get_user_data.return_value = _login_user_data('{"cluster": {}}')
        get_latest_dna_data_for_login_nodes("pool-0", pool, "/unused/", args)

    mock_get_user_data.assert_called_once_with(
        lt_id=None, lt_version="$Latest", region_name="us-east-1", lt_name="stack-pool-0"
    )


# ---------------------------------------------------------------------------
# write_dna_files
# ---------------------------------------------------------------------------


@pytest.mark.parametrize(
    ("write_files_section", "expected_dna_content"),
    [
        pytest.param(
            [
                {
                    "path": "/opt/parallelcluster/tmp/extra.json",
                    "content": "{}",
                },
                {
                    "path": "/opt/parallelcluster/tmp/dna.json",
                    "content": '{"cluster": {"base_os": "alinux2023"}}',
                },
            ],
            {"cluster": {"base_os": "alinux2023"}},
            id="writes_dna_file",
        ),
        pytest.param(
            [
                {
                    "path": "/opt/parallelcluster/tmp/extra.json",
                    "content": "{}",
                },
            ],
            None,
            id="no_op_when_dna_entry_missing",
        ),
    ],
)
def test_write_dna_files(tmp_path, write_files_section, expected_dna_content):
    output_path = str(tmp_path / "LogicalId")

    write_dna_files(write_files_section, output_path)

    target = tmp_path / "LogicalId-dna.json"
    if expected_dna_content is None:
        assert_that(target.exists()).is_false()
    else:
        assert_that(target.exists()).is_true()
        assert_that(json.loads(target.read_text())).is_equal_to(expected_dna_content)


# ---------------------------------------------------------------------------
# wait_for_login_nodes_lt_update
# ---------------------------------------------------------------------------


def test_wait_for_login_nodes_lt_update_uses_version_from_config():
    """The LT version is read from launch-templates-config.json, not hardcoded."""
    lt_config = {
        "LoginPools": {
            "pool-0": {"LaunchTemplate": {"Name": "stack-pool-0", "Version": "$Latest", "LogicalId": "LoginNodeLT0"}},
        }
    }
    user_data = _login_user_data('{"cluster": {"cluster_config_version": "v-new"}}')

    with patch("manage_fleet_dna.get_compute_launch_template_ids", return_value=lt_config):
        with patch("manage_fleet_dna.get_user_data", return_value=user_data) as mock_get_user_data:
            wait_for_login_nodes_lt_update("v-new", "us-east-1")

    mock_get_user_data.assert_called_once_with(
        lt_id=None, lt_version="$Latest", region_name="us-east-1", lt_name="stack-pool-0"
    )


def test_wait_for_login_nodes_lt_update_passes_when_versions_match():
    lt_config = {
        "LoginPools": {
            "pool-0": {"LaunchTemplate": {"Name": "stack-pool-0", "Version": "3", "LogicalId": "LoginNodeLT0"}},
        }
    }
    user_data = _login_user_data('{"cluster": {"cluster_config_version": "v-new"}}')

    with patch("manage_fleet_dna.get_compute_launch_template_ids", return_value=lt_config):
        with patch("manage_fleet_dna.get_user_data", return_value=user_data) as mock_get_user_data:
            wait_for_login_nodes_lt_update("v-new", "us-east-1")

    mock_get_user_data.assert_called_once_with(
        lt_id=None, lt_version="3", region_name="us-east-1", lt_name="stack-pool-0"
    )


def test_wait_for_login_nodes_lt_update_raises_when_versions_mismatch():
    lt_config = {
        "LoginPools": {
            "pool-0": {"LaunchTemplate": {"Name": "stack-pool-0", "Version": "$Latest", "LogicalId": "LoginNodeLT0"}},
        }
    }
    user_data = _login_user_data('{"cluster": {"cluster_config_version": "v-old"}}')

    with patch("manage_fleet_dna.get_compute_launch_template_ids", return_value=lt_config):
        with patch("manage_fleet_dna.get_user_data", return_value=user_data):
            with pytest.raises(RuntimeError, match="cluster_config_version=v-old, expected v-new"):
                wait_for_login_nodes_lt_update("v-new", "us-east-1")


def test_wait_for_login_nodes_lt_update_raises_when_version_missing_in_config():
    lt_config = {
        "LoginPools": {
            "pool-0": {"LaunchTemplate": {"Name": "stack-pool-0", "LogicalId": "LoginNodeLT0"}},
        }
    }

    with patch("manage_fleet_dna.get_compute_launch_template_ids", return_value=lt_config):
        with pytest.raises(RuntimeError, match="missing required data Name/Version/LogicalId"):
            wait_for_login_nodes_lt_update("v-new", "us-east-1")


def test_wait_for_login_nodes_lt_update_raises_when_config_missing():
    """Treat a missing config as a retryable error.

    The launch template config is expected to always be written, so a missing or
    unreadable config (None) is a retryable error rather than a silent pass.
    """
    with patch("manage_fleet_dna.get_compute_launch_template_ids", return_value=None):
        with patch("manage_fleet_dna.get_user_data") as mock_get_user_data:
            with pytest.raises(RuntimeError):
                wait_for_login_nodes_lt_update("v-new", "us-east-1")
            mock_get_user_data.assert_not_called()


@pytest.mark.parametrize("lt_config", [{}, {"LoginPools": {}}])
def test_wait_for_login_nodes_lt_update_returns_without_login_pools(lt_config):
    """Return without raising when there are no login node pools.

    When the config is present but has no login node pool, there is nothing to wait
    for: a warning is logged and the function returns without raising.
    """
    with patch("manage_fleet_dna.get_compute_launch_template_ids", return_value=lt_config):
        with patch("manage_fleet_dna.get_user_data") as mock_get_user_data:
            wait_for_login_nodes_lt_update("v-new", "us-east-1")
            mock_get_user_data.assert_not_called()


# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------


def test_main_cleanup_branch():
    """--cleanup invokes cleanup and nothing else."""
    with patch("sys.argv", ["manage_fleet_dna.py", "--region", "us-east-1", "--cleanup"]):
        with patch("manage_fleet_dna.cleanup") as mock_cleanup:
            with patch("manage_fleet_dna.share_compute_fleet_dna") as mock_compute:
                with patch("manage_fleet_dna.wait_for_login_nodes_lt_update") as mock_wait:
                    main()

    mock_cleanup.assert_called_once()
    mock_compute.assert_not_called()
    mock_wait.assert_not_called()


def test_main_wait_login_nodes_branch():
    """The --wait-login-nodes-launch-template-config-version flag invokes the wait and nothing else."""
    argv = [
        "manage_fleet_dna.py",
        "--region",
        "us-east-1",
        "--wait-login-nodes-launch-template-config-version",
        "v-new",
    ]
    with patch("sys.argv", argv):
        with patch("manage_fleet_dna.wait_for_login_nodes_lt_update") as mock_wait:
            with patch("manage_fleet_dna.share_compute_fleet_dna") as mock_compute:
                with patch("manage_fleet_dna.cleanup") as mock_cleanup:
                    main()

    mock_wait.assert_called_once_with("v-new", "us-east-1")
    mock_compute.assert_not_called()
    mock_cleanup.assert_not_called()


def test_main_share_branch():
    """With no special flag, main shares both compute fleet and login nodes dna."""
    with patch("sys.argv", ["manage_fleet_dna.py", "--region", "us-east-1"]):
        with patch("manage_fleet_dna.share_compute_fleet_dna") as mock_compute:
            with patch("manage_fleet_dna.share_login_nodes_dna") as mock_login:
                main()

    mock_compute.assert_called_once()
    mock_login.assert_called_once()


@pytest.mark.parametrize(
    "exception",
    [RuntimeError("boom"), ValueError("bad"), Exception("generic")],
)
def test_main_propagates_any_exception(exception):
    """The main function does not swallow exceptions; they propagate (Python exits non-zero)."""
    with patch("sys.argv", ["manage_fleet_dna.py", "--region", "us-east-1"]):
        with patch("manage_fleet_dna.share_compute_fleet_dna", side_effect=exception):
            with pytest.raises(type(exception)):
                main()


def test_main_wait_branch_propagates_failure():
    """A failure while waiting for login nodes LT propagates out of main."""
    argv = [
        "manage_fleet_dna.py",
        "--region",
        "us-east-1",
        "--wait-login-nodes-launch-template-config-version",
        "v-new",
    ]
    with patch("sys.argv", argv):
        with patch("manage_fleet_dna.wait_for_login_nodes_lt_update", side_effect=RuntimeError("stale")):
            with pytest.raises(RuntimeError, match="stale"):
                main()
