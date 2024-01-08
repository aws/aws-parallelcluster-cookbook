# Copyright 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
import pytest
from assertpy import assert_that
from manageVolume import (
    adapt_device_name,
    argparse,
    attach_volume,
    detach_volume,
    get_all_devices,
    get_imdsv2_token,
    is_volume_attached,
    is_volume_available,
    main,
    subprocess,
    validate_device_name,
)


@pytest.mark.parametrize(
    ("device_name", "raises"),
    [
        ("/dev/nvme0n1", False),
        ("/dev/nvme0n1p1", False),
        ("/dev/nvme0n1p128", False),
        ("/dev/nvme0n1&&", True),
        ("/dev/nvme0n1;", True),
        ("/dev/nvme0n1|", True),
        ("/dev/nvme0n1??", True),
    ],
)
def test_validate_device_name(device_name, raises):
    if raises:
        assert_that(validate_device_name).raises(ValueError).when_called_with(device_name).contains("invalid pattern")
    else:
        assert_that(validate_device_name(device_name)).is_true()


@pytest.mark.parametrize(
    ("dev", "expected_name"),
    [
        ("/dev/nvme0n1", "/dev/sdf"),
        ("/dev/nvme0n1p1", "/dev/sdf"),
        ("/dev/nvme0n1p128", "/dev/sdf"),
        ("/dev/hd0n1", "/dev/sd0n1"),
        ("/dev/hd0n1p1", "/dev/sd0n1p1"),
        ("/dev/xvd0n1", "/dev/sd0n1"),
        ("/dev/xvd0n1p1", "/dev/sd0n1p1"),
        ("/dev/sd0", "/dev/sd0"),
    ],
)
def test_adapt_device_name(mocker, dev, expected_name):
    mocker.patch("os.popen", mocker.mock_open(read_data="sdf"))
    assert_that(adapt_device_name(dev)).matches(expected_name)


@pytest.mark.parametrize(
    ("name", "raises"),
    [
        ("xvda", False),
        ("xvdb", False),
        (subprocess.CalledProcessError(returncode=0, cmd=["/bin/lsblk", "-d", "-n"]), True),
    ],
)
def test_get_all_devices(mocker, name, raises):
    mocker.patch("subprocess.check_output", return_value=name)
    if raises:
        assert_that(get_all_devices).raises(subprocess.CalledProcessError)
    else:
        assert_that(get_all_devices()).contains("/dev/" + name)


@pytest.mark.parametrize(
    ("status_code", "content", "expected_value"),
    [(200, {"key": "value"}, {"X-aws-ec2-metadata-token": {"key": "value"}}), (400, {"key": "value"}, {})],
)
def test_get_imdsv2_token(mocker, status_code, content, expected_value):
    mock = mocker.Mock()
    mocker.patch("requests.put", mock)
    mock.return_value.status_code = status_code
    mock.return_value.content = content
    assert_that(get_imdsv2_token()).is_equal_to(expected_value)


@pytest.fixture(name="volume_response")
def fixture_volume_response():
    return {
        "Device": "dev-01",
        "InstanceId": "instance-01",
        "State": "attached",
        "VolumeId": "vol-01",
        "DeleteOnTermination": True,
    }


@pytest.fixture(name="ec2_mock")
def fixture_ec2_mock(mocker):
    mock = mocker.MagicMock()
    mocker.patch("boto3.client", mock)
    return mock


@pytest.mark.parametrize(
    ("state", "message"),
    [("attached", ""), ("busy", "bad state"), ("detached", "bad state"), ("available", "failed to mount")],
)
def test_attach_volume(mocker, volume_response, state, message, ec2_mock, capsys):
    mocker.patch("time.sleep", return_value=None)
    mocker.patch("os.popen", mocker.mock_open(read_data="sdf"))
    mocker.patch("subprocess.check_output", return_value="xvda")
    mocker.patch("os.makedirs")
    mocker.patch("builtins.open", mocker.mock_open())

    volume_response["State"] = state
    ec2_mock.attach_volume.return_value = volume_response
    ec2_mock.describe_volumes.return_value = {"Volumes": [{"Attachments": [{"State": state}]}]}

    if state != "attached":
        with pytest.raises(SystemExit) as e:
            attach_volume(volume_response["VolumeId"], volume_response["InstanceId"], ec2_mock)
        assert_that(e.type).is_equal_to(SystemExit)
        assert_that(e.value.code).is_equal_to(1)

    captured = capsys.readouterr()
    assert_that(captured.out).contains(message)


@pytest.mark.parametrize(
    ("state", "message"),
    [("attached", "bad state"), ("busy", "bad state"), ("detached", "failed to detach"), ("available", "")],
)
def test_detach_volume(mocker, volume_response, state, message, ec2_mock, capsys):
    mocker.patch("time.sleep", return_value=None)

    volume_response["State"] = state
    ec2_mock.detach_volume.return_value = volume_response
    ec2_mock.describe_volumes.return_value = {"Volumes": [{"State": state}]}

    if state != "available":
        with pytest.raises(SystemExit) as e:
            detach_volume(volume_response["VolumeId"], ec2_mock)
            assert_that(e.type).is_equal_to(SystemExit)
            assert_that(e.value.code).is_equal_to(1)

    captured = capsys.readouterr()
    assert_that(captured.out).contains(message)


@pytest.mark.parametrize(
    ("volume_output", "expected_available"),
    [
        ({"Volumes": [{"State": "available"}]}, True),
        ({"Volumes": [{"State": "in-use"}]}, False),
        ({"Volumes": [{"State": "busy"}]}, False),
        (Exception, False),
    ],
)
def test_is_volume_available(ec2_mock, volume_output, expected_available, capsys):
    ec2_mock.describe_volumes.return_value = volume_output
    is_avail = is_volume_available(ec2_mock, 0)

    if volume_output == Exception:
        captured = capsys.readouterr()
        assert_that(captured.out).contains("exception")
        assert_that(is_avail).is_false()
    else:
        assert_that(is_avail).is_equal_to(expected_available)


@pytest.mark.parametrize(
    ("volume_output", "expected_attached"),
    [
        ({"Volumes": [{"State": "available"}]}, False),
        ({"Volumes": [{"State": "in-use"}]}, True),
        ({"Volumes": [{"State": "busy"}]}, False),
        (Exception, False),
    ],
)
def test_is_volume_attached(ec2_mock, volume_output, expected_attached, capsys):
    ec2_mock.describe_volumes.return_value = volume_output
    is_attached = is_volume_attached(ec2_mock, 0)

    if volume_output == Exception:
        captured = capsys.readouterr()
        assert_that(captured.out).contains("exception")
        assert_that(is_attached).is_false()
    else:
        assert_that(is_attached).is_equal_to(expected_attached)


@pytest.mark.parametrize(
    ("attach", "detach", "raises"),
    [(True, False, False), (True, True, False), (False, True, False), (False, False, True)],
)
def test_main(mocker, attach, detach, raises):
    mocker.patch(
        "argparse.ArgumentParser.parse_args", return_value=argparse.Namespace(attach=attach, detach=detach, volume_id=1)
    )
    mocker.patch("manageVolume.handle_volume", return_value=True)

    if raises:
        with pytest.raises(SystemExit) as e:
            main()
        assert_that(e.type).is_equal_to(SystemExit)
        assert_that(e.value.code).is_equal_to(1)
    else:
        try:
            main()
        except Exception:
            pytest.fail("Main raised an exception, should not fail")
