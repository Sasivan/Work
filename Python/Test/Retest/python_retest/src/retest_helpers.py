"""Reference pure-Python helpers used by the optional pytest checks."""
import re
from abc import ABC, abstractmethod


def dedup_preserve_order(values):
    seen = set()
    result = []
    for value in values:
        if value not in seen:
            seen.add(value)
            result.append(value)
    return result


def dedup_clients(records):
    seen = set()
    result = []
    for record in records:
        key = record["email"].strip().casefold()
        if key not in seen:
            seen.add(key)
            result.append(record.copy())
    return result


class DeliveryChannel(ABC):
    @abstractmethod
    def channel_name(self):
        raise NotImplementedError


class EmailChannel(DeliveryChannel):
    def channel_name(self):
        return "email"


class QueueChannel(DeliveryChannel):
    def channel_name(self):
        return "queue"


def encode_route_code(value):
    shifts = [2, 4, 1]
    result = []
    for index, char in enumerate(value):
        if char < "a" or char > "z":
            raise ValueError("route code must contain lowercase a-z only")
        shifted = (ord(char) - ord("a") + shifts[index % len(shifts)]) % 26
        result.append(chr(ord("a") + shifted))
    return "".join(result)


def normalize_asset_tag(value):
    match = re.fullmatch(r"\s*([A-Za-z]{2})[\s./-]*(\d{4})\s*", str(value))
    if not match:
        return None
    return f"{match.group(1).upper()}-{match.group(2)}"


def clean_reference_code(value):
    if value is None:
        return None
    digits = re.sub(r"\D", "", str(value))
    return int(digits) if digits else None


def parse_positive_quantity(value):
    if isinstance(value, bool):
        raise ValueError("boolean is not a quantity")
    if isinstance(value, int):
        number = value
    elif isinstance(value, str) and value.strip().isdigit():
        number = int(value.strip())
    else:
        raise ValueError("quantity must be a whole integer")
    if number <= 0:
        raise ValueError("quantity must be positive")
    return number


def normalize_engagement(value):
    if value is None:
        return "OTHER"
    cleaned = str(value).strip().lower()
    if not cleaned:
        return "OTHER"
    if cleaned in {"permanent", "staff", "full time", "ft", "employee"}:
        return "CORE"
    if cleaned in {"contractor", "agency", "freelance", "vendor"}:
        return "FLEX"
    return "OTHER"
