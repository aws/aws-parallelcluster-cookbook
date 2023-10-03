# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
import string
import time
from datetime import datetime

import pytest
from assertpy import assert_that
from pcluster_dcv_authenticator import (
    DCVAuthenticator,
    OneTimeTokenHandler,
    generate_random_token,
    generate_sha512_hash,
)

AUTH_MODULE_MOCK_PATH = "pcluster_dcv_authenticator."
AUTH_CLASS_MOCK_PATH = AUTH_MODULE_MOCK_PATH + "DCVAuthenticator."


class TestOneTimeTokenHandler:
    """Class to test the characteristics of the OneTimeTokenHandler class."""

    @staticmethod
    def test_token_capacity():
        """
        Test token capacity.

        Create a token handler with a defined size, add a number of items exceeding the internal capacity
        and verify the first one is not present.
        """
        storage = OneTimeTokenHandler(3)
        storage.add_token("token1", ("some_value", 1, 15.2, ["a", 2]))
        storage.add_token("token2", (1, 2))
        storage.add_token("token3", 5)
        storage.add_token("1", 15)
        assert_that(storage.get_token_info("token1")).is_none()

    @staticmethod
    def test_token_storage():
        """Add tokens and their corresponding information in the storage and verify they are correctly stored."""
        storage = OneTimeTokenHandler(3)
        storage.add_token("token1", ("some_value", 1, 15.2, ["a", 2]))
        storage.add_token("token2", (1, 2))
        storage.add_token("token3", 5)
        assert_that(storage.get_token_info("token1")).is_equal_to(("some_value", 1, 15.2, ["a", 2]))
        assert_that(storage.get_token_info("token2")).is_equal_to((1, 2))
        assert_that(storage.get_token_info("token3")).is_equal_to(5)

    @staticmethod
    def test_one_time_token():
        """Add a token and verify it is correctly removed once used."""
        storage = OneTimeTokenHandler(5)
        storage.add_token(1, "some_value")
        storage.get_token_info(1)
        assert_that(storage.get_token_info(1)).is_none()


def test_one_time_token_handler():
    TestOneTimeTokenHandler.test_token_capacity()
    TestOneTimeTokenHandler.test_token_storage()
    TestOneTimeTokenHandler.test_one_time_token()


def test_token_generator():
    # Verify token length and correctness
    assert_that(generate_random_token(256)).is_not_equal_to(generate_random_token(256))
    assert_that(len(generate_random_token(128))).is_equal_to(128)
    allowed_chars = "".join((string.ascii_letters, string.digits, "_", "-"))
    assert_that(allowed_chars).contains(*list(generate_random_token(256)))


def test_sha_generator():
    # Verify SHA512 generation and salt adding
    assert_that(len(generate_sha512_hash("hash"))).is_equal_to(128)
    assert_that(generate_sha512_hash("hash")).is_not_equal_to(generate_sha512_hash("hash"))
    assert_that(generate_sha512_hash("hash1", "hash2")).is_not_equal_to(generate_sha512_hash("hash1", "hash2"))
    assert_that(generate_sha512_hash([1, 2, 4])).is_not_equal_to(generate_sha512_hash([1, 2, 4]))


@pytest.mark.parametrize(
    "user, command, session_id, result",
    [
        ("user1", "/usr/libexec/dcv/dcvagent", "mysession", True),
        ("user1", "/usr/libexec/dcv/dcvagent2", "mysession", False),
        ("wrong", "/usr/libexec/dcv/dcvagent", "mysession", False),
        ("user1", "/usr/libexec/dcv/dcvagent", "wrong", False),
        ("user1", "/usr/lib/x86_64-linux-gnu/dcv/dcvagent", "mysession", True),
        ("wrong", "/usr/lib/x86_64-linux-gnu/dcv/dcvagent", "mysession", False),
        ("user1", "/usr/lib/x86_64-linux-gnu/dcv/dcvagent", "wrong", False),
    ],
)
def test_is_process_valid(user, command, session_id, result):
    expected_session_id = "mysession"
    expected_user = "user1"

    ps_aux_output = (
        f"{user}                63   0.0  0.0  4348844   3108   ??  Ss   23Jul19   2:32.46 {command} --mode full "
        f"--session-id {session_id}"
    )

    assert_that(DCVAuthenticator.check_dcv_process(ps_aux_output, expected_user, expected_session_id)).is_equal_to(
        result
    )


def mock_generate_random_token(mocker, value):
    mocker.patch(AUTH_MODULE_MOCK_PATH + "generate_random_token", return_value=value)


def mock_verify_session_existence(mocker, exists):
    def _return_value(user, sessionid):  # pylint: disable=W0613
        if not exists:
            raise DCVAuthenticator.IncorrectRequestError("The given session for the user does not exists")

    mocker.patch(AUTH_CLASS_MOCK_PATH + "_verify_session_existence", side_effect=_return_value)


def mock_os(mocker, user, timestamp):
    class FileProperty:
        pass

    file_property = FileProperty
    file_property.st_uid = 1
    file_property.st_size = b"800"
    file_property.st_mtime = timestamp
    file_property.pw_name = user
    file_property.st_mode = 0

    mocker.patch(AUTH_MODULE_MOCK_PATH + "os.stat", return_value=file_property)
    mocker.patch(AUTH_MODULE_MOCK_PATH + "os.remove")
    mocker.patch(AUTH_MODULE_MOCK_PATH + "getpwuid", return_value=file_property)


@pytest.mark.parametrize(
    "parameters, keys, result",
    [
        ({"a": "5", "b": "2"}, ["authUser", "sessionID"], DCVAuthenticator.IncorrectRequestError),
        ({"authUser": "5", "b": "2"}, ["authUser", "sessionID"], DCVAuthenticator.IncorrectRequestError),
        ({"a": "5", "sessionID": "2"}, ["authUser", "sessionID"], DCVAuthenticator.IncorrectRequestError),
        ({"authUser": "user1", "sessionID": "1234"}, ["authUser", "sessionID"], ["user1", "1234"]),
        ({"requestToken": "token1"}, ["requestToken"], ["token1"]),
    ],
)
def test_get_request_token_parameter(parameters, keys, result):
    if isinstance(result, list):
        assert_that(DCVAuthenticator._extract_parameters_values(parameters, keys)).is_equal_to(result)
    else:
        with pytest.raises(result):
            DCVAuthenticator._extract_parameters_values(parameters, keys)


def test_is_session_valid(mocker):
    ps_aunx_output = (
        b"USER   PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND\n"
        b"1000 63 0.0 0.0 4348844 3108   ??  Ss   23Jul19   2:32.46  /usr/libexec/dcv/dcvagent --mode full --session-id mysession\n"
        b"2000 2949 0.3 0.4 860568 34328 ? Sl 20:10 0:18 /usr/lib/x86_64-linux-gnu/dcv/dcvagent --mode full --session-id mysession\n"
    )
    # Mock subprocess.check_output with realistic responses for `/usr/bin/id` and `/bin/ps aunx`
    mocker.patch(AUTH_MODULE_MOCK_PATH + "subprocess.check_output", side_effect=[b"1000", ps_aunx_output])

    # Test that the session is valid
    DCVAuthenticator._is_session_valid("myuser", "mysession")

    # Mock subprocess.check_output with realistic responses for `/usr/bin/id` and `/bin/ps aunx`
    mocker.patch(AUTH_MODULE_MOCK_PATH + "subprocess.check_output", side_effect=[b"1000", ps_aunx_output])

    # Test that the session is not valid
    with pytest.raises(DCVAuthenticator.IncorrectRequestError):
        DCVAuthenticator._is_session_valid("myuser", "wrongsession")

def test_get_request_token(mocker):
    """Verify the first step of the authentication process, the retrieval of the Request Token."""
    # A nosec comment is appended to the following line in order to disable the B105 check.
    # Since the request token is only being used for a unit test and not the actual auth service
    token_value = "1234abcd_-"  # nosec B105
    user = "centos"
    session_id = "mysession"

    mock_verify_session_existence(mocker, exists=True)
    mock_generate_random_token(mocker, token_value)

    # all correct
    assert_that(DCVAuthenticator._get_request_token(user, session_id)).is_equal_to(
        json.dumps({"requestToken": token_value, "accessFile": generate_sha512_hash(token_value)})
    )
    assert_that(DCVAuthenticator.request_token_manager.get_token_info(token_value)[:-2]).is_equal_to((user, session_id))

    # session does not exists
    mock_verify_session_existence(mocker, exists=False)
    with pytest.raises(DCVAuthenticator.IncorrectRequestError):
        DCVAuthenticator._get_request_token(user, session_id)


@pytest.mark.parametrize(
    "user, session_id",
    [
        ("-1234abcd_-", "mysession"),
        ("a^mc", "mysession"),
        ("aAmc", "mysession"),
        ('a"mc', "mysession"),
        ("a1234abcd_-", "^mysession"),
        ("a1234abcd_-", "mys+ession"),
        ("a1234abcd_-", "".join(("c" for _ in range(129)))),
        ("".join(("c" for _ in range(33))), "mysession"),
    ],
)
def test_get_request_token_regex(user, session_id):
    with pytest.raises(DCVAuthenticator.IncorrectRequestError):
        DCVAuthenticator._get_request_token(user, session_id)


@pytest.mark.parametrize("token", ["assvbsd", "?" + "".join(("c" for _ in range(255)))])
def test_get_session_token_regex(token):
    with pytest.raises(DCVAuthenticator.IncorrectRequestError):
        DCVAuthenticator._get_session_token(token)


def test_check_auth(mocker):
    """
    Verify the DCVAuthenticator._check_auth method.

    The method verifies the token validity for the given DCV session id.
    """
    token = generate_random_token(256)
    user = "centos"
    session_id = "mysession"
    mock_verify_session_existence(mocker, exists=True)

    # valid
    DCVAuthenticator.session_token_manager.add_token(
        token, DCVAuthenticator.SessionTokenInfo(user, session_id, datetime.utcnow())
    )
    assert_that(DCVAuthenticator._check_auth(session_id, token)).is_equal_to(user)

    # expired
    DCVAuthenticator.session_token_manager.add_token(
        token,
        DCVAuthenticator.SessionTokenInfo(user, session_id, datetime.utcnow() - DCVAuthenticator.session_token_ttl),
    )
    time.sleep(1)
    assert_that(DCVAuthenticator._check_auth(session_id, token)).is_none()

    # wrong session
    DCVAuthenticator.session_token_manager.add_token(
        token, DCVAuthenticator.SessionTokenInfo(user, session_id, datetime.utcnow())
    )
    assert_that(DCVAuthenticator._check_auth("mysession2", token)).is_none()


def obtain_timestamp(date):
    return (date - datetime(1970, 1, 1)).total_seconds()


def test_get_session_token(mocker):
    """Verify the second step of the authentication process, the retrieval of the Session Token."""
    request_token = "".join("a" for _ in range(256))
    user = "centos"
    session_id = "mysession"
    access_file = "access_file"
    mock_verify_session_existence(mocker, exists=True)

    # empty
    with pytest.raises(DCVAuthenticator.IncorrectRequestError):
        DCVAuthenticator._get_session_token(request_token)

    # expired
    DCVAuthenticator.request_token_manager.add_token(
        request_token,
        DCVAuthenticator.RequestTokenInfo(
            user, session_id, datetime.utcnow() - DCVAuthenticator.request_token_ttl, access_file
        ),
    )
    with pytest.raises(DCVAuthenticator.IncorrectRequestError):
        DCVAuthenticator._get_session_token(request_token)

    # file does not exist
    DCVAuthenticator.request_token_manager.add_token(
        request_token, DCVAuthenticator.RequestTokenInfo(user, session_id, datetime.utcnow(), access_file)
    )
    with pytest.raises(DCVAuthenticator.IncorrectRequestError):
        DCVAuthenticator._get_session_token(request_token)

    # user is different
    mock_os(mocker, "centos2", obtain_timestamp(datetime.utcnow()))
    DCVAuthenticator.request_token_manager.add_token(
        request_token, DCVAuthenticator.RequestTokenInfo(user, session_id, datetime.utcnow(), access_file)
    )
    with pytest.raises(DCVAuthenticator.IncorrectRequestError):
        DCVAuthenticator._get_session_token(request_token)

    # file is expired
    mock_os(mocker, user, obtain_timestamp(datetime.utcnow() - DCVAuthenticator.request_token_ttl))
    DCVAuthenticator.request_token_manager.add_token(
        request_token, DCVAuthenticator.RequestTokenInfo(user, session_id, datetime.utcnow(), access_file)
    )
    with pytest.raises(DCVAuthenticator.IncorrectRequestError):
        DCVAuthenticator._get_session_token(request_token)

    # working
    mock_os(mocker, user, obtain_timestamp(datetime.utcnow()))
    mock_verify_session_existence(mocker, exists=True)
    # A nosec comment is appended to the following line in order to disable the B105 check.
    # Since the session token is not a hardcoded password but merely used for unit testing
    session_token = "1234"  # nosec B105
    mock_generate_random_token(mocker, session_token)
    DCVAuthenticator.request_token_manager.add_token(
        request_token, DCVAuthenticator.RequestTokenInfo(user, session_id, datetime.utcnow(), access_file)
    )
    assert_that(DCVAuthenticator._get_session_token(request_token)).is_equal_to(
        json.dumps({"sessionToken": session_token})
    )
    assert_that(DCVAuthenticator.session_token_manager.get_token_info(session_token)[:-1]).is_equal_to(
        (user, session_id)
    )
