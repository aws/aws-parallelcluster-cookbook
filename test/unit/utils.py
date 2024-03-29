# Copyright 2024 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with
#  the License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.
from collections import namedtuple
from functools import wraps


def do_nothing_decorator(*args, **kwargs):
    """
    Decorate by doing nothing.

    This decorator is useful to patch real decorators for testing, e.g. the retry decorator.
    """

    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            return f(*args, **kwargs)

        return decorated_function

    return decorator


MockedBoto3Request = namedtuple(
    "MockedBoto3Request", ["method", "response", "expected_params", "generate_error", "error_code"]
)
