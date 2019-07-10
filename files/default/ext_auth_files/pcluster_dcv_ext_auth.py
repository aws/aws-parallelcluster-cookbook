# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance
# with the License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.
from __future__ import print_function
from future.backports import OrderedDict
from future.backports.http.server import BaseHTTPRequestHandler, HTTPServer
from future.backports.socketserver import ThreadingMixIn
from future.backports.urllib.parse import parse_qsl, urlparse

import hashlib
import json
import os
import random
import re
import shutil
import ssl
import string
import subprocess
import sys
from collections import namedtuple
from datetime import datetime, timedelta
from pwd import getpwuid

import argparse

from retry.api import retry_call

AUTHORIZATION_FILE_DIR = "/run/parallelcluster/dcv_ext_auth"
LOG_FILE_PATH = "/var/log/parallelcluster/dcv_ext_auth.log"


class OneTimeTokenHandler:
    """This class store tokens with information associated with them"""

    def __init__(self, max_number_of_tokens):
        self._tokens = OrderedDict()
        self._max_number_of_tokens = max_number_of_tokens

    def add_token(self, token, values):
        """
        Add a token with his corresponding values in the storage

        :param token  the token to store
        :param values a tuple of values to store
        """
        while len(self._tokens) >= self._max_number_of_tokens:
            # we remove the first token stored
            self._tokens.popitem(last=False)
        self._tokens[token] = values

    def get_token_value(self, token):
        """Pop the value of the token if present, else returns None"""
        return self._tokens.pop(token, None)


class DCVAuthenticator(BaseHTTPRequestHandler):
    """This class handles the authentication for DCV."""

    class IncorrectRequestException(Exception):
        pass

    USER_REGEX = r"^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$"
    SESSION_REGEX = r"^([a-zA-Z0-9_-]{0,128})$"
    TOKEN_REGEX = r"^([a-zA-Z0-9_-]{256})$"
    MAX_NUMBER_OF_TR = 500
    MAX_NUMBER_OF_TS = 100
    SECONDS_OF_LIFE_TR = 10
    SECONDS_OF_LIFE_TS = 30

    DCVAuthTokenValues = namedtuple("ExtAuthTokenValues", "user dcv_session_id creation_time")

    _request_token_manager = OneTimeTokenHandler(MAX_NUMBER_OF_TR)
    _session_token_manager = OneTimeTokenHandler(MAX_NUMBER_OF_TS)
    _request_token_ttl = timedelta(seconds=SECONDS_OF_LIFE_TR)
    _session_token_ttl = timedelta(seconds=SECONDS_OF_LIFE_TS)


    def do_GET(self):  # noqa N802
        """
        Handle user add-user request.

        The format of the request should be:
            curl -X GET -G http://localhost:<port> -d action=requestToken -d authUser=<username> -d sessionID=<ID>
            curl -X GET -G http://localhost:<port> -d action=sessionToken -d requestToken=<tr>
        """
        try:
            parameters = dict(parse_qsl(urlparse(self.path).query))
            if not parameters or len(parameters) > 3:
                raise DCVAuthenticator.IncorrectRequestException(
                    "Incorrect number of parameters passed.\nParameters: {0}".format(parameters)
                )
            action = self._get_values_from_parameters(parameters, ["action"])[0]
            if action == "requestToken":
                username, session_id = self._get_values_from_parameters(parameters, ["authUser", "sessionID"])
                result = self._get_request_token(username, session_id)
            elif action == "sessionToken":
                request_token = self._get_values_from_parameters(parameters, ["requestToken"])[0]
                result = self._get_session_token(request_token)
            else:
                raise DCVAuthenticator.IncorrectRequestException("The action specified is not correct")
            self._set_headers(400, content="application/json")
            self.wfile.write(result.encode())
        except DCVAuthenticator.IncorrectRequestException as e:
            self.log_message("ERROR: {0}".format(e))
            self._return_bad_request(e)

    def do_POST(self):  # noqa N802
        """
        Handle DCV post request.

        The format of the request is the following:
            curl -k http://localhost:<port> -d sessionId=<session-id> -d authenticationToken=<token>
        """
        try:
            length = int(self.headers["Content-Length"])
            field_data = self.rfile.read(length).decode("utf-8")
            parameters = dict(parse_qsl(field_data))
            if len(parameters) != 3:
                raise DCVAuthenticator.IncorrectRequestException(
                    "Incorrect number of parameters passed.\nParameters: {0}".format(parameters)
                )
            session_token, session_id = self._get_values_from_parameters(
                parameters, ["authenticationToken", "sessionId"]
            )

            authorized_user = self._check_auth(session_id, session_token)
            if authorized_user:
                self._return_auth_ok(username=authorized_user)
            else:
                raise DCVAuthenticator.IncorrectRequestException("The session token is not valid")
        except DCVAuthenticator.IncorrectRequestException as e:
            self.log_message("ERROR: {0}".format(e))
            self._return_auth_ko(e)

    def log_message(self, formatting, *args):
        self.server.log_file.write(
            "{0} - - [{1}] {2}\n".format(self.address_string(), datetime.utcnow(), formatting % args)
        )
        self.server.log_file.flush()

    def _set_headers(self, response, content="text/xml", length=None):
        self.send_response(response)
        self.send_header("Content-type", content)
        if length:
            self.send_header("Content-Length", length)
        self.end_headers()

    def _return_auth_ko(self, message):
        http_string = '<auth result="no"><message>{0}</message></auth>'.format(message)
        self._set_headers(200, length=len(http_string))
        self.wfile.write(http_string.encode())

    def _return_auth_ok(self, username):
        http_string = '<auth result="yes"><username>{0}</username></auth>'.format(username)
        self._set_headers(200, length=len(http_string))
        self.wfile.write(http_string.format(username).encode())

    def _return_bad_request(self, message):
        self._set_headers(200)
        self.wfile.write("{0}\n".format(message).encode())

    @staticmethod
    def _get_values_from_parameters(parameters, keys):
        try:
            return [parameters[key] for key in keys]
        except KeyError:
            raise DCVAuthenticator.IncorrectRequestException(
                "Incorrect parameters for the request token\n" "They should be {0}".format(", ".join(keys))
            )

    @classmethod
    def _check_auth(cls, session_id, token):
        DCVAuthenticator._validate_request(session_id, DCVAuthenticator.SESSION_REGEX, "sessionid")
        DCVAuthenticator._validate_request(token, DCVAuthenticator.TOKEN_REGEX, "session token")
        values = cls._session_token_manager.get_token_value(token)
        if (
                values
                and values.dcv_session_id == session_id
                and datetime.utcnow() - values.creation_time <= cls._session_token_ttl
        ):
            return values.user

    @classmethod
    def _get_request_token(cls, user, session_id):
        DCVAuthenticator._validate_request(user, DCVAuthenticator.USER_REGEX, "authUser")
        DCVAuthenticator._validate_request(session_id, DCVAuthenticator.SESSION_REGEX, "sessionId")
        DCVAuthenticator._verify_session_existence(user, session_id)
        request_token = generate_random_token(256)
        filename = generate_sha512_hash(request_token)
        cls._request_token_manager.add_token(
            request_token, DCVAuthenticator.DCVAuthTokenValues(user, session_id, datetime.utcnow())
        )
        cls._request_token_manager.add_token(
            request_token, DCVAuthenticator.DCVAuthTokenValues(user, session_id, datetime.utcnow())
        )
        return json.dumps({"requestToken": request_token, "requiredFile": filename})

    @classmethod
    def _get_session_token(cls, request_token):
        DCVAuthenticator._validate_request(request_token, DCVAuthenticator.TOKEN_REGEX, "requestToken")
        values = cls._request_token_manager.get_token_value(request_token)
        if not values:
            raise DCVAuthenticator.IncorrectRequestException("The requestToken parameter is not a valid requestToken")

        tr_time = values.creation_time
        user = values.user
        session_id = values.dcv_session_id
        if datetime.utcnow() - tr_time > cls._request_token_ttl:
            raise DCVAuthenticator.IncorrectRequestException("The requestToken is not valid anymore")

        file_name = generate_sha512_hash(request_token)
        try:
            path = "{0}/{1}".format(AUTHORIZATION_FILE_DIR, file_name)
            file_details = os.stat(path)
            if getpwuid(file_details.st_uid).pw_name != user:
                raise DCVAuthenticator.IncorrectRequestException("The user is not the one that created the file")
            if datetime.utcnow() - datetime.utcfromtimestamp(file_details.st_mtime) > cls._request_token_ttl:
                raise DCVAuthenticator.IncorrectRequestException("The file has expired")
            os.remove(path)
        except OSError:
            raise DCVAuthenticator.IncorrectRequestException("The file created by the user does not exist")

        DCVAuthenticator._verify_session_existence(user, session_id)
        session_token = generate_random_token(256)
        cls._session_token_manager.add_token(
            session_token, DCVAuthenticator.DCVAuthTokenValues(user, session_id, datetime.utcnow())
        )
        return json.dumps({"sessionToken": session_token})

    @staticmethod
    def _validate_request(string_to_test, regex, resource_name):
        if not re.match(regex, string_to_test):
            raise DCVAuthenticator.IncorrectRequestException("The {0} parameter is not a valid.".format(resource_name))

    # TODO Once the DCV team updates their code and allows list-session to list all session even for non-root user, we
    # should update this code.
    @staticmethod
    def _is_session_valid(user, session_id):
        # we remove the first and the last because they are the heading and empty, respectively
        processes = subprocess.check_output(["ps", "aux"]).decode("utf-8").split("\n")[1:-1]
        # we check that the filter is empty
        if not next(filter(lambda x: DCVAuthenticator.is_process_valid(x, user, session_id), processes), None):
            raise DCVAuthenticator.IncorrectRequestException("The given session for the user does not exists")

    @staticmethod
    def _verify_session_existence(user, session_id):
        retry_call(DCVAuthenticator._is_session_valid, fargs=[user, session_id], tries=5, delay=1)

    @staticmethod
    def is_process_valid(row, user, session_id):
        # row example:
        # centos 63 0.0 0.0 4348844 3108   ??  Ss   23Jul19   2:32.46  /usr/libexec/dcv/dcvagent --session-id mysession
        fields = row.split()
        command_index = 10
        session_name_index = 12
        user_index = 0
        dcv_agent_path = "/usr/libexec/dcv/dcvagent"
        return (
                fields[command_index] == dcv_agent_path
                and fields[user_index] == user
                and fields[session_name_index] == session_id
        )


class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
    """Handle requests in a separate thread."""


def set_server_logging(server):
    log_file = open(LOG_FILE_PATH, "w")
    os.chmod(LOG_FILE_PATH, 0o644)
    server.log_file = log_file


def run_server(port, certificate=None, key=None):
    """
    This class run the external authenticator server on localhost.

    The external authenticator *must* be run as a separate user, it works in two phase: first you wanna make a request
    like:
    curl -X GET -G http://localhost:<port> -d action=requestToken -d authUser=<username> -d sessionID=<ID>
    curl -X GET -G http://localhost:<port> -d action=sessionToken -d requestToken=<tr>

    :param port: the port in which you want to start the server
    :param certificate: the certificate to use if https
    :param key: the key to use if https and it's not in certificate
    """
    server_address = ("localhost", port)
    httpd = ThreadedHTTPServer(server_address, DCVAuthenticator)
    set_server_logging(httpd)
    if certificate:
        if key:
            httpd.socket = ssl.wrap_socket(httpd.socket, certfile=certificate, keyfile=key, server_side=True)
        else:
            httpd.socket = ssl.wrap_socket(httpd.socket, certfile=certificate, server_side=True)
    print(
        "Starting DCV external authenticator {PROTOCOL} server on port {PORT}, use <Ctrl-C> to stop".format(
            PROTOCOL="HTTPS" if certificate else "HTTP", PORT=port
        )
    )
    httpd.serve_forever()


def get_arguments():
    parser = argparse.ArgumentParser(description="Execute the ParallelCluster External Authenticator")
    parser.add_argument("--port", help="The port in which you want to start the server", type=int)
    parser.add_argument(
        "--certificate", help="The certificate to use for the external authenticator to run in HTTPS. Has to be .pem"
    )
    parser.add_argument("--key", help="The .key of the certificate, if not included in it")
    return parser.parse_args()


def generate_random_token(token_length):
    """This function generate CSPRNG compliant random tokens."""
    allowed_chars = "".join((string.ascii_letters, string.digits, "_", "-"))
    max_int = len(allowed_chars) - 1
    system_random = random.SystemRandom()
    return "".join(allowed_chars[system_random.randint(0, max_int)] for _ in range(token_length))


def generate_sha512_hash(*args):
    """This function generates a sha512 """
    hash_handler = hashlib.sha512()
    for arg in args:
        hash_handler.update(str(arg).encode("utf-8"))
    return hash_handler.hexdigest()


def main():
    try:
        args = get_arguments()
        # cleaning up the directory containing old files
        shutil.rmtree(AUTHORIZATION_FILE_DIR, ignore_errors=True)
        run_server(port=args.port if args.port else 8444, certificate=args.certificate, key=args.key)
    except KeyboardInterrupt:
        print("Closing the server")
    except Exception as e:
        print("Unexpected error of type {0}: {1}".format(type(e).__name__, e))
        sys.exit(1)


if __name__ == "__main__":
    main()
