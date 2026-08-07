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

"""Helpers for inspecting a path's ownership and permissions."""

import stat
from dataclasses import dataclass
from pathlib import Path

from pcluster_diag.util import users


@dataclass
class PathStat:
    """The ownership and permissions of a filesystem path.

    Attributes:
        owner: The owning user name, or the numeric uid as a string if it has no ``/etc/passwd`` entry.
        group: The owning group name, or the numeric gid as a string if it has no ``/etc/group`` entry.
        mode: The permission bits as a 4-digit octal string (e.g. ``0755``).
    """

    owner: str
    group: str
    mode: str


def stat_path(path: str) -> PathStat:
    """Return the owner, group, and octal mode of ``path``.

    Raises:
        FileNotFoundError: If ``path`` does not exist.
    """
    info = Path(path).stat()
    return PathStat(
        owner=users.get_username_for_uid(info.st_uid),
        group=users.get_groupname_for_gid(info.st_gid),
        mode=format_bits(stat.S_IMODE(info.st_mode)),
    )


def format_bits(bits: int) -> str:
    """Return permission ``bits`` as a 4-digit octal string (e.g. 0o640 -> ``0640``)."""
    return format(bits, "04o")


def parse_mode(mode: str) -> int:
    """Return the integer permission bits of an octal ``mode`` string (e.g. ``0640`` -> 0o640)."""
    return int(mode, 8)


# Permission bits in report order, with the wording used in findings. Octal alone ("missing 0100") is
# not actionable in a report, so findings name the access instead.
_BIT_DESCRIPTIONS = (
    (stat.S_IRUSR, "owner read"),
    (stat.S_IWUSR, "owner write"),
    (stat.S_IXUSR, "owner execute/traverse"),
    (stat.S_IRGRP, "group read"),
    (stat.S_IWGRP, "group write"),
    (stat.S_IXGRP, "group execute/traverse"),
    (stat.S_IROTH, "other read"),
    (stat.S_IWOTH, "other write"),
    (stat.S_IXOTH, "other execute/traverse"),
)


def describe_bits(bits: int) -> str:
    """Return ``bits`` as the accesses they grant (e.g. 0o022 -> ``group write, other write``)."""
    return ", ".join(description for bit, description in _BIT_DESCRIPTIONS if bits & bit)
