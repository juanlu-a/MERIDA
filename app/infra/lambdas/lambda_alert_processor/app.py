import logging
import os
from datetime import datetime
from decimal import Decimal
from typing import Any, Dict, List, Tuple

import boto3
from boto3.dynamodb.types import TypeDeserializer
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

deserializer = TypeDeserializer()

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["DYNAMO_TABLE_NAME"])

sns_client = boto3.client("sns")
cognito_client = boto3.client("cognito-idp")

USER_POOL_ID = os.environ.get("USER_POOL_ID")
ALERTS_TOPIC_ARN = os.environ.get("ALERTS_TOPIC_ARN")
TOLERANCE_PERCENT = float(os.environ.get("TOLERANCE_PERCENT", "0.1"))

METRIC_TO_IDEAL_FIELD = {
    "temperature": "IdealTemperature",
    "humidity": "IdealHumidity",
    "light": "IdealLight",
    "irrigation": "IdealIrrigation",
}


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    DynamoDB Streams handler that evaluates sensor readings against ideal values.
    Publishes SNS alerts to notify Cognito users when measurements are out of range.
    """
    records = event.get("Records", [])
    logger.info("Received %d DynamoDB stream records", len(records))

    processed = 0
    for record in records:
        if record.get("eventName") != "INSERT":
            continue

        new_image = record.get("dynamodb", {}).get("NewImage")
        if not new_image:
            logger.debug("Record without NewImage, skipping")
            continue

        try:
            item = _deserialize_item(new_image)
            if _process_plot_state(item):
                processed += 1
        except Exception as exc:  # pylint: disable=broad-except
            logger.exception("Failed to process record: %s", exc)

    return {"statusCode": 200, "processed_records": processed}


def _deserialize_item(image: Dict[str, Any]) -> Dict[str, Any]:
    """Convert DynamoDB Streams image into standard Python dict."""
    return {key: deserializer.deserialize(value) for key, value in image.items()}


def _process_plot_state(item: Dict[str, Any]) -> bool:
    """
    Process a single plot state record.
    Returns True if the record triggered an alert evaluation (normal or alert).
    """
    pk = item.get("PK")
    sk = item.get("SK")

    if not pk or not sk or not pk.startswith("PLOT#") or not sk.startswith("STATE#"):
        logger.debug("Item %s/%s is not a plot state event, skipping", pk, sk)
        return False

    plot_id = pk.split("#", maxsplit=1)[-1]
    timestamp = item.get("Timestamp") or sk.split("#", maxsplit=1)[-1]
    species_id = item.get("SpeciesId") or item.get("species_id")
    facility_id = item.get("FacilityId") or item.get("facility_id")

    if not species_id:
        logger.info("State %s missing SpeciesId, skipping alert evaluation", sk)
        return True

    if not facility_id and isinstance(item.get("GSI_PK"), str) and item["GSI_PK"].startswith("FACILITY#"):
        facility_id = item["GSI_PK"].split("#", maxsplit=1)[-1]

    ideal = _fetch_ideal_species_record(facility_id, species_id)
    if not ideal:
        logger.warning(
            "Ideal parameters not found for species %s (facility=%s)", species_id, facility_id
        )
        return True

    deviations = _find_deviations(item, ideal)
    if not deviations:
        logger.info("Plot %s measurements at %s are within acceptable range", plot_id, timestamp)
        return True

    recipients = _fetch_recipient_emails()
    if not recipients:
        logger.warning("No Cognito user emails found; skipping SNS notification")
        return True

    _publish_alert(
        plot_id=plot_id,
        species_id=species_id,
        facility_id=facility_id,
        timestamp=timestamp,
        deviations=deviations,
        recipients=recipients,
    )
    return True


def _fetch_ideal_species_record(facility_id: Any, species_id: Any) -> Dict[str, Any]:
    """Retrieve ideal parameters for the specified species."""
    facility_segment = f"FACILITY#{facility_id}" if facility_id else None

    candidates: List[Dict[str, Any]] = []
    keys_to_try: List[Tuple[str, str]] = []

    if facility_segment:
        keys_to_try.append((facility_segment, f"SPECIES#{species_id}"))
    keys_to_try.append((f"SPECIES#{species_id}", "PROFILE"))

    for pk, sk in keys_to_try:
        try:
            response = table.get_item(Key={"PK": pk, "SK": sk})
        except ClientError as error:  # pragma: no cover - log AWS errors
            logger.error("Failed to fetch ideal parameters: %s", error)
            continue

        item = response.get("Item")
        if item:
            candidates.append(item)

    return candidates[0] if candidates else {}


def _find_deviations(
    measurement: Dict[str, Any],
    ideal: Dict[str, Any],
) -> List[Dict[str, Any]]:
    """Compare measurement against ideal values and return deviation details."""
    deviations: List[Dict[str, Any]] = []

    for metric, ideal_field in METRIC_TO_IDEAL_FIELD.items():
        if metric not in measurement or ideal_field not in ideal:
            continue

        actual_value = _to_float(measurement[metric])
        ideal_value = _to_float(ideal[ideal_field])

        if ideal_value is None or actual_value is None:
            continue

        threshold = abs(ideal_value) * TOLERANCE_PERCENT
        lower_bound = ideal_value - threshold
        upper_bound = ideal_value + threshold

        if actual_value < lower_bound or actual_value > upper_bound:
            deviations.append(
                {
                    "metric": metric,
                    "actual": actual_value,
                    "ideal": ideal_value,
                    "lower_bound": lower_bound,
                    "upper_bound": upper_bound,
                }
            )

    return deviations


def _fetch_recipient_emails() -> List[str]:
    """Retrieve user emails from Cognito User Pool."""
    if not USER_POOL_ID:
        logger.error("USER_POOL_ID environment variable is required")
        return []

    emails: List[str] = []
    pagination_token = None

    while True:
        try:
            params: Dict[str, Any] = {"UserPoolId": USER_POOL_ID}
            if pagination_token:
                params["PaginationToken"] = pagination_token

            response = cognito_client.list_users(**params)
        except ClientError as error:  # pragma: no cover
            logger.error("Failed to list Cognito users: %s", error)
            break

        for user in response.get("Users", []):
            email = _extract_email(user)
            if email:
                emails.append(email)

        pagination_token = response.get("PaginationToken")
        if not pagination_token:
            break

    return emails


def _extract_email(user: Dict[str, Any]) -> str:
    """Extract email attribute from Cognito user description."""
    attributes = user.get("Attributes", [])
    for attribute in attributes:
        if attribute.get("Name") == "email":
            return attribute.get("Value")
    return ""


def _publish_alert(
    plot_id: str,
    species_id: Any,
    facility_id: Any,
    timestamp: Any,
    deviations: List[Dict[str, Any]],
    recipients: List[str],
) -> None:
    """Publish alert message to SNS topic."""
    if not ALERTS_TOPIC_ARN:
        logger.error("ALERTS_TOPIC_ARN environment variable is required to publish alerts")
        return

    subject = f"[SmartGrow] Plot {plot_id} out of range"

    lines = [
        f"Plot ID: {plot_id}",
        f"Species: {species_id}",
        f"Facility: {facility_id or 'Unknown'}",
        f"Timestamp: {timestamp or datetime.utcnow().isoformat()}",
        "",
        "Metrics outside tolerance:",
    ]

    for deviation in deviations:
        lines.append(
            (
                f"- {deviation['metric'].capitalize()}: actual={deviation['actual']:.2f}, "
                f"ideal={deviation['ideal']:.2f} "
                f"(allowed {deviation['lower_bound']:.2f} - {deviation['upper_bound']:.2f})"
            )
        )

    lines.extend(
        [
            "",
            "Recipients:",
            ", ".join(recipients),
        ]
    )

    message = "\n".join(lines)

    try:
        sns_client.publish(
            TopicArn=ALERTS_TOPIC_ARN,
            Subject=subject,
            Message=message,
        )
        logger.info("Alert published for plot %s", plot_id)
    except ClientError as error:  # pragma: no cover
        logger.error("Failed to publish alert: %s", error)


def _to_float(value: Any) -> float:
    """Convert DynamoDB numeric types to float for calculations."""
    if value is None:
        return None

    if isinstance(value, Decimal):
        return float(value)

    if isinstance(value, (int, float)):
        return float(value)

    try:
        return float(value)
    except (TypeError, ValueError):
        logger.debug("Unable to convert value %s (%s) to float", value, type(value))
        return None

