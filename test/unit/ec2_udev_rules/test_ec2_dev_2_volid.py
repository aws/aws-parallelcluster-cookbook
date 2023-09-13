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
from ec2_dev_2_volid import adapt_device_name, get_device_volume_id, get_imdsv2_token, validate_device_name


@pytest.mark.parametrize(
    ("device_name", "raises"),
    [
        ("nvme0n1", False),
        ("xvda", False),
        ("nvme0n1p128", False),
        ("nvme0n1&&", True),
        ("xvda;", True),
        ("nvme0n1|", True),
        ("xvdb??", True),
    ],
)
def test_validate_device_name(device_name, raises):
    if raises:
        assert_that(validate_device_name).raises(ValueError).when_called_with(device_name).contains("invalid pattern")
    else:
        assert_that(validate_device_name(device_name)).is_true()


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


@pytest.mark.parametrize(
    ("dev", "expected_name", "raises"),
    [
        ("nvme0n1", "sdf", True),
        ("nvme0n1p1", "sdf", True),
        ("nvme0n1p128", "sdf", True),
        ("xvd0n1", "/dev/sd0n1", False),
        ("xvd0n1p1", "/dev/sd0n1p1", False),
    ],
)
def test_adapt_device_name(mocker, dev, expected_name, raises, capsys):
    mocker.patch("os.popen", mocker.mock_open(read_data=":sdf"))
    if raises:
        with pytest.raises(SystemExit) as e:
            adapt_device_name(dev)
            captured = capsys.readouterr()
            assert_that(expected_name).is_equal_to(captured.out)
            assert_that(e.value.code).is_equal_to(0)
    else:
        assert_that(adapt_device_name(dev)).matches(expected_name)


@pytest.fixture(name="ec2_mock")
def fixture_ec2_mock(mocker):
    mock = mocker.MagicMock()
    mocker.patch("boto3.client", mock)
    return mock


@pytest.mark.parametrize(
    ("dev", "block", "output_value"),
    [
        (
            "/dev/sda1",
            {
                "InstanceId": "i-1234567890abcdef0",
                "BlockDeviceMappings": [
                    {
                        "DeviceName": "/dev/sda1",
                        "Ebs": {
                            "Status": "attached",
                            "DeleteOnTermination": True,
                            "VolumeId": "vol-049df61146c4d7901",
                            "AttachTime": "2013-05-17T22:42:34.000Z",
                        },
                    },
                    {
                        "DeviceName": "/dev/sdf",
                        "Ebs": {
                            "Status": "attached",
                            "DeleteOnTermination": False,
                            "VolumeId": "vol-049df61146c4d7901",
                            "AttachTime": "2013-09-10T23:07:00.000Z",
                        },
                    },
                ],
            },
            "vol-049df61146c4d7901",
        ),
        (
            "/dev/sda2",
            {
                "InstanceId": "i-1234567890abcdef0",
                "BlockDeviceMappings": [
                    {
                        "DeviceName": "/dev/sda1",
                        "Ebs": {
                            "Status": "attached",
                            "DeleteOnTermination": True,
                            "VolumeId": "vol-049df61146c4d7901",
                            "AttachTime": "2013-05-17T22:42:34.000Z",
                        },
                    },
                    {
                        "DeviceName": "/dev/sdf",
                        "Ebs": {
                            "Status": "attached",
                            "DeleteOnTermination": False,
                            "VolumeId": "vol-049df61146c4d7901",
                            "AttachTime": "2013-09-10T23:07:00.000Z",
                        },
                    },
                ],
            },
            SystemExit,
        ),
    ],
)
def test_get_device_volume_id(mocker, ec2_mock, dev, block, output_value):
    mocker.patch("time.sleep", return_value=None)
    ec2_mock.describe_instance_attribute.return_value = block
    if output_value == SystemExit:
        with pytest.raises(SystemExit) as e:
            get_device_volume_id(ec2_mock, dev, 1)
            assert_that(e.type).is_equal_to(SystemExit)
            assert_that(e.value.code).is_equal_to(1)
    else:
        volume_id = get_device_volume_id(ec2_mock, dev, 1)
        assert_that(volume_id).is_equal_to(output_value)
