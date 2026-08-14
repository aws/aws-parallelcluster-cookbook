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

"""Registry of diagnostic Checks.

Only explicitly registered Checks will be executed, in registration order.
"""

import logging
from typing import Dict, List, Optional, Set, Tuple

import click

from pcluster_diag.checks.cfn_hup import CfnHup
from pcluster_diag.checks.critical_paths import CriticalPathsHaveExpectedPermissions
from pcluster_diag.checks.daemon_health import ClusterDaemonsAreRunning, ClustermgtdHeartbeatIsHealthy
from pcluster_diag.checks.directory_lookup import DirectoryService
from pcluster_diag.checks.fsx_connectivity import LustreFilesystem
from pcluster_diag.checks.imds import Imds
from pcluster_diag.checks.reserved_users import ReservedUsersAndGroups
from pcluster_diag.checks.slurm_accounting import SlurmAccounting
from pcluster_diag.models.check import Check
from pcluster_diag.models.context import Context

logger = logging.getLogger(__name__)


class Registry:
    """An explicit, order-preserving collection of registered Checks.

    Checks are registered via ``register``, returned in registration order
    by ``registered_checks``, and resolved by identifier via ``get``.
    """

    def __init__(self) -> None:
        """Create an empty registry."""
        # Maps the check identifier -> the first Check registered under that name.
        # A dict preserves insertion order, so this also captures registration order.
        self._checks_by_id: Dict[str, Check] = {}

    def register(self, check: Check) -> "Registry":
        """Register ``check`` explicitly, preserving registration order, and return this registry.

        Returning ``self`` lets Checks be registered inline by chaining ``register`` calls (see
        ``DEFAULT_REGISTRY`` below). If a Check with the same identifier is already registered, warn,
        keep the first Check, and drop ``check`` without aborting registration.
        """
        identifier = check.identifier
        if identifier in self._checks_by_id:
            logger.warning(
                "Duplicate check identifier '%s': keeping the first Check registered "
                "under that name and ignoring the duplicate.",
                identifier,
            )
            return self
        self._checks_by_id[identifier] = check
        return self

    def registered_checks(self) -> List[Check]:
        """Return the registered Checks in registration order, one per identifier."""
        return list(self._checks_by_id.values())

    def select_checks(self, context: Context, assume_yes: bool = False) -> Tuple[List[Check], List[Check], List[Check]]:
        """Classify the registered Checks for ``context`` and prompt for any required confirmations.

        Returns a ``(registered, not_applicable, not_approved)`` triple, each in registration order:

        - ``registered``: every registered Check (the Runner runs those that are neither skipped nor
          declined).
        - ``not_applicable``: non-applicable Checks (``should_run(context)`` False); the Runner records
          these as SKIPPED_NOT_APPLICABLE.
        - ``not_approved``: applicable, confirmation-required Checks whose prompt the user declined; the
          Runner records these as SKIPPED_BY_USER.

        Confirmation-required Checks (``approval_required(context)`` True) are listed and prompted yes/no
        here, before the Runner is invoked, so execution begins only once every decision is collected.
        When ``assume_yes`` is True, they are approved without prompting.
        """
        registered = self.registered_checks()
        applicable = [check for check in registered if check.should_run(context)]
        applicable_ids = {check.identifier for check in applicable}

        require_confirmation = [check for check in applicable if check.approval_required(context)]
        declined = self._prompt_for_confirmations(require_confirmation, assume_yes=assume_yes)

        not_applicable: List[Check] = []
        not_approved: List[Check] = []
        for check in registered:
            if check.identifier not in applicable_ids:
                not_applicable.append(check)
            elif check.identifier in declined:
                not_approved.append(check)

        return registered, not_applicable, not_approved

    @staticmethod
    def _prompt_for_confirmations(checks_to_confirm: List[Check], assume_yes: bool = False) -> Set[str]:
        """List the confirmation-required Checks, prompt yes/no for each, and return the declined identifiers.

        All prompts are answered before any Check runs, so the listing happens up front (Req 6.10, 11.3).
        When ``assume_yes`` is True, every Check is approved without prompting (nothing is declined).
        """
        if not checks_to_confirm or assume_yes:
            return set()

        logger.info("The following checks require your confirmation before they run:")
        for check in checks_to_confirm:
            logger.info("  - %s: %s", check.identifier, check.description)

        return {
            check.identifier
            for check in checks_to_confirm
            if not click.confirm("Run check '{}'?".format(check.identifier), err=True)
        }

    def get(self, identifier: str) -> Optional[Check]:
        """Return the registered Check with ``identifier``, or ``None`` if none."""
        return self._checks_by_id.get(identifier)


# The default Registry, in execution order. Concrete Checks are registered inline here by chaining
# ``register`` (which returns the registry).
DEFAULT_REGISTRY = (
    Registry()
    .register(Imds())
    .register(CfnHup())
    .register(ReservedUsersAndGroups())
    .register(CriticalPathsHaveExpectedPermissions())
    .register(ClusterDaemonsAreRunning())
    .register(ClustermgtdHeartbeatIsHealthy())
    .register(DirectoryService())
    .register(SlurmAccounting())
    .register(LustreFilesystem())
    # FsxTargetsAreReachable (approval_required: heavier per-target probe) is deliberately left out: its
    # findings are not signals we trust yet. See its docstring in checks/fsx_connectivity.py.
)
