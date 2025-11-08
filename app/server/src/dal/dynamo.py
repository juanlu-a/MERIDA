import os
from functools import lru_cache
from dotenv import load_dotenv
load_dotenv()

import boto3


@lru_cache(maxsize=1)
def _get_resource():
    region = os.getenv("AWS_REGION")
    if region:
        return boto3.resource("dynamodb", region_name=region)
    return boto3.resource("dynamodb")


@lru_cache(maxsize=1)
def _get_table_name() -> str:
    table_name = os.getenv("DYNAMO_TABLE_NAME")
    if not table_name:
        raise RuntimeError(f"Environment variable DYNAMO_TABLE_NAME must be set")
    return table_name


@lru_cache(maxsize=1)
def get_table():
    return _get_resource().Table(_get_table_name())


table = get_table()
