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

"""Unit tests for the generic OS package and kernel-module probes."""

import subprocess

import pytest

from pcluster_diag.util import packages


def _completed(returncode=0, stdout="", stderr=""):
    return subprocess.CompletedProcess(args=["cmd"], returncode=returncode, stdout=stdout, stderr=stderr)


def _raise_oserror(command):
    raise FileNotFoundError(command[0])


def test_package_installed_true_when_rpm_present(monkeypatch):
    monkeypatch.setattr(
        packages, "run_command", lambda command: _completed(returncode=0 if command[:2] == ["rpm", "-q"] else 1)
    )

    assert packages.package_installed(["lustre-client"]) is True


def test_package_installed_true_when_dpkg_present(monkeypatch):
    monkeypatch.setattr(
        packages, "run_command", lambda command: _completed(returncode=0 if command[0] == "dpkg" else 1)
    )

    assert packages.package_installed(["lustre-client-modules"]) is True


def test_package_installed_false_when_absent(monkeypatch):
    monkeypatch.setattr(packages, "run_command", lambda command: _completed(returncode=1))

    assert packages.package_installed(["lustre-client"]) is False


def test_package_installed_false_when_binary_missing(monkeypatch):
    monkeypatch.setattr(packages, "run_command", _raise_oserror)

    assert packages.package_installed(["lustre-client"]) is False


@pytest.mark.parametrize("returncode, expected", [(0, True), (1, False)])
def test_kernel_module_available(monkeypatch, returncode, expected):
    monkeypatch.setattr(packages, "run_command", lambda command: _completed(returncode=returncode))

    assert packages.kernel_module_available("lustre") is expected


def test_kernel_module_loaded_true_when_lsmod_lists_it(monkeypatch):
    lsmod = "Module                  Size  Used by\nlustre               1000  1\nlnet                  500  1\n"
    monkeypatch.setattr(packages, "run_command", lambda command: _completed(stdout=lsmod))

    assert packages.kernel_module_loaded("lustre") is True
    assert packages.kernel_module_loaded("ext4") is False


def test_kernel_module_loaded_false_when_lsmod_missing(monkeypatch):
    monkeypatch.setattr(packages, "run_command", _raise_oserror)

    assert packages.kernel_module_loaded("lustre") is False


def test_kernel_module_loaded_false_on_nonzero_exit(monkeypatch):
    monkeypatch.setattr(packages, "run_command", lambda command: _completed(returncode=1))

    assert packages.kernel_module_loaded("lustre") is False


def test_kernel_release_returns_uname(monkeypatch):
    monkeypatch.setattr(packages, "run_command", lambda command: _completed(stdout="6.1.0-1.amzn2023\n"))

    assert packages.kernel_release() == "6.1.0-1.amzn2023"


def test_kernel_release_none_when_uname_missing(monkeypatch):
    monkeypatch.setattr(packages, "run_command", _raise_oserror)

    assert packages.kernel_release() is None


def test_kernel_release_none_on_nonzero_exit(monkeypatch):
    monkeypatch.setattr(packages, "run_command", lambda command: _completed(returncode=1))

    assert packages.kernel_release() is None


def test_module_version_from_modinfo(monkeypatch):
    monkeypatch.setattr(packages, "run_command", lambda command: _completed(stdout="2.15.6\n"))

    assert packages.module_version("lustre") == "2.15.6"


def test_module_version_none_on_failure(monkeypatch):
    monkeypatch.setattr(packages, "run_command", lambda command: _completed(returncode=1))

    assert packages.module_version("lustre") is None


def test_module_version_none_when_modinfo_missing(monkeypatch):
    monkeypatch.setattr(packages, "run_command", _raise_oserror)

    assert packages.module_version("lustre") is None
