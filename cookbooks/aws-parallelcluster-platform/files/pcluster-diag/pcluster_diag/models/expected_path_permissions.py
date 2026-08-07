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

"""Model describing the ownership and permissions a filesystem path is expected to have.

A path's mode is not judged by equality with whatever the cookbook happens to set: the same path
usually tolerates several modes, and both loosening *and* tightening a mode can break a daemon (e.g.
tightening Slurm's StateSaveLocation to 0700 is fine, but 0600 drops the traverse bit slurmctld
needs). A mode expectation is therefore expressed as the bits the consuming daemon needs
(``required_bits``), the bits that make the path insecure (``forbidden_bits``), or -- where a daemon
validates the mode by equality -- the exact set of modes it accepts (``allowed_modes``).

Whether an over-permissive mode is a failure is also per path: munged refuses to start from a key
others can read, while slurmctld runs fine on a world-writable StateSaveLocation.
"""

from dataclasses import dataclass
from typing import FrozenSet, Optional

from pcluster_diag.util.path_permissions import format_bits, parse_mode


@dataclass(frozen=True)
class ExpectedPathPermissions:
    """The ownership and permissions a filesystem path is expected to have on given node types.

    Attributes:
        path: The absolute path to inspect.
        owner: The expected owning user name.
        group: The expected owning group name.
        node_types: The node types the path is expected on; a Check inspects it only on those.
        required_bits: Permission bits the consuming daemon needs; missing any of them is a failure.
        forbidden_bits: Permission bits that make the path insecure.
        allowed_modes: The exact modes accepted, for daemons that validate the mode by equality. When
            set, ``required_bits``/``forbidden_bits`` are not consulted.
        forbidden_bits_break_daemon: Whether granting ``forbidden_bits`` stops the consuming daemon,
            making it a failure rather than an advisory.

    Raises:
        ValueError: If the expectation would inspect nothing or contradicts itself.
    """

    path: str
    owner: str
    group: str
    node_types: tuple
    required_bits: int = 0
    forbidden_bits: int = 0
    allowed_modes: Optional[FrozenSet[str]] = None
    forbidden_bits_break_daemon: bool = False

    def __post_init__(self) -> None:
        """Reject expectations that would silently inspect nothing or contradict themselves."""
        declares_bits = bool(self.required_bits or self.forbidden_bits)
        if self.allowed_modes is not None:
            if not self.allowed_modes:
                raise ValueError("{}: allowed_modes must not be empty".format(self.path))
            if declares_bits:
                raise ValueError(
                    "{}: allowed_modes cannot be combined with required_bits/forbidden_bits".format(self.path)
                )
        elif not declares_bits:
            raise ValueError(
                "{}: declare required_bits, forbidden_bits or allowed_modes, otherwise the mode is "
                "never inspected".format(self.path)
            )
        if self.required_bits & self.forbidden_bits:
            raise ValueError(
                "{}: {} is both required and forbidden".format(
                    self.path, format_bits(self.required_bits & self.forbidden_bits)
                )
            )
        if self.forbidden_bits_break_daemon and not self.forbidden_bits:
            raise ValueError("{}: forbidden_bits_break_daemon without forbidden_bits".format(self.path))

    def missing_bits(self, mode: str) -> int:
        """Return the ``required_bits`` absent from ``mode`` (0 when none are missing)."""
        return self.required_bits & ~parse_mode(mode)

    def offending_bits(self, mode: str) -> int:
        """Return the ``forbidden_bits`` present in ``mode`` (0 when none are present)."""
        return self.forbidden_bits & parse_mode(mode)

    def is_disallowed_mode(self, mode: str) -> bool:
        """Return whether ``allowed_modes`` is set and ``mode`` is not one of them."""
        if self.allowed_modes is None:
            return False
        return parse_mode(mode) not in {parse_mode(allowed) for allowed in self.allowed_modes}

    def allowed_modes_description(self) -> str:
        """Return the accepted modes ordered for a stable message (e.g. ``0600 or 0640``)."""
        return " or ".join(sorted(self.allowed_modes or (), key=parse_mode))
