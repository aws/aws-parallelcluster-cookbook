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

"""Unit tests for the OS packages lister."""

import pytest

from pcluster_diag.util import os_packages
from pcluster_diag.util.os_packages import OsPackage, parse_dpkg_packages, parse_rpm_packages
from tests.test_helpers import completed_process


def test_parse_rpm_packages_sorts_by_name():
    output = "zlib\t1.2.11-40.el9\tx86_64\nbash\t5.1.8-9.el9\tx86_64\ngpg-pubkey\tfd431d51-4ae0493b\t(none)\n\n"

    assert parse_rpm_packages(output) == [
        OsPackage("bash", "5.1.8-9.el9", "x86_64"),
        OsPackage("gpg-pubkey", "fd431d51-4ae0493b", "(none)"),
        OsPackage("zlib", "1.2.11-40.el9", "x86_64"),
    ]


def test_parse_rpm_packages_skips_unparseable_lines():
    assert parse_rpm_packages("garbage\nbash\t5.1\tx86_64\n") == [OsPackage("bash", "5.1", "x86_64")]


def test_parse_dpkg_packages_keeps_only_installed():
    output = (
        "ii \tbash\t5.1-6ubuntu1\tamd64\n"
        "rc \told-package\t1.0\tamd64\n"
        "ii \tadduser\t3.118ubuntu5\tall\n"
        "unparseable\n"
    )

    assert parse_dpkg_packages(output) == [
        OsPackage("adduser", "3.118ubuntu5", "all"),
        OsPackage("bash", "5.1-6ubuntu1", "amd64"),
    ]


@pytest.mark.parametrize(
    "ubuntu, expected_manager, expected_command",
    [
        pytest.param(False, "rpm", "rpm", id="rpm-based OS"),
        pytest.param(True, "dpkg", "dpkg-query", id="Ubuntu"),
    ],
)
def test_installed_packages_uses_the_manager_of_the_os(monkeypatch, ubuntu, expected_manager, expected_command):
    # Both package managers are available: the OS decides.
    monkeypatch.setattr(os_packages.shutil, "which", lambda name: "/usr/bin/" + name)
    commands = []

    def fake_run_command(command, timeout=None):
        commands.append(command[0])
        stdout = "ii \tbash\t5.1\tamd64\n" if command[0] == "dpkg-query" else "bash\t5.1\tx86_64\n"
        return completed_process(stdout=stdout)

    monkeypatch.setattr(os_packages, "run_command", fake_run_command)

    packages = os_packages.installed_packages(ubuntu)

    assert packages.manager == expected_manager
    assert [package.name for package in packages.packages] == ["bash"]
    assert commands == [expected_command]


@pytest.mark.parametrize("ubuntu", [False, True])
def test_installed_packages_returns_none_without_the_manager_of_the_os(monkeypatch, ubuntu):
    # Only the package manager of the other OS family is available.
    available = "rpm" if ubuntu else "dpkg-query"
    monkeypatch.setattr(os_packages.shutil, "which", lambda name: "/usr/bin/" + name if name == available else None)

    assert os_packages.installed_packages(ubuntu) is None


def test_installed_packages_raises_when_manager_fails(monkeypatch):
    monkeypatch.setattr(os_packages.shutil, "which", lambda name: "/usr/bin/rpm" if name == "rpm" else None)
    monkeypatch.setattr(
        os_packages, "run_command", lambda command, timeout=None: completed_process(1, stderr="db locked")
    )

    with pytest.raises(RuntimeError, match="rpm failed with exit code 1: db locked"):
        os_packages.installed_packages(ubuntu=False)
