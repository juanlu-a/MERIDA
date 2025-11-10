import logging
import os
from datetime import datetime
from decimal import Decimal
from typing import Any, Dict, List, Sequence, Tuple

import boto3
from boto3.dynamodb.types import TypeDeserializer
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

deserializer = TypeDeserializer()

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["DYNAMO_TABLE_NAME"])

sns_client = boto3.client("sns")

ALERTS_TOPIC_ARN = os.environ.get("ALERTS_TOPIC_ARN")

METRIC_TO_RANGE_FIELDS: Dict[str, Sequence[str]] = {
    "temperature": ("MinTemperature", "MaxTemperature"),
    "humidity": ("MinHumidity", "MaxHumidity"),
    "light": ("MinLight", "MaxLight"),
    "irrigation": ("MinIrrigation", "MaxIrrigation"),
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
    pk = item.get("pk")
    sk = item.get("sk")

    if not pk or not sk or not pk.startswith("PLOT#") or not sk.startswith("STATE#"):
        logger.debug("Item %s/%s is not a plot state event, skipping", pk, sk)
        return False

    plot_id = pk.split("#", maxsplit=1)[-1]
    timestamp = item.get("Timestamp") or sk.split("#", maxsplit=1)[-1]
    species_id = item.get("SpeciesId") or item.get("species_id")
    facility_id = item.get("FacilityId") or item.get("facility_id")
    business_id = item.get("BusinessId") or item.get("business_id")
    plot_name = item.get("PlotName") or item.get("plot_name")

    # Extract facility_id from GSI_PK if not present
    if not facility_id and isinstance(item.get("GSI_PK"), str) and item["GSI_PK"].startswith("FACILITY#"):
        facility_id = item["GSI_PK"].split("#", maxsplit=1)[-1]

    # Fetch plot-specific thresholds
    plot_thresholds = _fetch_plot_thresholds(plot_id)
    
    # If still no facility_id, try to get it from plot thresholds
    if not facility_id and plot_thresholds:
        facility_id = plot_thresholds.get("facility_id") or plot_thresholds.get("FacilityId")
        if facility_id:
            logger.info("Retrieved facility_id %s from plot thresholds", facility_id)
    
    # Last resort: fetch from plot metadata
    if not facility_id:
        logger.warning("facility_id not found in item, fetching from plot metadata")
        plot_metadata = _fetch_plot_metadata_by_id(plot_id)
        if plot_metadata:
            facility_id = plot_metadata.get("facility_id")
            if facility_id:
                logger.info("Retrieved facility_id %s from plot metadata", facility_id)
    
    if not plot_thresholds:
        logger.info("No thresholds configured for plot %s, skipping alert evaluation", plot_id)
        return True
    
    # Check if thresholds are enabled
    umbral_enabled = plot_thresholds.get("umbral_enabled", False)
    
    if not umbral_enabled:
        logger.info("Thresholds for plot %s are disabled (umbral_enabled=False), skipping alert evaluation", plot_id)
        return True
    
    logger.info("Plot %s has thresholds enabled, proceeding with alert evaluation", plot_id)
    
    # Extract species_id from thresholds (for logging/context)
    species_id = plot_thresholds.get("species_id") or species_id
    
    business_id = business_id or plot_thresholds.get("BusinessId") or plot_thresholds.get("business_id")

    deviations = _find_deviations(item, plot_thresholds)
    if not deviations:
        logger.info("Plot %s measurements at %s are within acceptable range", plot_id, timestamp)
        return True

    recipients = _fetch_responsible_emails(business_id, facility_id)
    if not recipients:
        logger.warning("No responsible emails found for facility %s (business=%s); skipping SNS notification", facility_id, business_id)
        return True

    # Fetch facility name for better email readability
    facility_name = _fetch_facility_name(facility_id)

    _publish_alert(
        plot_id=plot_id,
        plot_name=plot_name,
        species_id=species_id,
        facility_id=facility_id,
        facility_name=facility_name,
        timestamp=timestamp,
        deviations=deviations,
        recipients=recipients,
    )
    return True


def _fetch_plot_metadata(plot_id: Any, facility_id: Any) -> Dict[str, Any]:
    """
    Retrieve plot metadata to get species information.
    Tries to fetch from FACILITY#{facility_id} / PLOT#{plot_id}
    """
    if not facility_id:
        logger.warning("Cannot fetch plot metadata without facility_id")
        return {}
    
    try:
        response = table.get_item(
            Key={
                "pk": f"FACILITY#{facility_id}",
                "sk": f"PLOT#{plot_id}"
            }
        )
        item = response.get("Item")
        if item:
            logger.info("Successfully fetched plot metadata for plot %s", plot_id)
            return item
        else:
            logger.warning("Plot metadata not found for pk=FACILITY#%s, sk=PLOT#%s", facility_id, plot_id)
            return {}
    except ClientError as error:
        logger.error("Failed to fetch plot metadata: %s", error)
        return {}


def _fetch_plot_metadata_by_id(plot_id: Any) -> Dict[str, Any]:
    """
    Retrieve plot metadata using only plot_id by querying GSI_TypeIndex.
    Used as fallback when facility_id is not available.
    """
    if not plot_id:
        logger.warning("Cannot fetch plot metadata without plot_id")
        return {}
    
    try:
        # Query using GSI_TypeIndex with filter on plot_id
        response = table.query(
            IndexName='GSI_TypeIndex',
            KeyConditionExpression='#type = :type',
            FilterExpression='plot_id = :plot_id',
            ExpressionAttributeNames={'#type': 'type'},
            ExpressionAttributeValues={
                ':type': 'PLOT',
                ':plot_id': plot_id
            },
            Limit=1
        )
        
        items = response.get('Items', [])
        if items:
            logger.info("Found plot metadata via GSI for plot %s", plot_id)
            return items[0]
        
        logger.warning("Plot metadata not found for plot_id %s", plot_id)
        return {}
    
    except ClientError as error:
        logger.error("Failed to fetch plot metadata by id: %s", error)
        return {}


def _fetch_plot_thresholds(plot_id: Any) -> Dict[str, Any]:
    """
    Retrieve thresholds for a specific plot.
    Returns the plot's own thresholds (with umbral_enabled flag).
    """
    try:
        response = table.get_item(
            Key={
                "pk": f"PLOT#{plot_id}",
                "sk": "THRESHOLDS"
            }
        )
        
        item = response.get("Item")
        if item:
            logger.info("Found plot thresholds for plot %s", plot_id)
            return item
        else:
            logger.warning("No thresholds configured for plot %s", plot_id)
            return {}
    
    except ClientError as error:
        logger.error("Failed to fetch plot thresholds: %s", error)
        return {}


def _fetch_ideal_species_record(facility_id: Any, species_id: Any) -> Dict[str, Any]:
    """
    DEPRECATED: Use _fetch_plot_thresholds instead.
    Retrieve ideal parameters for the specified species.
    """
    facility_segment = f"FACILITY#{facility_id}" if facility_id else None

    candidates: List[Dict[str, Any]] = []
    keys_to_try: List[Tuple[str, str]] = []

    if facility_segment:
        keys_to_try.append((facility_segment, f"SPECIES#{species_id}"))
    keys_to_try.append((f"SPECIES#{species_id}", "PROFILE"))

    for pk, sk in keys_to_try:
        try:
            response = table.get_item(Key={"pk": pk, "sk": sk})
        except ClientError as error:  # pragma: no cover - log AWS errors
            logger.error("Failed to fetch ideal parameters: %s", error)
            continue

        item = response.get("Item")
        if item:
            logger.info("Found ideal parameters at pk=%s, sk=%s", pk, sk)
            candidates.append(item)

    if candidates:
        logger.info("Using ideal parameters for species %s", species_id)
        return candidates[0]
    else:
        logger.warning("No ideal parameters found for species %s", species_id)
        return {}


def _find_deviations(
    measurement: Dict[str, Any],
    ideal_ranges: Dict[str, Any],
) -> List[Dict[str, Any]]:
    """Compare measurement against configured ranges and return deviation details."""
    deviations: List[Dict[str, Any]] = []

    for metric, range_fields in METRIC_TO_RANGE_FIELDS.items():
        if metric not in measurement:
            continue

        lower_field, upper_field = range_fields
        lower_bound = _to_float(_first_present(ideal_ranges, (lower_field, lower_field.lower())))
        upper_bound = _to_float(_first_present(ideal_ranges, (upper_field, upper_field.lower())))
        actual_value = _to_float(measurement[metric])

        if actual_value is None:
            continue

        if lower_bound is not None and actual_value < lower_bound:
            deviations.append(
                {
                    "metric": metric,
                    "actual": actual_value,
                    "lower_bound": lower_bound,
                    "upper_bound": upper_bound,
                    "direction": "below",
                }
            )
            continue

        if upper_bound is not None and actual_value > upper_bound:
            deviations.append(
                {
                    "metric": metric,
                    "actual": actual_value,
                    "lower_bound": lower_bound,
                    "upper_bound": upper_bound,
                    "direction": "above",
                }
            )

    return deviations


def _fetch_facility_name(facility_id: Any) -> str:
    """Retrieve facility name from DynamoDB."""
    if not facility_id:
        return "Unknown Facility"

    key = {
        "pk": f"FACILITY#{facility_id}",
        "sk": "Metadata",
    }

    try:
        response = table.get_item(Key=key)
        facility = response.get("Item")
        if facility:
            return facility.get("name", f"Facility {facility_id[:8]}")
    except ClientError as error:
        logger.error("Failed to fetch facility name for %s: %s", facility_id, error)

    return f"Facility {facility_id[:8]}"


def _fetch_responsible_emails(business_id: Any, facility_id: Any) -> List[str]:
    """
    Retrieve responsible emails for a facility from DynamoDB.
    Backend structure: FACILITY#{facility_id} / RESPONSIBLES
    Field: "responsibles" (list of email strings)
    """
    if not facility_id:
        logger.warning("Missing facility_id for responsible lookup")
        return []

    key = {
        "pk": f"FACILITY#{facility_id}",
        "sk": "RESPONSIBLES",
    }

    try:
        response = table.get_item(Key=key)
    except ClientError as error:  # pragma: no cover - AWS errors logged
        logger.error("Failed to fetch responsibles for %s: %s", key, error)
        return []

    record = response.get("Item")
    if not record:
        logger.info("No responsible record found for facility %s", facility_id)
        return []

    # Backend stores responsibles as a list of emails
    raw_emails = record.get("responsibles", [])

    # Handle list format (standard)
    if isinstance(raw_emails, list):
        emails = [email for email in raw_emails if isinstance(email, str) and email.strip()]
        logger.info("Found %d responsible(s) for facility %s", len(emails), facility_id)
        return emails

    # Handle string format (backwards compatibility)
    if isinstance(raw_emails, str):
        emails = [email.strip() for email in raw_emails.split(",") if email.strip()]
        logger.info("Found %d responsible(s) for facility %s (parsed from CSV string)", len(emails), facility_id)
        return emails

    logger.warning("Responsibles field for facility %s is not a list or string: %s", facility_id, type(raw_emails))
    return []


def _publish_alert(
    plot_id: str,
    plot_name: Any,
    species_id: Any,
    facility_id: Any,
    facility_name: str,
    timestamp: Any,
    deviations: List[Dict[str, Any]],
    recipients: List[str],
) -> None:
    """Publish alert message to SNS topic."""
    if not ALERTS_TOPIC_ARN:
        logger.error("ALERTS_TOPIC_ARN environment variable is required to publish alerts")
        return

    # Use plot name if available, otherwise use short ID
    plot_display = plot_name if plot_name else f"Plot {plot_id[:8]}"
    subject = f"[MERIDA Alert] {plot_display} - Values Out of Range"

    # Map metric keys to display names with units
    metric_info = {
        "temperature": {"name": "Temperature", "unit": "°C"},
        "humidity": {"name": "Humidity", "unit": "%"},
        "light": {"name": "Light", "unit": "lux"},
        "soil_moisture": {"name": "Soil Moisture", "unit": "%"},
    }

    lines = [
        "ALERT: Environmental Values Out of Tolerance Range",
        "",
        f"Facility: {facility_name}",
        f"Plot: {plot_display}",
        f"Species: {species_id or 'Unknown'}",
        f"Timestamp: {timestamp or datetime.utcnow().isoformat()}",
        "",
        "Metrics Outside Tolerance:",
        "",
    ]

    for deviation in deviations:
        metric_key = deviation['metric']
        info = metric_info.get(metric_key, {"name": metric_key.capitalize(), "unit": ""})
        actual = deviation['actual']
        lower = deviation.get('lower_bound')
        upper = deviation.get('upper_bound')
        
        # Build range description
        if lower is not None and upper is not None:
            range_desc = f"{lower:.1f} - {upper:.1f}{info['unit']}"
        elif lower is not None:
            range_desc = f">= {lower:.1f}{info['unit']}"
        elif upper is not None:
            range_desc = f"<= {upper:.1f}{info['unit']}"
        else:
            range_desc = "undefined"
        
        # Calculate how much out of range
        deviation_desc = ""
        if upper is not None and actual > upper:
            diff = actual - upper
            deviation_desc = f" ({diff:.1f}{info['unit']} above maximum)"
        elif lower is not None and actual < lower:
            diff = lower - actual
            deviation_desc = f" ({diff:.1f}{info['unit']} below minimum)"
        
        lines.append(
            f"  - {info['name']}: {actual:.1f}{info['unit']}{deviation_desc}"
        )
        lines.append(f"    Allowed range: {range_desc}")
        lines.append("")

    lines.append("---")
    lines.append("This is an automated alert from the MERIDA monitoring system.")

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


def _first_present(source: Dict[str, Any], keys: Sequence[str]) -> Any:
    """Return the first non-null value for the provided key aliases."""
    for key in keys:
        if key in source and source[key] not in (None, ""):
            return source[key]
    return None

