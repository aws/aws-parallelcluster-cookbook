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

"""Helpers for reading the local POSIX user and group databases (``/etc/passwd`` and ``/etc/group``)."""

import grp
import pwd
from typing import List, Optional


def get_user_uid(name: str) -> Optional[int]:
    """Return the uid of user ``name``, or None if the user does not exist."""
    try:
        return pwd.getpwnam(name).pw_uid
    except KeyError:
        return None


def get_user_gid(name: str) -> Optional[int]:
    """Return the primary gid of user ``name``, or None if the user does not exist."""
    try:
        return pwd.getpwnam(name).pw_gid
    except KeyError:
        return None


def get_group_gid(name: str) -> Optional[int]:
    """Return the gid of group ``name``, or None if the group does not exist."""
    try:
        return grp.getgrnam(name).gr_gid
    except KeyError:
        return None


def get_username_for_uid(uid: int) -> str:
    """Return the user name for ``uid``, or the numeric uid as a string if it has no ``/etc/passwd`` entry."""
    try:
        return pwd.getpwuid(uid).pw_name
    except KeyError:
        return str(uid)


def get_groupname_for_gid(gid: int) -> str:
    """Return the group name for ``gid``, or the numeric gid as a string if it has no ``/etc/group`` entry."""
    try:
        return grp.getgrgid(gid).gr_name
    except KeyError:
        return str(gid)


def get_usernames_for_uid(uid: int) -> List[str]:
    """Return every user name mapped to ``uid`` in ``/etc/passwd``, in database order.

    More than one name means a non-unique uid: a duplicate uid makes the kernel resolve that uid to the
    first matching ``/etc/passwd`` entry, so a daemon that expects a specific user (e.g. by NOPASSWD
    sudoers rule) can instead resolve to a different name and lose its privileges.
    """
    return [entry.pw_name for entry in pwd.getpwall() if entry.pw_uid == uid]


def get_groupnames_for_gid(gid: int) -> List[str]:
    """Return every group name mapped to ``gid`` in ``/etc/group``, in database order.

    As with :func:`get_usernames_for_uid`, more than one name means a non-unique gid.
    """
    return [entry.gr_name for entry in grp.getgrall() if entry.gr_gid == gid]
