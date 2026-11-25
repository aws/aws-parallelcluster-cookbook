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

"""Reading the configuration files of the node, with the secrets they hold redacted."""

import glob
import os
import re
from typing import List, NamedTuple, Optional, Sequence

REDACTED = "<redacted>"

# A "key = value" or "key: value" setting whose key names a secret, e.g. ldap_default_authtok in sssd.conf or
# StoragePass in slurmdbd.conf. "credential" is not one: in sssd.conf, cache_credentials and
# offline_credentials_expiration are settings, not secrets. The JSON files ParallelCluster writes hold the ARNs of the
# secrets, not the secrets.
_SECRET_SETTING = re.compile(
    r"^(?P<key>\s*[\w.-]*(?:pass|secret|authtok|token)[\w.-]*\s*[=:]\s*)\S.*$",
    re.IGNORECASE | re.MULTILINE,
)


class ConfigFile(NamedTuple):
    """A configuration file of the node: its content with the secrets redacted, or the error reading it."""

    path: str
    content: Optional[str] = None
    error: Optional[str] = None


def redact_secrets(text: str) -> str:
    """Return ``text`` with the value of every setting whose key names a secret replaced by ``<redacted>``."""
    return _SECRET_SETTING.sub(lambda match: match["key"] + REDACTED, text)


def read_config_files(patterns: Sequence[str]) -> List[ConfigFile]:
    """Return the files matching the glob ``patterns``, in pattern order and sorted by path within a pattern.

    A pattern that matches no file is skipped, since the files differ by node type, and a file matched by several
    patterns is returned once. The secrets are redacted from the content; a file that cannot be read is returned with
    its error.
    """
    files: List[ConfigFile] = []
    seen = set()
    for pattern in patterns:
        for path in sorted(glob.glob(pattern)):
            if path in seen or not os.path.isfile(path):
                continue
            seen.add(path)
            try:
                with open(path, encoding="utf-8", errors="replace") as config_file:
                    content = config_file.read()
                files.append(ConfigFile(path, content=redact_secrets(content)))
            except OSError as error:
                files.append(ConfigFile(path, error=str(error)))
    return files


def render(files: Sequence[ConfigFile]) -> str:
    """Return ``files`` as one text, each after a ``==> path <==`` header, as ``tail`` prints several files."""
    sections = []
    for config_file in files:
        body = config_file.content if config_file.error is None else "<could not read: {}>".format(config_file.error)
        sections.append("==> {} <==\n{}{}".format(config_file.path, body, "" if body.endswith("\n") else "\n"))
    return "\n".join(sections)
