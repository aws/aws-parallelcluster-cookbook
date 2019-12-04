"""
Validate and modify the data in the cloudwatch_log_files.json cookbook file.

This file is used to validate and add data to the JSON file that's used to
configure the CloudWatch agent on a cluster's EC2 instances. The structure of
the new and/or existing data is validated in the following ways:
* jsonschema is used to ensure that the input and output configs both possess
  a valid structure. See cloudwatch_log_files_schema.json for the schema.
* For each log_configs entry, it's verified that its timestamp_key is a valid
  key into the same config file's timestamp_formats object.
* It's verified that all log_configs entries have unique values for their
  log_stream_name and file_path attributes.
"""

import argparse
import collections
import json
import os
import shutil
import sys
import jsonschema


DEFAULT_SCHEMA_PATH = os.path.realpath(os.path.join(os.path.curdir, "cloudwatch_log_files_schema.json"))
SCHEMA_PATH = os.environ.get("CW_LOGS_CONFIGS_PATH", DEFAULT_SCHEMA_PATH)
DEFAULT_LOG_CONFIGS_PATH = os.path.realpath(os.path.join(os.path.curdir, "cloudwatch_log_files.json"))
LOG_CONFIGS_PATH = os.environ.get("CW_LOGS_CONFIGS_PATH", DEFAULT_LOG_CONFIGS_PATH)
LOG_CONFIGS_BAK_PATH = "{}.bak".format(LOG_CONFIGS_PATH)


def _fail(message):
    """Exit nonzero with the given error message."""
    sys.exit(message)


def parse_args():
    """Parse command line args."""
    parser = argparse.ArgumentParser(
        description="Validate of add new CloudWatch log configs.",
        epilog="If neither --input-json nor --input-file are used, this script will validate the existing config."
    )
    add_group = parser.add_mutually_exclusive_group()
    add_group.add_argument(
        "--input-file", type=argparse.FileType("r"), help="Path to file containing configs for log files to add."
    )
    add_group.add_argument(
        "--input-json", type=json.loads, help="String containing configs for log files to add."
    )
    return parser.parse_args()


def get_input_json(args):
    """Either load the input JSON data from a file, or returned the JSON parsed on the CLI."""
    if args.input_file:
        with args.input_file:
            return json.load(args.input_file)
    else:
        return args.input_json


def _read_json_at(path):
    """Read the JSON file at path."""
    try:
        with open(path) as input_file:
            return json.load(input_file)
    except FileNotFoundError:
        _fail("No file exists at {}".format(path))
    except ValueError:
        _fail("File at {} contains invalid JSON".format(path))


def _read_schema():
    """Read the schema for the CloudWatch log configs file."""
    return _read_json_at(SCHEMA_PATH)


def _read_log_configs():
    """Read the current version of the CloudWatch log configs file, cloudwatch_log_files.json."""
    return _read_json_at(LOG_CONFIGS_PATH)


def _validate_json_schema(input_json):
    """Ensure the structure of input_json matches the schema."""
    schema = _read_schema()
    try:
        jsonschema.validate(input_json, schema)
    except jsonschema.exceptions.ValidationError as validation_err:
        _fail(str(validation_err))


def _validate_timestamp_keys(input_json):
    """Ensure the timestamp_format_key values in input_json's log_configs entries are valid."""
    valid_keys = set()
    for config in (input_json, _read_log_configs()):
        valid_keys |= set(config.get("timestamp_formats").keys())
    for log_config in input_json.get("log_configs"):
        if log_config.get("timestamp_format_key") not in valid_keys:
            _fail(
                "Log config with log_stream_name {log_stream_name} and file_path {file_path} contains an invalid "
                "timestamp_format_key: {timestamp_format_key}. Valid values are {valid_keys}"
                .format(
                    log_stream_name=log_config.get("log_stream_name"),
                    file_path=log_config.get("file_path"),
                    timestamp_format_key=log_config.get("timestamp_format_key"),
                    valid_keys=", ".join(valid_keys)
                )
            )


def _get_duplicate_values(seq):
    """Get the duplicate values in seq."""
    counter = collections.Counter(seq)
    return [value for value, count in counter.items() if count > 1]


def _validate_log_config_fields_uniqueness(input_json):
    """Ensure that each entry in input_json's log_configs list has a unique log_stream_name and file_path."""
    unique_fields = ("log_stream_name", "file_path")
    for field in unique_fields:
        duplicates = _get_duplicate_values([config.get(field) for config in input_json.get("log_configs")])
        if duplicates:
            _fail(
                "The following {field} values are used multiple times: {duplicates}".format(
                    field=field, duplicates=", ".join(duplicates)
                )
            )


def validate_json(input_json=None):
    """Ensure the structure of input_json matches that of the file it will be added to."""
    if input_json is None:
        input_json = _read_log_configs()
    _validate_json_schema(input_json)
    _validate_timestamp_keys(input_json)
    _validate_log_config_fields_uniqueness(input_json)


def _write_log_configs(log_configs):
    """Write log_configs back to the CloudWatch log configs file."""
    log_configs_path = os.environ.get("CW_LOGS_CONFIGS_PATH", DEFAULT_LOG_CONFIGS_PATH)
    with open(log_configs_path, "w") as log_configs_file:
        json.dump(log_configs, log_configs_file, indent=2)


def write_validated_json(input_json):
    """Write validated JSON back to the CloudWatch log configs file."""
    log_configs = _read_log_configs()
    log_configs["log_configs"].extend(input_json.get("log_configs"))

    # NOTICE: the input JSON's timestamp_formats dict is the one that is
    # updated, so that those defined in the original config aren't clobbered.
    log_configs["timestamp_formats"] = input_json["timestamp_formats"].update(log_configs.get("timestamp_formats"))
    _write_log_configs(log_configs)


def create_backup():
    """Create a backup of the file at LOG_CONFIGS_PATH."""
    shutil.copyfile(LOG_CONFIGS_PATH, LOG_CONFIGS_BAK_PATH)


def restore_backup():
    """Replace the file at LOG_CONFIGS_PATH with the backup that was created in create_backup."""
    shutil.move(LOG_CONFIGS_BAK_PATH, LOG_CONFIGS_PATH)


def remove_backup():
    """Remove the backup created by create_backup."""
    try:
        os.remove(LOG_CONFIGS_BAK_PATH)
    except FileNotFoundError:
        pass


def main():
    """Run the script."""
    args = parse_args()
    create_backup()
    try:
        if args.input_file or args.input_json:
            input_json = get_input_json(args)
            validate_json(input_json)
            write_validated_json(input_json)
        validate_json()
    except Exception:
        restore_backup()
    finally:
        remove_backup()


if __name__ == "__main__":
    main()
