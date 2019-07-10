import json
from datetime import datetime

import pytest

from assertpy import assert_that
from pcluster_dcv_ext_auth.pcluster_dcv_ext_auth import (
    DCVAuthenticator,
    OneTimeTokenHandler,
    generate_random_token,
    generate_sha512_hash,
)

MAIN = "pcluster_dcv_ext_auth.pcluster_dcv_ext_auth."
EXT_AUTH = MAIN + "DCVAuthenticator."


class TestOneTimeTokenHandler:
    def __init__(self):
        TestOneTimeTokenHandler.test_fixed_length()
        TestOneTimeTokenHandler.test_correct_storage()
        TestOneTimeTokenHandler.test_token_remove()

    @staticmethod
    def test_fixed_length():
        storage = OneTimeTokenHandler(3)
        storage.add_token("caso", ("patata", 1, 15.2, ["a", 2]))
        storage.add_token("as", (1, 2))
        storage.add_token("cappa", 5)
        storage.add_token("1", 15)
        assert_that(storage.get_token_value("caso")).is_none()

    @staticmethod
    def test_correct_storage():
        storage = OneTimeTokenHandler(3)
        storage.add_token("caso", ("patata", 1, 15.2, ["a", 2]))
        storage.add_token("as", (1, 2))
        storage.add_token("cappa", 5)
        assert_that(storage.get_token_value("caso")).is_equal_to(("patata", 1, 15.2, ["a", 2]))
        assert_that(storage.get_token_value("as")).is_equal_to((1, 2))
        assert_that(storage.get_token_value("cappa")).is_equal_to(5)

    @staticmethod
    def test_token_remove():
        storage = OneTimeTokenHandler(5)
        storage.add_token(1, "cascata")
        storage.get_token_value(1)
        assert_that(storage.get_token_value(1)).is_none()


def test_one_time_token_handler():
    TestOneTimeTokenHandler()


def test_token_generator():
    assert_that(generate_random_token(256)).is_not_equal_to(generate_random_token(256))
    assert_that(len(generate_random_token(128))).is_equal_to(128)


def test_sha_generator():
    assert_that(generate_sha512_hash("cavolo", "luca", 15)).is_equal_to(generate_sha512_hash("cavolo", "luca", 15))
    assert_that(generate_sha512_hash("flower")).is_equal_to(generate_sha512_hash("flower"))
    assert_that(generate_sha512_hash([1, 2, 4])).is_equal_to(generate_sha512_hash([1, 2, 4]))


def _create_row(user, command, session_id):
    return (
        "{USER}                63   0.0  0.0  4348844   3108   ??  Ss   23Jul19   2:32.46 {COMMAND} "
        "--session-id {SESSION}".format(USER=user, COMMAND=command, SESSION=session_id)
    )


@pytest.mark.parametrize(
    "user, command, session_id, result",
    [
        ("luca", "/usr/libexec/dcv/dcvagent", "mysession", True),
        ("luca", "/usr/libexec/dcv/dcvagent2", "mysession", False),
        ("wrong", "/usr/libexec/dcv/dcvagent", "mysession", False),
        ("luca", "/usr/libexec/dcv/dcvagent", "wrong", False),
    ],
)
def test_is_process_valid(user, command, session_id, result):
    expected_session_id = "mysession"
    expected_user = "luca"

    assert_that(
        DCVAuthenticator.is_process_valid(_create_row(user, command, session_id), expected_user, expected_session_id)
    ).is_equal_to(result)


def mock_generate_random_token(mocker, value):
    mocker.patch(MAIN + "generate_random_token", return_value=value)


def mock_verify_session_existence(mocker, exists):
    def _return_value(user, sessionid):
        if not exists:
            raise DCVAuthenticator.IncorrectRequestException("The given session for the user does not exists")

    mocker.patch(EXT_AUTH + "_verify_session_existence", side_effect=_return_value)


def mock_os(mocker, user, timestamp):
    class FileProperty(object):
        pass

    file_property = FileProperty
    file_property.st_uid = 1
    file_property.st_size = b"800"
    file_property.st_mtime = timestamp
    file_property.pw_name = user
    file_property.st_mode = 0

    mocker.patch(MAIN + "os.stat", return_value=file_property, autospec=True)
    mocker.patch(MAIN + "os.remove")
    mocker.patch(MAIN + "getpwuid", autospec=True, return_value=file_property)


@pytest.mark.parametrize(
    "parameters, keys, result",
    [
        ({"a": "5", "b": "2"}, ["authUser", "sessionID"], DCVAuthenticator.IncorrectRequestException),
        ({"authUser": "5", "b": "2"}, ["authUser", "sessionID"], DCVAuthenticator.IncorrectRequestException),
        ({"a": "5", "sessionID": "2"}, ["authUser", "sessionID"], DCVAuthenticator.IncorrectRequestException),
        ({"authUser": "luca", "sessionID": "1234"}, ["authUser", "sessionID"], ["luca", "1234"]),
        ({"requestToken": "ciao"}, ["requestToken"], ["ciao"]),
    ],
)
def test_get_request_token_parameter(parameters, keys, result):
    if isinstance(result, list):
        assert_that(DCVAuthenticator._get_values_from_parameters(parameters, keys)).is_equal_to(result)
    else:
        with pytest.raises(result):
            DCVAuthenticator._get_values_from_parameters(parameters, keys)


def test_get_request_token(mocker):
    token_value = "1234abcd_-"
    user = "centos"
    session_id = "mysession"

    mock_verify_session_existence(mocker, exists=True)
    mock_generate_random_token(mocker, token_value)
    # all correct
    assert_that(DCVAuthenticator._get_request_token(user, session_id)).is_equal_to(
        json.dumps({"requestToken": token_value, "requiredFile": generate_sha512_hash(token_value)})
    )
    assert_that(DCVAuthenticator._request_token_manager.get_token_value(token_value)[:-1]).is_equal_to(
        (user, session_id)
    )
    # session does not exists
    mock_verify_session_existence(mocker, exists=False)
    with pytest.raises(DCVAuthenticator.IncorrectRequestException):
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
    with pytest.raises(DCVAuthenticator.IncorrectRequestException):
        DCVAuthenticator._get_request_token(user, session_id)


@pytest.mark.parametrize("token", ["assvbsd", "?" + "".join(("c" for _ in range(255)))])
def test_get_session_token_regex(token):
    with pytest.raises(DCVAuthenticator.IncorrectRequestException):
        DCVAuthenticator._get_session_token(token)


def test_check_auth(mocker):
    token = generate_random_token(256)
    user = "centos"
    session_id = "mysession"
    mock_verify_session_existence(mocker, exists=True)
    # it's valid
    DCVAuthenticator._session_token_manager.add_token(
        token, DCVAuthenticator.DCVAuthTokenValues(user, session_id, datetime.utcnow())
    )
    assert_that(DCVAuthenticator._check_auth(session_id, token)).is_equal_to(user)
    # it's expired
    DCVAuthenticator._session_token_manager.add_token(
        token,
        DCVAuthenticator.DCVAuthTokenValues(user, session_id, datetime.utcnow() - DCVAuthenticator._session_token_ttl),
    )
    assert_that(DCVAuthenticator._check_auth(session_id, token)).is_none()
    # wrong session
    DCVAuthenticator._session_token_manager.add_token(
        token, DCVAuthenticator.DCVAuthTokenValues(user, session_id, datetime.utcnow())
    )
    assert_that(DCVAuthenticator._check_auth("mysession2", token)).is_none()
    # non existing path
    DCVAuthenticator._session_token_manager.add_token(
        token, DCVAuthenticator.DCVAuthTokenValues(user, session_id, datetime.utcnow())
    )
    assert_that(DCVAuthenticator._check_auth("mysession2", token)).is_none()


# py 2.7 compatibility
def obtain_timestamp(date):
    return (date - datetime(1970, 1, 1)).total_seconds()


def test_get_session_token(mocker):
    request_token = "".join(("a" for _ in range(256)))
    user = "centos"
    session_id = "mysession"
    mock_verify_session_existence(mocker, exists=True)
    # it's empty
    with pytest.raises(DCVAuthenticator.IncorrectRequestException):
        DCVAuthenticator._get_session_token(request_token)
    # it's expired
    DCVAuthenticator._request_token_manager.add_token(
        request_token,
        DCVAuthenticator.DCVAuthTokenValues(user, session_id, datetime.utcnow() - DCVAuthenticator._request_token_ttl),
    )
    with pytest.raises(DCVAuthenticator.IncorrectRequestException):
        DCVAuthenticator._get_session_token(request_token)
    # file does not exist
    DCVAuthenticator._request_token_manager.add_token(
        request_token, DCVAuthenticator.DCVAuthTokenValues(user, session_id, datetime.utcnow())
    )
    with pytest.raises(DCVAuthenticator.IncorrectRequestException):
        DCVAuthenticator._get_session_token(request_token)
    # user is different
    mock_os(mocker, "centos2", obtain_timestamp(datetime.utcnow()))
    DCVAuthenticator._request_token_manager.add_token(
        request_token, DCVAuthenticator.DCVAuthTokenValues(user, session_id, datetime.utcnow())
    )
    with pytest.raises(DCVAuthenticator.IncorrectRequestException):
        DCVAuthenticator._get_session_token(request_token)
    # file is expired
    mock_os(mocker, user, obtain_timestamp(datetime.utcnow() - DCVAuthenticator._request_token_ttl))
    DCVAuthenticator._request_token_manager.add_token(
        request_token, DCVAuthenticator.DCVAuthTokenValues(user, session_id, datetime.utcnow())
    )
    with pytest.raises(DCVAuthenticator.IncorrectRequestException):
        DCVAuthenticator._get_session_token(request_token)
    # working
    mock_os(mocker, user, obtain_timestamp(datetime.utcnow()))
    mock_verify_session_existence(mocker, exists=True)
    session_token = "1234"
    mock_generate_random_token(mocker, session_token)
    DCVAuthenticator._request_token_manager.add_token(
        request_token, DCVAuthenticator.DCVAuthTokenValues(user, session_id, datetime.utcnow())
    )
    assert_that(DCVAuthenticator._get_session_token(request_token)).is_equal_to(
        json.dumps({"sessionToken": session_token})
    )
    assert_that(DCVAuthenticator._session_token_manager.get_token_value(session_token)[:-1]).is_equal_to(
        (user, session_id)
    )
