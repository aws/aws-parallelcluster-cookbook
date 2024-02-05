# Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with
#  the License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

"""
This module loads pytest fixtures and plugins needed by all tests.

It's very useful for fixtures that need to be shared among all tests.
"""

import os

import boto3
import pytest
from botocore.stub import Stubber


@pytest.fixture()
def test_datadir(request, datadir):
    """
    Inject the datadir with resources for the specific test function.

    If the test function is declared in a class then datadir is ClassName/FunctionName
    otherwise it is only FunctionName.
    """
    function_name = request.function.__name__
    if not request.cls:
        return datadir / function_name

    class_name = request.cls.__name__
    return datadir / class_name / function_name


@pytest.fixture()
def boto3_stubber(mocker, boto3_stubber_path):
    """
    Create a function to easily mock boto3 clients.

    To mock a boto3 service simply pass the name of the service to mock and
    the mocked requests, where mocked_requests is an object containing the method to mock,
    the response to return and the expected params for the boto3 method that gets called.

    The function makes use of botocore.Stubber to mock the boto3 API calls.
    Multiple boto3 services can be mocked as part of the same test.

    :param boto3_stubber_path is the path of the boto3 import to mock. (e.g. pcluster.config.validators.boto3)
    """
    created_stubbers = []
    mocked_clients = {}

    mocked_client_factory = mocker.patch(boto3_stubber_path, autospec=True)
    # use **kwargs to skip parameters passed to the boto3.client other than the "service"
    # e.g. boto3.client("ec2", region_name=region, ...) --> x = ec2
    mocked_client_factory.client.side_effect = lambda x, **kwargs: mocked_clients[x]

    def _boto3_stubber(service, mocked_requests):
        if "AWS_DEFAULT_REGION" not in os.environ:
            # We need to provide a region to boto3 to avoid no region exception.
            # Which region to provide is arbitrary.
            os.environ["AWS_DEFAULT_REGION"] = "us-east-1"
        client = boto3.client(service)
        stubber = Stubber(client)
        # Save a ref to the stubber so that we can deactivate it at the end of the test.
        created_stubbers.append(stubber)

        # Attach mocked requests to the Stubber and activate it.
        if not isinstance(mocked_requests, list):
            mocked_requests = [mocked_requests]
        for mocked_request in mocked_requests:
            if mocked_request.generate_error:
                stubber.add_client_error(
                    mocked_request.method,
                    service_message=mocked_request.response,
                    expected_params=mocked_request.expected_params,
                    service_error_code=mocked_request.error_code,
                )
            else:
                stubber.add_response(
                    mocked_request.method, mocked_request.response, expected_params=mocked_request.expected_params
                )
        stubber.activate()

        # Add stubber to the collection of mocked clients. This allows to mock multiple clients.
        # Mocking twice the same client will replace the previous one.
        mocked_clients[service] = client
        return client

    # yield allows to return the value and then continue the execution when the test is over.
    # Used for resources cleanup.
    yield _boto3_stubber

    # Assert that all mocked requests were consumed and deactivate all stubbers.
    for stubber in created_stubbers:
        stubber.assert_no_pending_responses()
        stubber.deactivate()
