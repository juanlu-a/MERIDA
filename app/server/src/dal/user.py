from __future__ import annotations

from decimal import Decimal
from typing import Any

from src.dal.dynamo import table
from src.schemas.user import UserRead
from src.utils.keys import pk_user


_PROFILE_SK = "PROFILE"


def _normalize_value(value: Any) -> Any:
    if isinstance(value, Decimal):
        return float(value)
    if isinstance(value, list):
        return [_normalize_value(item) for item in value]
    if isinstance(value, dict):
        return {key: _normalize_value(val) for key, val in value.items()}
    return value


def get_user_profile(user_id: str) -> UserRead | None:
    response = table.get_item(Key={"PK": pk_user(user_id), "SK": _PROFILE_SK})
    item = response.get("Item")
    if not item:
        return None

    data = _normalize_value(item)
    facilities = data.get("facilities", [])
    if not isinstance(facilities, list):
        facilities = [facilities]

    return UserRead(
        user_id=user_id,
        name=data.get("name", ""),
        email=data.get("email", ""),
        facilities=[str(facility) for facility in facilities if facility is not None],
    )
