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

"""Model describing a sudoers definition: a user allowed to run a command as another user."""

from dataclasses import dataclass


@dataclass(frozen=True)
class SudoerDefinition:
    """A user allowed to run a command as another user, with the tags that grant it.

    Describes both the definitions ParallelCluster expects and the ones the sudoers files contain; in the
    latter, ``user``, ``runas`` and ``command`` may be ``ALL``.

    Attributes:
        user: The user invoking sudo.
        runas: The user the command runs as.
        command: The command line, arguments included.
        nopasswd: Whether the definition carries NOPASSWD: true for anything run non-interactively.
        setenv: Whether the definition carries SETENV.
    """

    user: str
    runas: str
    command: str
    nopasswd: bool = True
    setenv: bool = False

    def __str__(self) -> str:
        """Return the definition in sudoers syntax, for messages only (comparison uses the fields).

        E.g. ``slurm ALL = (pcluster-admin) NOPASSWD:SETENV: /bin/x``.
        """
        tags = "".join(tag + ":" for tag, on in (("NOPASSWD", self.nopasswd), ("SETENV", self.setenv)) if on)
        return "{} ALL = ({}) {}{}".format(self.user, self.runas, tags + " " if tags else "", self.command)
