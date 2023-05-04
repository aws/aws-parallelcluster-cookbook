# Copyright 2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance
# with the License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.
import os
from datetime import datetime, timedelta, timezone
from types import SimpleNamespace

import boto3
import botocore
import clusterstatusmgtd
import pytest
from assertpy import assert_that
from clusterstatusmgtd import (
    ClusterStatusManager,
    ClusterstatusmgtdConfig,
    ComputeFleetStatus,
    ComputeFleetStatusManager,
    _sleep_remaining_loop_time,
)


@pytest.mark.parametrize(
    "loop_start_time, loop_end_time, loop_total_time, expected_sleep_time",
    [
        (
            datetime(2020, 1, 1, 0, 0, 30, tzinfo=timezone.utc),
            datetime(2020, 1, 1, 0, 0, 30, tzinfo=timezone.utc),
            60,
            60,
        ),
        (
            datetime(2020, 1, 1, 0, 0, 30, tzinfo=timezone.utc),
            datetime(2020, 1, 1, 0, 1, 00, tzinfo=timezone.utc),
            60,
            30,
        ),
        (
            datetime(2020, 1, 1, 0, 0, 30, tzinfo=timezone.utc),
            datetime(2020, 1, 1, 0, 1, 30, tzinfo=timezone.utc),
            60,
            0,
        ),
        (
            datetime(2020, 1, 1, 0, 0, 30, tzinfo=timezone.utc),
            datetime(2020, 1, 1, 0, 0, 0, tzinfo=timezone.utc),
            60,
            0,
        ),
        (
            datetime(2020, 1, 1, 1, 0, 0, tzinfo=timezone(timedelta(hours=1))),
            datetime(2020, 1, 1, 0, 0, 30, tzinfo=timezone.utc),
            60,
            30,
        ),
        (
            datetime(2020, 1, 1, 1, 0, 0),
            datetime(2020, 1, 1, 0, 0, 30, tzinfo=timezone.utc),
            60,
            None,  # can't assert this with naive timezone since the value depends on the system timezone
        ),
    ],
)
def test_sleep_remaining_loop_time(mocker, loop_start_time, loop_end_time, loop_total_time, expected_sleep_time):
    sleep_mock = mocker.patch("time.sleep")
    datetime_now_mock = mocker.MagicMock()
    datetime_now_mock.now = mocker.MagicMock(return_value=loop_end_time, spec=datetime.now)
    mocker.patch("clusterstatusmgtd.datetime", datetime_now_mock)

    _sleep_remaining_loop_time(loop_total_time, loop_start_time)

    if expected_sleep_time:
        sleep_mock.assert_called_with(expected_sleep_time)
    elif expected_sleep_time == 0:
        sleep_mock.assert_not_called()
    datetime_now_mock.now.assert_called_with(tz=timezone.utc)


def test_run_command():
    pass


def test_write_json_to_file():
    # tested in test_call_update_event
    pass


class TestComputeFleetStatus:
    """Class to test ComputeFleetStatus."""

    def test_transform_compute_fleet_data(self):
        """Tested in test_call_update_event."""
        pass

    def test_is_start_in_progress(self):
        """Tested in test_manage_cluster_status."""
        pass

    def test_is_stop_in_progress(self):
        """Tested in test_manage_cluster_status."""
        pass

    def test_is_protected_status(self):
        """Not tested, not used."""
        pass


class TestComputeFleetStatusManager:
    """Class to test TestComputeFleetStatusManager."""

    @pytest.fixture
    def compute_fleet_status_manager(self, mocker):
        """Fixture for ComputeFleetStatusManager."""
        status_manager = ComputeFleetStatusManager("table", botocore.config.Config(), "us-east-1")
        mocker.patch.object(status_manager, "_table")

        return status_manager

    @pytest.mark.parametrize(
        "get_item_response, expected_exception, expected_status",
        [
            ({"Item": {"Id": "COMPUTE_FLEET", "Data": {"status": "RUNNING"}}}, None, {"status": "RUNNING"}),
            ({"NoData": "NoValue"}, ComputeFleetStatusManager.FleetDataNotFoundError, Exception()),
        ],
        ids=["success", "exception"],
    )
    def test_get_status(self, compute_fleet_status_manager, get_item_response, expected_exception, expected_status):
        """Test get_status method."""
        if isinstance(expected_status, Exception):
            compute_fleet_status_manager._table.get_item.side_effect = get_item_response
            with pytest.raises(expected_exception):
                compute_fleet_status_manager.get_status()
        else:
            compute_fleet_status_manager._table.get_item.return_value = get_item_response
            status = compute_fleet_status_manager.get_status()
            assert_that(status).is_equal_to(expected_status)

        compute_fleet_status_manager._table.get_item.assert_called_with(
            ConsistentRead=True, Key={"Id": ComputeFleetStatusManager.DB_KEY}
        )

    @pytest.mark.parametrize(
        "expected_status, expected_update_item, expected_exception",
        [
            (
                {"status": "RUNNING"},
                {"Attributes": {"Data": {"status": "RUNNING"}}},
                None,
            ),
            (
                boto3.client("dynamodb", region_name="us-east-1").exceptions.ConditionalCheckFailedException(
                    {"Error": {}}, {}
                ),
                {},
                ComputeFleetStatusManager.ConditionalStatusUpdateFailedError,
            ),
            (Exception(), {}, Exception),
        ],
        ids=["success", "conditional_check_failed", "exception"],
    )
    def test_update_status(
        self, compute_fleet_status_manager, expected_status, expected_update_item, expected_exception
    ):
        """Test update_status method."""
        if isinstance(expected_status, Exception):
            compute_fleet_status_manager._table.update_item.side_effect = expected_status
            with pytest.raises(expected_exception):
                compute_fleet_status_manager.update_status(ComputeFleetStatus.STARTING, ComputeFleetStatus.RUNNING)
        else:
            compute_fleet_status_manager._table.update_item.return_value = expected_update_item
            actual_status = compute_fleet_status_manager.update_status(
                ComputeFleetStatus.STARTING, ComputeFleetStatus.RUNNING
            )
            assert_that(actual_status).is_equal_to(expected_status)


class TestClusterstatusmgtdConfig:
    """Class to test ClusterstatusmgtdConfig."""

    @pytest.mark.parametrize(
        ("config_file", "expected_attributes"),
        [
            (
                "default.conf",
                {
                    "cluster_name": "test",
                    "region": "us-east-2",
                    "_boto3_config": {"retries": {"max_attempts": 5, "mode": "standard"}},
                    "loop_time": 60,
                    "logging_config": os.path.join(
                        os.path.dirname(clusterstatusmgtd.__file__), "clusterstatusmgtd_logging.conf"
                    ),
                    "dynamodb_table": "table-name",
                    "computefleet_status_path": "/opt/parallelcluster/shared/computefleet-status.json",
                    "update_event_timeout_minutes": 15,
                },
            ),
            (
                "all_options.conf",
                {
                    "cluster_name": "test-2",
                    "region": "us-east-1",
                    "_boto3_config": {
                        "retries": {"max_attempts": 10, "mode": "standard"},
                        "proxies": {"https": "https://fake.proxy"},
                    },
                    "loop_time": 30,
                    "logging_config": "/my/logging/config",
                    "dynamodb_table": "another-table",
                    "computefleet_status_path": "/alternative/status.json",
                    "update_event_timeout_minutes": 5,
                },
            ),
        ],
        ids=["default", "all_options"],
    )
    def test_config_parsing(self, config_file, expected_attributes, test_datadir):
        """Test config_parsing method."""
        sync_config = ClusterstatusmgtdConfig(test_datadir / config_file)
        for key in expected_attributes:
            assert_that(sync_config.__dict__.get(key)).is_equal_to(expected_attributes.get(key))

    def test_config_comparison(self, test_datadir):
        """Test configs comparison."""
        config = test_datadir / "config.conf"
        config_modified = test_datadir / "config_modified.conf"

        assert_that(ClusterstatusmgtdConfig(config)).is_equal_to(ClusterstatusmgtdConfig(config))
        assert_that(ClusterstatusmgtdConfig(config)).is_not_equal_to(ClusterstatusmgtdConfig(config_modified))


@pytest.fixture(name="initialize_compute_fleet_status_manager_mock")
def fixture_initialize_compute_fleet_status_manager_mock(mocker):
    compute_fleet_status_manager_mock = mocker.Mock(spec=ComputeFleetStatusManager)
    compute_fleet_status_manager_mock.get_status.return_value = ComputeFleetStatus.RUNNING
    compute_fleet_status_manager_mock.COMPUTE_FLEET_STATUS_ATTRIBUTE = (
        ComputeFleetStatusManager.COMPUTE_FLEET_STATUS_ATTRIBUTE
    )
    return mocker.patch.object(
        ClusterStatusManager,
        "_initialize_compute_fleet_status_manager",
        spec=ClusterStatusManager._initialize_compute_fleet_status_manager,
        return_value=compute_fleet_status_manager_mock,
    )


class TestClusterStatusManager:
    """Class to test ClusterStatusManager."""

    def test_set_config(self, initialize_compute_fleet_status_manager_mock):
        """Test set_config method."""
        initial_config = SimpleNamespace(some_key_1="some_value_1", some_key_2="some_value_2")
        updated_config = SimpleNamespace(some_key_1="some_value_1", some_key_2="some_value_2_changed")

        clusterstatus_manager = ClusterStatusManager(initial_config)
        assert_that(clusterstatus_manager._config).is_equal_to(initial_config)
        clusterstatus_manager.set_config(initial_config)
        assert_that(clusterstatus_manager._config).is_equal_to(initial_config)
        clusterstatus_manager.set_config(updated_config)
        assert_that(clusterstatus_manager._config).is_equal_to(updated_config)

        assert_that(initialize_compute_fleet_status_manager_mock.call_count).is_equal_to(2)

    @pytest.mark.parametrize(
        "get_status_response, fallback, expected_fleet_status",
        [
            ({"status": "RUNNING"}, None, ComputeFleetStatus.RUNNING),
            (
                {},
                ComputeFleetStatus.STOPPED,
                ComputeFleetStatus.STOPPED,
            ),
            (
                Exception,
                ComputeFleetStatus.STOPPED,
                ComputeFleetStatus.STOPPED,
            ),
        ],
        ids=["success", "empty_response", "exception"],
    )
    def test_get_compute_fleet_status(
        self, initialize_compute_fleet_status_manager_mock, get_status_response, fallback, expected_fleet_status
    ):
        """Test get_compute_fleet_status method."""
        config = SimpleNamespace(some_key_1="some_value_1", some_key_2="some_value_2")
        clusterstatus_manager = ClusterStatusManager(config)

        if get_status_response is Exception:
            initialize_compute_fleet_status_manager_mock().get_status.side_effect = get_status_response
        else:
            initialize_compute_fleet_status_manager_mock().get_status.return_value = get_status_response

        actual_fleet_status = clusterstatus_manager._get_compute_fleet_status(fallback)
        assert_that(actual_fleet_status).is_equal_to(expected_fleet_status)

    @pytest.mark.parametrize(
        "new_status, new_fleet_data, expected_exception",
        [
            (
                ComputeFleetStatus.RUNNING,
                {"status": "RUNNING"},
                None,
            ),
            (
                boto3.client("dynamodb", region_name="us-east-1").exceptions.ConditionalCheckFailedException(
                    {"Error": {}}, {}
                ),
                None,
                ComputeFleetStatusManager.ConditionalStatusUpdateFailedError,
            ),
            (Exception(), None, Exception),
        ],
        ids=["success", "conditional_check_failed", "exception"],
    )
    def test_update_compute_fleet_status(
        self, initialize_compute_fleet_status_manager_mock, new_status, new_fleet_data, expected_exception
    ):
        """Test update_compute_fleet_status method."""
        config = SimpleNamespace(some_key_1="some_value_1", some_key_2="some_value_2")
        clusterstatus_manager = ClusterStatusManager(config)

        if isinstance(new_status, Exception):
            initialize_compute_fleet_status_manager_mock().update_status.side_effect = expected_exception
            with pytest.raises(expected_exception):
                clusterstatus_manager._update_compute_fleet_status(new_status)
        else:
            initialize_compute_fleet_status_manager_mock().update_status.return_value = new_fleet_data
            clusterstatus_manager._update_compute_fleet_status(new_status)
            assert_that(clusterstatus_manager._compute_fleet_data).is_equal_to(new_fleet_data)
            assert_that(clusterstatus_manager._compute_fleet_status).is_equal_to(new_status)

    @pytest.mark.parametrize(
        "status, translated_status, exception",
        [
            (
                {"status": "STOPPING"},
                '{"status": "STOP_REQUESTED"}',
                None,
            ),
            (
                {"status": "STARTING"},
                '{"status": "START_REQUESTED"}',
                None,
            ),
            (
                {"status": "WRONG"},
                '{"status": "UNKNOWN"}',
                None,
            ),
            (
                {},
                '{"status": "UNKNOWN"}',
                None,
            ),
            (
                None,
                '{"status": "UNKNOWN"}',
                Exception(),
            ),
            (
                {"status": "STOPPING"},
                '{"status": "STOP_REQUESTED"}',
                Exception(),
            ),
        ],
        ids=["stopping", "starting", "unknown_status", "empty_status", "no_status", "run_command_exception"],
    )
    @pytest.mark.usefixtures("initialize_compute_fleet_status_manager_mock")
    def test_call_update_event(self, mocker, status, translated_status, exception):
        """Test call_update_event method."""
        computeflee_json_path = "/path/to/compute_fleet.json"
        cinc_log_file = "/var/log/chef-client.log"
        cmd = (
            "sudo cinc-client "
            "--local-mode "
            "--config /etc/chef/client.rb "
            "--log_level auto "
            f"--logfile {cinc_log_file} "
            "--force-formatter "
            "--no-color "
            "--chef-zero-port 8889 "
            "--json-attributes /etc/chef/dna.json "
            "--override-runlist aws-parallelcluster::update_computefleet_status"
        )

        config = SimpleNamespace(computefleet_status_path=computeflee_json_path, update_event_timeout_minutes=1)
        clusterstatus_manager = ClusterStatusManager(config)
        clusterstatus_manager._compute_fleet_data = status
        run_command_mock = mocker.patch("clusterstatusmgtd._run_command")
        if isinstance(exception, Exception):
            run_command_mock.side_effect = exception
            with pytest.raises(ClusterStatusManager.ClusterStatusUpdateEventError):
                clusterstatus_manager._call_update_event()
        else:
            file_writer_mock = mocker.mock_open()
            mocker.patch("clusterstatusmgtd.open", file_writer_mock)

            clusterstatus_manager._call_update_event()

            file_writer_mock.assert_called_once_with(computeflee_json_path, "w", encoding="utf-8")
            file_writer_mock().write.assert_called_once_with(translated_status)
            run_command_mock.assert_called_once_with(cmd, 1)

    def test_update_status(self):
        """Tested in test_manage_cluster_status."""
        pass

    @pytest.mark.parametrize(
        "compute_fleet_initial_status, compute_fleet_transitions",
        [
            (ComputeFleetStatus.RUNNING, []),
            (ComputeFleetStatus.STOP_REQUESTED, [ComputeFleetStatus.STOPPING, ComputeFleetStatus.STOPPED]),
            (ComputeFleetStatus.STOPPING, [ComputeFleetStatus.STOPPED]),
            (ComputeFleetStatus.STOPPED, []),
            (ComputeFleetStatus.START_REQUESTED, [ComputeFleetStatus.STARTING, ComputeFleetStatus.RUNNING]),
            (ComputeFleetStatus.STARTING, [ComputeFleetStatus.RUNNING]),
        ],
    )
    def test_manage_cluster_status(
        self,
        mocker,
        initialize_compute_fleet_status_manager_mock,
        compute_fleet_initial_status,
        compute_fleet_transitions,
    ):
        """Test manage_cluster_status method."""
        config = SimpleNamespace(computefleet_status_path="/path/to/fleet.json", update_event_timeout_minutes=1)
        clusterstatus_manager = ClusterStatusManager(config)
        update_compute_fleet_status_mocked = initialize_compute_fleet_status_manager_mock().update_status
        get_compute_fleet_status_mocked = mocker.patch.object(
            clusterstatus_manager, "_get_compute_fleet_status", return_value=compute_fleet_initial_status
        )
        call_update_event_mocked = mocker.patch.object(clusterstatus_manager, "_call_update_event")

        clusterstatus_manager.manage_cluster_status()

        get_compute_fleet_status_mocked.assert_called_once()
        if compute_fleet_transitions:
            call_update_event_mocked.assert_called_once()
            assert_that(update_compute_fleet_status_mocked.call_count).is_equal_to(len(compute_fleet_transitions))
        else:
            call_update_event_mocked.assert_not_called()
            update_compute_fleet_status_mocked.assert_not_called()

    @pytest.mark.usefixtures("initialize_compute_fleet_status_manager_mock")
    def test_manage_cluster_status_concurrency(self, mocker, caplog):
        """Test manage_cluster_status method, in case of concurrency."""
        config = SimpleNamespace(computefleet_status_path="/path/to/fleet.json", update_event_timeout_minutes=1)
        clusterstatus_manager = ClusterStatusManager(config)
        mocker.patch.object(
            clusterstatus_manager, "_get_compute_fleet_status", return_value=ComputeFleetStatus.STOP_REQUESTED
        )
        mocker.patch.object(
            clusterstatus_manager,
            "_update_compute_fleet_status",
            side_effect=ComputeFleetStatusManager.ConditionalStatusUpdateFailedError,
        )

        clusterstatus_manager.manage_cluster_status()

        assert_that(caplog.text).contains("Cluster status was updated while handling a transition")
        assert_that(clusterstatus_manager._get_compute_fleet_status.call_count).is_equal_to(1)
        assert_that(clusterstatus_manager._update_compute_fleet_status.call_count).is_equal_to(1)
