# Copyright 2026 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

"""Configuration of the AWS clients that checks create."""

from typing import Optional

from botocore.config import Config


def client_config(proxy: Optional[str], timeout: int) -> Config:
    """Return a botocore client config with ``timeout`` and, when set, the cluster ``proxy``.

    ``proxy`` is the ``cluster.proxy`` value of dna.json: the ParallelCluster daemons reach AWS through it, and dna.json
    holds the literal string "NONE" when no proxy is configured.
    """
    proxies = {"https": proxy} if proxy and proxy != "NONE" else None
    return Config(connect_timeout=timeout, read_timeout=timeout, retries={"max_attempts": 2}, proxies=proxies)
