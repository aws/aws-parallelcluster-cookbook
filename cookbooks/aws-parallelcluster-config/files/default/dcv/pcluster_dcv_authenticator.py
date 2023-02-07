# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
import argparse
import errno
import hashlib
import json
import logging
import os
import random
import re
import ssl
import string

# A nosec comment is appended to the following line in order to disable the B404 check.
# In this file the input of the module subprocess is trusted.
import subprocess  # nosec B404
import sys
import time
from collections import OrderedDict, namedtuple
from datetime import datetime, timedelta
from http.server import BaseHTTPRequestHandler, HTTPServer
from logging.handlers import RotatingFileHandler
from pwd import getpwuid
from socketserver import ThreadingMixIn
from urllib.parse import parse_qsl, urlparse

AUTHORIZATION_FILE_DIR = "/var/spool/parallelcluster/pcluster_dcv_authenticator"
LOG_FILE_PATH = "/var/log/parallelcluster/pcluster_dcv_authenticator.log"

logger = logging.getLogger(__name__)


def retry(func, func_args, attempts=1, wait=0):
    """
    Call function and re-execute it if it raises an Exception.

    :param func: the function to execute.
    :param func_args: the positional arguments of the function.
    :param attempts: the maximum number of attempts. Default: 1.
    :param wait: delay between attempts. Default: 0.
    :returns: the result of the function.
    """
    while attempts:
        try:
            return func(*func_args)
        except Exception as e:
            attempts -= 1
            if not attempts:
                raise e

            logger.info("%s, retrying in %s seconds..", e, wait)
            time.sleep(wait)


def generate_random_token(token_length):
    """Generate CSPRNG compliant random tokens."""
    allowed_chars = "".join((string.ascii_letters, string.digits, "_", "-"))
    max_int = len(allowed_chars) - 1
    system_random = random.SystemRandom()

    return "".join(allowed_chars[system_random.randint(0, max_int)] for _ in range(token_length))


class OneTimeTokenHandler:
    """
    Store in memory tokens and information associated with them.

    The handler maintains a limited number of tokens in memory with a FIFO logic when the limits are reached.
    """

    def __init__(self, max_number_of_tokens):
        self._tokens = OrderedDict()
        self._max_number_of_tokens = max_number_of_tokens

    def add_token(self, token, token_info):
        """
        Add token and his corresponding information in the storage.

        :param token the token to store
        :param token_info a tuple of values associated to the token to store
        """
        while len(self._tokens) >= self._max_number_of_tokens:
            # Remove the first token stored
            self._tokens.popitem(last=False)

        self._tokens[token] = token_info

    def get_token_info(self, token):
        """Pop the token and return the related information if the token is present, else returns None."""
        return self._tokens.pop(token, None)


class DCVAuthenticator(BaseHTTPRequestHandler):
    """
    Simple HTTP server to handle NICE DCV authentication process.

    The authentication process to access to a DCV session is performed by the following steps:
    1. Obtain a Request Token:
    - an user declares himself and asks for a Request Token for a given DCV Session:
        - curl -X GET -G http://localhost:<port> -d action=requestToken -d authUser=<username> -d sessionID=<ID>
    - the authenticator will return a json containing requestToken and accessFile values:
        - the requestToken must be used as parameter for the Session Token request
        - the accessFile is used to verify the user identity in the Session Token request

    2. Obtain a DCV Session Token:
    - the user must create an "access file" in the AUTHORIZATION_FILE_DIR, named as the retrieved accessFile value
    - the user asks for a SessionToken (the real token to access to the DCV session)
        - curl -X GET -G http://localhost:<port> -d action=sessionToken -d requestToken=<tr>
    - the authenticator verifies the owner of the access file, the validity of the requestToken and returns
      a Session Token
    - the user can use the retrieved Session Token to connect to the DCV session.

    3. DCV connection:
    - the Session Token must be used in the web browser to access to the DCV Session
    - the DCV process, running in the same instance of the authenticator, will ask to validate the token:
        - curl -k http://localhost:<port> -d sessionId=<session-id> -d authenticationToken=<token>
    - the authenticator verifies the validity of the authenticationToken and permits the user to access to the session.
    """

    class IncorrectRequestError(Exception):
        """Class representing an incorrect request to the DCVAuthenticator."""

        pass

    USER_REGEX = r"^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$"
    SESSION_ID_REGEX = r"^([a-zA-Z0-9_-]{0,128})$"
    # A nosec comment is appended to the following line in order to disable the B105 check.
    # Since the TOKEN_REGEX is not a hardcoded password
    TOKEN_REGEX = r"^([a-zA-Z0-9_-]{256})$"  # nosec B105

    MAX_NUMBER_OF_REQUEST_TOKENS = 500
    MAX_NUMBER_OF_SESSION_TOKENS = 100
    REQUEST_TOKEN_EXPIRE_SECONDS = 10
    SESSION_TOKEN_EXPIRE_SECONDS = 30

    # Define the information associated to a specific token
    RequestTokenInfo = namedtuple("RequestTokenInfo", "user dcv_session_id creation_time access_file")
    SessionTokenInfo = namedtuple("SessionTokenInfo", "user dcv_session_id creation_time")

    # Define two token handlers with different capacity and expiration
    request_token_manager = OneTimeTokenHandler(max_number_of_tokens=MAX_NUMBER_OF_REQUEST_TOKENS)
    request_token_ttl = timedelta(seconds=REQUEST_TOKEN_EXPIRE_SECONDS)
    session_token_manager = OneTimeTokenHandler(max_number_of_tokens=MAX_NUMBER_OF_SESSION_TOKENS)
    session_token_ttl = timedelta(seconds=SESSION_TOKEN_EXPIRE_SECONDS)

    def do_GET(self):  # noqa N802, pylint: disable=C0103
        """
        Handle GET requests coming from the user to obtain request and session tokens.

        The format of the request should be:
            curl -X GET -G http://localhost:<port> -d action=requestToken -d authUser=<username> -d sessionID=<ID>
            curl -X GET -G http://localhost:<port> -d action=sessionToken -d requestToken=<tr>
        """
        try:
            logger.info("Validating user request..")
            # validate number of parameters
            parameters = dict(parse_qsl(urlparse(self.path).query))
            if not parameters or len(parameters) > 3:
                raise DCVAuthenticator.IncorrectRequestError(
                    f"Incorrect number of parameters passed.\nParameters: {parameters}"
                )

            # evaluate action parameter
            action = self._extract_parameters_values(parameters, ["action"])[0]
            if action == "requestToken":
                username, session_id = self._extract_parameters_values(parameters, ["authUser", "sessionID"])
                result = self._get_request_token(username, session_id)
            elif action == "sessionToken":
                request_token = self._extract_parameters_values(parameters, ["requestToken"])[0]
                result = self._get_session_token(request_token)
            else:
                raise DCVAuthenticator.IncorrectRequestError(f"The action specified '{action}' is not valid.")

            self._set_headers(400, content="application/json")
            self.wfile.write(result.encode())

        except DCVAuthenticator.IncorrectRequestError as e:
            logger.error(e)
            self._return_bad_request(e)

    def do_POST(self):  # noqa N802 pylint: disable=C0103
        """
        Handle POST requests, coming from NICE DCV server.

        The format of the request is the following:
            curl -k http://localhost:<port> -d sessionId=<session-id> -d authenticationToken=<token>
        """
        try:
            length = int(self.headers["Content-Length"])
            field_data = self.rfile.read(length).decode("utf-8")
            parameters = dict(parse_qsl(field_data))
            if len(parameters) != 3:
                raise DCVAuthenticator.IncorrectRequestError(
                    f"Incorrect number of parameters passed.\nParameters: {parameters}"
                )
            session_token, session_id = self._extract_parameters_values(
                parameters, ["authenticationToken", "sessionId"]
            )

            authorized_user = self._check_auth(session_id, session_token)
            if authorized_user:
                self._return_auth_ok(username=authorized_user)
            else:
                raise DCVAuthenticator.IncorrectRequestError("The session token is not valid")

        except DCVAuthenticator.IncorrectRequestError as e:
            logger.error(e)
            self._return_auth_ko(e)

    def log_message(self, fmt, *args):
        """Override Server log message by removing authentication actions."""
        if all(auth_action not in args[0] for auth_action in ["requestToken", "sectionToken"]):
            logger.info(fmt, args)

    def _set_headers(self, response, content="text/xml", length=None):
        self.send_response(response)
        self.send_header("Content-type", content)
        if length:
            self.send_header("Content-Length", length)
        self.end_headers()

    def _return_auth_ko(self, message):
        http_string = f'<auth result="no"><message>{message}</message></auth>'
        self._set_headers(200, length=len(http_string))
        self.wfile.write(http_string.encode())

    def _return_auth_ok(self, username):
        http_string = f'<auth result="yes"><username>{username}</username></auth>'
        self._set_headers(200, length=len(http_string))
        self.wfile.write(http_string.format(username).encode())

    def _return_bad_request(self, message):
        self._set_headers(200)
        self.wfile.write(f"{message}\n".encode())

    @staticmethod
    def _extract_parameters_values(parameters, keys):
        try:
            return [parameters[key] for key in keys]
        except KeyError:
            raise DCVAuthenticator.IncorrectRequestError(f"Wrong parameters. Required parameters are {', '.join(keys)}")

    @classmethod
    def _check_auth(cls, session_id, session_token):
        """Check session token expiration to see if it is still valid for the given DCV session id."""
        # validate session and session token
        DCVAuthenticator._validate_param(session_id, DCVAuthenticator.SESSION_ID_REGEX, "sessionId")
        DCVAuthenticator._validate_param(session_token, DCVAuthenticator.TOKEN_REGEX, "sessionToken")

        # search for token in the internal authenticator token storage
        token_info = cls.session_token_manager.get_token_info(session_token)
        if (
            token_info
            and token_info.dcv_session_id == session_id
            and datetime.utcnow() - token_info.creation_time <= cls.session_token_ttl
        ):
            return token_info.user
        return None

    @classmethod
    def _get_request_token(cls, user, session_id):
        """
        Obtain the request token and the "access file" name required to obtain the session token.

        Generate a Request token, store in memory and returns a json containing the token itself
        and the name of the file the user must create in the AUTHORIZATION_FILE_DIR.
        """
        logger.info("New request for Request Token from user '%s' and DCV Session Id '%s'.", user, session_id)
        # validate user and session
        DCVAuthenticator._validate_param(user, DCVAuthenticator.USER_REGEX, "authUser")
        DCVAuthenticator._validate_param(session_id, DCVAuthenticator.SESSION_ID_REGEX, "sessionId")
        DCVAuthenticator._verify_session_existence(user, session_id)
        logger.info("DCV session id and user are valid.")

        # create and register internally a request token to use to retrieve the session token
        logger.info("Generating new Request Token and Access File..")
        request_token = generate_random_token(256)
        access_file = generate_sha512_hash(request_token)
        cls.request_token_manager.add_token(
            request_token, DCVAuthenticator.RequestTokenInfo(user, session_id, datetime.utcnow(), access_file)
        )
        logger.info("Request Token and Access File generated correctly.")

        return json.dumps({"requestToken": request_token, "accessFile": access_file})

    @classmethod
    def _get_session_token(cls, request_token):
        """
        Obtain the session token to connect to the DCV session.

        Generate a Session token, store in memory and returns a json containing the token itself.
        """
        logger.info("New request for Session Token.")
        DCVAuthenticator._validate_param(request_token, DCVAuthenticator.TOKEN_REGEX, "requestToken")

        # retrieve request token information to validate it
        logger.info("Validating Request Token..")
        token_info = cls.request_token_manager.get_token_info(request_token)
        if not token_info:
            raise DCVAuthenticator.IncorrectRequestError("The requestToken parameter is not valid")
        user = token_info.user
        session_id = token_info.dcv_session_id
        access_file = token_info.access_file
        logger.info("Request Token is valid.")

        # verify token expiration
        logger.info("Verifying Request Token..")
        if datetime.utcnow() - token_info.creation_time > cls.request_token_ttl:
            raise DCVAuthenticator.IncorrectRequestError("The requestToken is not valid anymore")
        logger.info("Request Token is valid.")

        # verify user by checking if the access_file is created by the user asking the session token
        logger.info("Verifying Access File..")
        try:
            access_file_path = f"{AUTHORIZATION_FILE_DIR}/{access_file}"
            file_details = os.stat(access_file_path)
            if getpwuid(file_details.st_uid).pw_name != user:
                raise DCVAuthenticator.IncorrectRequestError("The user is not the one that created the access file")
            if datetime.utcnow() - datetime.utcfromtimestamp(file_details.st_mtime) > cls.request_token_ttl:
                raise DCVAuthenticator.IncorrectRequestError("The access file has expired")
            logger.info("Access File is valid. User identified correctly.")
            os.remove(access_file_path)
            logger.info("Access File removed correctly.")
        except OSError:
            raise DCVAuthenticator.IncorrectRequestError("The Access File does not exist")

        # create and register internally a session token
        logger.info("Generating new Session Token..")
        DCVAuthenticator._verify_session_existence(user, session_id)
        session_token = generate_random_token(256)
        cls.session_token_manager.add_token(
            session_token, DCVAuthenticator.SessionTokenInfo(user, session_id, datetime.utcnow())
        )
        logger.info("Session Token created successfully.")

        return json.dumps({"sessionToken": session_token})

    @staticmethod
    def _validate_param(string_to_test, regex, resource_name):
        if not re.match(regex, string_to_test):
            raise DCVAuthenticator.IncorrectRequestError(f"The {resource_name} parameter is not valid")

    @staticmethod
    def _is_session_valid(user, session_id):
        """
        Verify if the DCV session exists and the ownership.

        # We are using ps aux to retrieve the list of sessions
        # because currently DCV doesn't allow list-session to list all session even for non-root user.
        # TODO change this method if DCV updates his behaviour.
        """
        logger.info("Verifying NICE DCV session validity..")
        # Remove the first and the last because they are the heading and empty, respectively
        # All commands and arguments in this subprocess call are built as literals
        processes = subprocess.check_output(["/bin/ps", "aux"]).decode("utf-8").split("\n")[1:-1]  # nosec B603

        # Check the filter is empty
        if not next(
            filter(lambda process: DCVAuthenticator.check_dcv_process(process, user, session_id), processes), None
        ):
            raise DCVAuthenticator.IncorrectRequestError("The given session does not exists")
        logger.info("The NICE DCV session is valid.")

    @staticmethod
    def _verify_session_existence(user, session_id):
        retry(DCVAuthenticator._is_session_valid, func_args=[user, session_id], attempts=20, wait=1)

    @staticmethod
    def check_dcv_process(row, user, session_id):
        """Check if there is a dcvagent process running for the given user and for the given session_id."""
        # row example:
        # centos 63 0.0 0.0 4348844 3108   ??  Ss   23Jul19   2:32.46  /usr/libexec/dcv/dcvagent --mode full \
        #     --session-id mysession
        # ubuntu 2949 0.3 0.4 860568 34328 ? Sl 20:10 0:18 /usr/lib/x86_64-linux-gnu/dcv/dcvagent --mode full \
        #     --session-id mysession
        fields = row.split()
        command_index = 10
        session_name_index = 14
        user_index = 0

        return (
            fields[command_index].endswith("/dcv/dcvagent")
            and fields[user_index] == user
            and fields[session_name_index] == session_id
        )


class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
    """Handle requests in a separate thread."""


def _run_server(port, certificate=None, key=None):
    """
    Run NICE DCV authenticator server on localhost.

    The NICE DCV authenticator server *must* run with an appropriate user.

    :param port: the port in which you want to start the server
    :param certificate: the certificate to use if HTTPSs
    :param key: the private key to use if HTTPSs
    """
    server_address = ("localhost", port)
    httpd = ThreadedHTTPServer(server_address, DCVAuthenticator)

    if certificate:
        if key:
            httpd.socket = ssl.wrap_socket(  # nosec nosemgrep pylint: disable=W4902
                httpd.socket, certfile=certificate, keyfile=key, server_side=True
            )
        else:
            httpd.socket = ssl.wrap_socket(  # nosec nosemgrep pylint: disable=W4902
                httpd.socket, certfile=certificate, server_side=True
            )
    print(
        f"Starting DCV external authenticator {'HTTPS' if certificate else 'HTTP'} server on port {port}, use "
        f"<Ctrl-C> to stop "
    )
    httpd.serve_forever()


def _parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description="Execute the ParallelCluster DCV External Authenticator")
    parser.add_argument("--port", help="The port in which you want to start the HTTP server", type=int)
    parser.add_argument("--certificate", help="The certificate to use to run in HTTPS. It must be a .pem file")
    parser.add_argument("--key", help="The private key of the certificate")
    return parser.parse_args()


def generate_sha512_hash(*args):
    """Generate a salted sha512 of the given token."""
    salt = generate_random_token(256)

    hash_handler = hashlib.sha512()
    for item in args, salt:
        hash_handler.update(str(item).encode("utf-8"))

    return hash_handler.hexdigest()


def _prepare_auth_folder():
    """Delete old authorization files."""
    for access_file in os.listdir(AUTHORIZATION_FILE_DIR):
        os.remove(os.path.join(AUTHORIZATION_FILE_DIR, access_file))


def fail(message):
    """
    Print error message and exit(1).

    :param message: message to print
    """
    logger.error(message)
    sys.exit(1)


def _config_logger():
    """
    Define a logger for pcluster_dcv_authenticator.

    :return: the logger
    """
    try:
        logfile = os.path.expanduser(LOG_FILE_PATH)
        logdir = os.path.dirname(logfile)
        os.makedirs(logdir)
    except OSError as e:
        if e.errno == errno.EEXIST and os.path.isdir(logdir):
            pass
        else:
            print(f"Cannot create log file ({logfile}). Failed with exception: {e}")
            sys.exit(1)

    formatter = logging.Formatter("%(asctime)s %(levelname)s [%(module)s:%(funcName)s] %(message)s")

    logfile_handler = RotatingFileHandler(logfile, maxBytes=5 * 1024 * 1024, backupCount=1)
    logfile_handler.setFormatter(formatter)

    dcv_authenticator_logger = logging.getLogger("pcluster_dcv_authenticator")
    dcv_authenticator_logger.addHandler(logfile_handler)

    dcv_authenticator_logger.setLevel("INFO")
    return dcv_authenticator_logger


def main():
    global logger  # pylint: disable=C0103,W0603
    logger = _config_logger()
    try:
        logger.info("Starting NICE DCV authenticator server")
        args = _parse_args()
        _prepare_auth_folder()
        _run_server(port=args.port if args.port else 8444, certificate=args.certificate, key=args.key)
    except KeyboardInterrupt:
        logger.info("Closing NICE DCV authenticator server")
    except Exception as e:
        fail(f"Unexpected error of type {type(e).__name__}: {e}")


if __name__ == "__main__":
    main()
