import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

import pytest
from retest_helpers import (
    DeliveryChannel, EmailChannel, QueueChannel,
    clean_reference_code, dedup_clients, encode_route_code,
    normalize_asset_tag, normalize_engagement, parse_positive_quantity,
)


def test_dedup_preserves_first_seen_order_and_normalizes_email():
    records = [
        {"client_id": 1, "email": "Alice@example.com"},
        {"client_id": 2, "email": "bob@example.com"},
        {"client_id": 3, "email": " alice@example.com "},
    ]
    result = dedup_clients(records)
    assert [row["client_id"] for row in result] == [1, 2]


def test_dedup_does_not_modify_input():
    records = [{"client_id": 1, "email": "A@example.com"}, {"client_id": 2, "email": "a@example.com"}]
    dedup_clients(records)
    assert len(records) == 2


def test_abstract_channel_classes():
    with pytest.raises(TypeError):
        DeliveryChannel()
    assert EmailChannel().channel_name() == "email"
    assert QueueChannel().channel_name() == "queue"


def test_route_code_shift():
    assert encode_route_code("abc") == "cfd"


def test_route_code_wraps():
    assert encode_route_code("xyz") == "zca"


def test_route_code_rejects_uppercase():
    with pytest.raises(ValueError):
        encode_route_code("A1")


def test_asset_tag_normalization():
    assert normalize_asset_tag(" lt 0047 ") == "LT-0047"
    assert normalize_asset_tag("pr.1020") == "PR-1020"


def test_asset_tag_invalid():
    assert normalize_asset_tag("ABC-10") is None


def test_reference_code_digits():
    assert clean_reference_code("WR-00981") == 981


def test_reference_code_without_digits():
    assert clean_reference_code("n/a") is None


def test_positive_quantity_accepts_int_and_string():
    assert parse_positive_quantity(3) == 3
    assert parse_positive_quantity(" 4 ") == 4


def test_positive_quantity_rejects_invalid_values():
    for value in [True, 0, -2, "2.5", "bad", None]:
        with pytest.raises(ValueError):
            parse_positive_quantity(value)


def test_engagement_exact_mapping_and_catch_all():
    assert normalize_engagement(" STAFF ") == "CORE"
    assert normalize_engagement("agency") == "FLEX"
    assert normalize_engagement("staff;vendor") == "OTHER"
    assert normalize_engagement(None) == "OTHER"
