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

"""Model describing SSSD's view of the directory backend(s)."""

from dataclasses import dataclass
from typing import Optional


@dataclass(frozen=True)
class SssdBackendStatus:
    """A read-only snapshot of SSSD's view of the directory backend(s).

    Attributes:
        summary: A compact, human-readable ``sssctl domain-status`` summary across the AD/LDAP domains.
        online: ``False`` if any AD/LDAP domain reports its backend offline, ``True`` if every domain
            reports online, ``None`` when sssctl did not report a parseable online status.
    """

    summary: str
    online: Optional[bool]
