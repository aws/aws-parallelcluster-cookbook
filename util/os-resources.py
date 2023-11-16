# !/usr/bin/python3
import os
import shutil

import click


@click.group()
def cli():
    """Utility script to list and generate cookbook resources files for a given OS.

    \b
    The script copies the `resources/<name>/<name>_{src_platform}{src_version}` cookbook resources
    into new created files: `named: resources/<name>/<name>_{dst_platform}{dst_version}`,
    replacing the platform and version patterns.

    This utility permits to automatically generate all the required files,
    then they must be checked one by one to see if there are OS specific checks on them.
    Templates and other specific files must be manually copied.

    \b
    Usage:
    python3 util/os-resources.py list-resources --cookbooks-path cookbooks --platform redhat --version 8
    python3 util/os-resources.py generate --src-platform redhat --src-version 8 --dst-platform rocky --dst-version 8 --cookbooks-path cookbooks
    """
    pass


@cli.command()
@click.option("--cookbooks-path", help="Directory containing the cookbooks.", required=True, type=click.Path())
@click.option(
    "--src-platform",
    help="Platform of the os to copy from (e.g. redhat)",
    type=click.Choice(["amazon", "centos", "redhat", "ubuntu"]),
    required=True,
)
@click.option(
    "--src-version",
    help="Version of the os to copy from (e.g. 8)",
    type=click.Choice(["2", "7", "8", "20", "22"]),
    required=True,
)
@click.option("--dst-platform", help="Platform of the os to copy to (e.g. rocky)", required=True)
@click.option("--dst-version", help="Version of the os to copy to (e.g. 8)", required=True)
def generate(cookbooks_path, src_platform, src_version, dst_platform, dst_version):
    src_os = f"{src_platform}{src_version}"

    resources = _get_resources_by_os(cookbooks_path, src_os)
    _generate_new_resources(resources, dst_platform, dst_version, src_platform, src_version)


def _generate_new_resources(resources, dst_platform, dst_version, src_platform, src_version):
    src_os = f"{src_platform}{src_version}"
    dst_os = f"{dst_platform}{dst_version}"

    for resource in resources:
        dirname = os.path.dirname(resource)

        src_filename = os.path.basename(resource)
        src_path = os.path.join(dirname, src_filename)

        dst_name = src_filename.replace(src_os, dst_os)
        dst_path = os.path.join(dirname, dst_name)
        _copy_and_replace(dst_path, dst_platform, dst_version, src_path, src_platform, src_version)


def _copy_and_replace(dst_path, dst_platform, dst_version, src_path, src_platform, src_version):
    print(f"Creating {dst_path}")
    shutil.copy(src_path, dst_path)

    with open(dst_path, "r") as file:
        filedata = file.read()
        # Replace platform in the dst file
        filedata = filedata.replace(f"platform: '{src_platform}'", f"platform: '{dst_platform}'")
        filedata = filedata.replace(f"platform?('{src_platform}')", f"platform?('{dst_platform}')")
        if f"{dst_platform}" not in filedata:
            print(f"ERROR: Unable to replace platform in file {dst_path}")

        # Replace platform in the dst file. There are 2 alternatives ways to find version
        filedata = filedata.replace(f"to_i == {src_version}", f"to_i == {dst_version}")
        filedata = filedata.replace(f"platform_version: '{src_version}'", f"platform_version: '{dst_version}'")

        if f"to_i == {dst_version}" not in filedata and f"platform_version: '{dst_version}'" not in filedata:
            # In some files the version is not specified
            print(f"WARNING: Unable to replace file version in file {dst_path}")

    with open(dst_path, "w") as file:
        file.write(filedata)


@cli.command()
@click.option("--cookbooks-path", help="Directory containing the cookbooks.", required=True, type=click.Path())
@click.option("--platform", help="Platform of the os to search for (e.g. redhat)", required=True)
@click.option("--version", help="Version of the os to search for (e.g. 8)", required=True)
def list_resources(cookbooks_path, platform, version):
    print("List OS Specific resources")
    os_to_search = f"{platform}{version}"
    resources = _get_resources_by_os(cookbooks_path, os_to_search)
    print(f"Found {len(resources)} resources for {os_to_search}")


def _get_resources_by_os(cookbooks_path, os_to_search):
    resources = []
    for root, dirs, files in os.walk(cookbooks_path, topdown=False):

        for name in files:
            if name.endswith(f"{os_to_search}.rb"):
                resources.append(os.path.join(root, name))
                print(name.replace(f"_{os_to_search}.rb", ""))

    return resources


if __name__ == "__main__":
    cli()
