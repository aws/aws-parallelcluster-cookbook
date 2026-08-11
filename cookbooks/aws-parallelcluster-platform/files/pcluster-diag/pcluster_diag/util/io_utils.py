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

"""Generic I/O helpers."""

import configparser
from pathlib import Path
from typing import Dict, Optional, Union


def write_text_file(path: Path, text: str) -> None:
    """Write ``text`` to ``path``, creating parent directories as needed.

    Args:
        path: The destination file path.
        text: The text to write.
    """
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def read_ini_option(path: str, section: str, option: Optional[str] = None) -> Union[str, Dict[str, str], None]:
    """Read from the ``section`` of the INI file at ``path``.

    With ``option`` provided, return that option's stripped value, or None when the section or option is
    absent or the value is empty. With ``option`` left as None, return the whole ``section`` as a dict of
    its stripped key/value pairs (an empty dict when the section is absent).

    Interpolation is disabled so a ``%`` in a value (e.g. a url-encoded arn) stays literal, and duplicate
    keys are tolerated (the last one wins).

    Raises:
        FileNotFoundError: If the file does not exist.
    """
    parser = configparser.ConfigParser(interpolation=None, strict=False)
    with open(path, encoding="utf-8") as config_file:
        parser.read_file(config_file)
    if option is None:
        if not parser.has_section(section):
            return {}
        return {key: value.strip() for key, value in parser.items(section)}
    if not parser.has_option(section, option):
        return None
    return parser.get(section, option).strip() or None
