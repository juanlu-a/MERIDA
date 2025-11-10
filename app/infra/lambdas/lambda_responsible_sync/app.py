import logging
import os
from typing import Any, Dict, Optional, Sequence, Set

import boto3
from boto3.dynamodb.types import TypeDeserializer
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

deserializer = TypeDeserializer()

sns_client = boto3.client("sns")

ALERTS_TOPIC_ARN = os.environ["ALERTS_TOPIC_ARN"]

# Attribute names we will consider when extracting responsible emails
RESPONSIBLE_ATTRIBUTES: Sequence[str] = (
    "responsibles",
    "Responsibles",
    "users",
    "Users",
    "emails",
    "Emails",
)


def lambda_handler(event: Dict[str, Any], _context: Any) -> Dict[str, Any]:
    """
    Synchrnise SNS toic subscriptions with the list of responsible emails saved in DynamoDB.

    Triggered by DynamoDB Streams on records where PK starts with BUSINESS# and SK with FACILITY#.
    """
    logger.info("Received %d stream records", len(event.get("Records", [])))

    for record in event.get("Records", []):
        event_name = record.get("eventName")
        dynamodb_record = record.get("dynamodb", {})

        pk = _get_key_value(dynamodb_record, "pk")
        sk = _get_key_value(dynamodb_record, "sk")

        if not pk or not sk:
            logger.debug("Record without pk/sk, skipping: %s", record)
            continue

        business_id = pk.split("#", maxsplit=1)[-1]
        facility_id = sk.split("#", maxsplit=1)[-1]

        new_emails = _extract_emails(dynamodb_record.get("NewImage"))
        old_emails = _extract_emails(dynamodb_record.get("OldImage"))

        logger.info(
            "Processing %s for business=%s facility=%s (new=%s old=%s)",
            event_name,
            business_id,
            facility_id,
            sorted(new_emails),
            sorted(old_emails),
        )

        _sync_subscriptions(new_emails, old_emails)

    return {"statusCode": 200}


def _sync_subscriptions(new_emails: Set[str], old_emails: Set[str]) -> None:
    """Create or delete SNS subscriptions to match the provided email sets."""
    to_add = new_emails - old_emails
    to_remove = old_emails - new_emails

    if to_add:
        logger.info("Adding subscriptions: %s", sorted(to_add))
        for email in to_add:
            try:
                sns_client.subscribe(
                    TopicArn=ALERTS_TOPIC_ARN, Protocol="email", Endpoint=email
                )
            except ClientError as error:  # pragma: no cover
                logger.error("Failed to subscribe %s: %s", email, error)

    if to_remove:
        logger.info("Removing subscriptions: %s", sorted(to_remove))
        existing = _list_topic_subscriptions()
        for email in to_remove:
            subscription_arn = existing.get(email.lower())
            if not subscription_arn:
                logger.debug("Subscription for %s not found; skipping removal", email)
                continue

            if subscription_arn.lower() == "pendingconfirmation":
                logger.info(
                    "Subscription for %s still pending confirmation; cannot remove", email
                )
                continue

            try:
                sns_client.unsubscribe(SubscriptionArn=subscription_arn)
            except ClientError as error:  # pragma: no cover
                logger.error("Failed to unsubscribe %s: %s", email, error)


def _list_topic_subscriptions() -> Dict[str, str]:
    """Return a map email -> subscription ARN for the SNS topic."""
    subscriptions: Dict[str, str] = {}
    next_token: Optional[str] = None

    while True:
        params: Dict[str, Any] = {"TopicArn": ALERTS_TOPIC_ARN}
        if next_token:
            params["NextToken"] = next_token

        response = sns_client.list_subscriptions_by_topic(**params)
        for subscription in response.get("Subscriptions", []):
            if subscription.get("Protocol") != "email":
                continue
            endpoint = (subscription.get("Endpoint") or "").lower()
            arn = subscription.get("SubscriptionArn", "")
            if endpoint:
                subscriptions[endpoint] = arn

        next_token = response.get("NextToken")
        if not next_token:
            break

    return subscriptions


def _extract_emails(image: Optional[Dict[str, Any]]) -> Set[str]:
    """Extract a set of emails from a DynamoDB Streams image."""
    if not image:
        return set()

    python_dict = _deserialize_image(image)
    for key in RESPONSIBLE_ATTRIBUTES:
        if key in python_dict:
            raw_value = python_dict[key]
            if isinstance(raw_value, str):
                return {
                    email.strip().lower()
                    for email in raw_value.split(",")
                    if email and email.strip()
                }
            if isinstance(raw_value, (list, tuple, set)):
                return {
                    str(email).strip().lower()
                    for email in raw_value
                    if isinstance(email, (str, bytes)) and str(email).strip()
                }

    return set()


def _deserialize_image(image: Dict[str, Any]) -> Dict[str, Any]:
    """Convert DynamoDB Streams attribute map to a native Python dict."""
    return {key: deserializer.deserialize(value) for key, value in image.items()}


def _get_key_value(dynamodb_record: Dict[str, Any], key_name: str) -> Optional[str]:
    """Fetch the primary key value (pk/sk) from a DynamoDB stream record."""
    keys = dynamodb_record.get("Keys")
    if not keys or key_name not in keys:
        return None
    value = deserializer.deserialize(keys[key_name])
    return str(value) if value is not None else None

