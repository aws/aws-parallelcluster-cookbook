import argparse
import json
import sys
from datetime import datetime, timezone

import boto3
from boto3.dynamodb.conditions import Attr

DB_KEY = "COMPUTE_FLEET"
DB_DATA = "Data"

COMPUTE_FLEET_STATUS_ATTRIBUTE = "status"
COMPUTE_FLEET_LAST_UPDATED_TIME_ATTRIBUTE = "lastStatusUpdatedTime"


def update_item(table, status, current_status):
    table.update_item(
        Key={"Id": DB_KEY},
        UpdateExpression="set #dt.#st=:s, #dt.#lut=:t",
        ExpressionAttributeNames={
            "#dt": DB_DATA,
            "#st": COMPUTE_FLEET_STATUS_ATTRIBUTE,
            "#lut": COMPUTE_FLEET_LAST_UPDATED_TIME_ATTRIBUTE,
        },
        ExpressionAttributeValues={
            ":s": str(status),
            ":t": str(datetime.now(tz=timezone.utc)),
        },
        ConditionExpression=Attr(f"{DB_DATA}.{COMPUTE_FLEET_STATUS_ATTRIBUTE}").eq(str(current_status)),
    )


def update_status_with_last_updated_time(table_name, region, status):
    """Get compute fleet status and the last compute fleet status updated time."""
    try:
        table = boto3.resource("dynamodb", region_name=region).Table(table_name)
        current_status = get_dynamo_db_data(table).get(COMPUTE_FLEET_STATUS_ATTRIBUTE)
        if current_status == status:
            return
        elif current_status == "RUNNING":
            update_item(table, status, current_status)
        else:
            raise Exception(f"Could not update compute fleet status from '{current_status}' to {status}.")
    except Exception as e:
        raise Exception(f"Failed when updating fleet status with error: {e}")


def get_dynamo_db_data(table):
    try:
        compute_fleet_item = table.get_item(ConsistentRead=True, Key={"Id": DB_KEY})
        if not compute_fleet_item or "Item" not in compute_fleet_item:
            raise Exception("COMPUTE_FLEET data not found in db table")
        db_data = compute_fleet_item["Item"].get(DB_DATA)
        return db_data

    except Exception as e:
        raise Exception(f"Failed when retrieving data from DynamoDB with error {e}.")


def get_status_with_last_updated_time(table_name, region):
    """Get compute fleet status and the last compute fleet status updated time."""
    try:
        table = boto3.resource("dynamodb", region_name=region).Table(table_name)
        dynamo_db_data = get_dynamo_db_data(table)
        print(
            json.dumps(
                {
                    COMPUTE_FLEET_STATUS_ATTRIBUTE: dynamo_db_data.get(COMPUTE_FLEET_STATUS_ATTRIBUTE),
                    COMPUTE_FLEET_LAST_UPDATED_TIME_ATTRIBUTE: dynamo_db_data.get(
                        COMPUTE_FLEET_LAST_UPDATED_TIME_ATTRIBUTE
                    ),
                },
                sort_keys=True,
                indent=4,
            )
        )

    except Exception as e:
        raise Exception(f"Failed when retrieving fleet status from DynamoDB with error {e}.")


def main():
    try:
        parser = argparse.ArgumentParser(description="Get or update compute fleet status of scheduler plugin.")
        parser.add_argument(
            "--table-name",
            type=str,
            required=True,
            help="DynamoDB table name",
        )
        parser.add_argument(
            "--region",
            type=str,
            required=True,
            help="Region of cluster",
        )
        parser.add_argument(
            "--status",
            type=str,
            required=False,
            help="Specify the compute fleet status to set, can be PROTECTED",
            choices={"PROTECTED"},
        )
        parser.add_argument(
            "--action",
            type=str,
            required=True,
            help="Get or update compute-fleet-status",
            choices={"update", "get"},
        )

        args = parser.parse_args()
        if args.action == "update" and not args.status:
            parser.error("ERROR: --status is required when 'action' is specified to 'update'.")
        elif args.action == "get" and args.status:
            parser.error("ERROR: --status can not be specified when 'action' is 'get'.")

        if args.action == "update":
            update_status_with_last_updated_time(args.table_name, args.region, args.status)
        else:
            get_status_with_last_updated_time(args.table_name, args.region)
    except Exception as e:
        print(f"ERROR: Failed to {args.action} compute fleet status, exception: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
