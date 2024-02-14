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
from ec2_dev_2_volid import adapt_device_name, validate_device_name


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
