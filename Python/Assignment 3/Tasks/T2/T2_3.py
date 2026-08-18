from T1 import *
import pandas as pd
import numpy as np
import pytest

@pytest.mark.parametrize(
    "arr,expected_min,expected_max",
    [
        ([5, 5, 5], 0.0, 0.0),
        ([1, 2, 3], 0.0, 1.0),
        ([0, 100], 0.0, 1.0),
    ]
)
def test_normalise(arr,expected_min,expected_max):
    result = normalize(arr)
    assert not np.isnan(result).any() 
    assert np.isclose(result.min(), expected_min)
    assert np.isclose(result.max(), expected_max)


@pytest.mark.parametrize(
    "amounts,mean_val,expected_flags",
    [
        ([10, 20, 30], 20, ["N", "N", "Y"]),
        ([10, 20, 30], 5, ["Y", "Y", "Y"]),
        ([10, 20, 30], 100, ["N", "N", "N"]),
        ([10, 20, 30], None, ["N", "N", "Y"]),
    ],
)
def test_high_value_parametrized(amounts, mean_val, expected_flags):
    result = high_value(amounts, mean_val)
    assert list(result) == expected_flags