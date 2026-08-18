from T1 import *
import pandas as pd
import numpy as np
import pytest

@pytest.fixture
def sample_shops():
    p1 = r"C:\Work\Python\Assignment 3\Dataset\shops.csv"
    df = pd.read_csv(p1,parse_dates=["open_date"])
    return df[:3]

@pytest.fixture
def sample_orders():
    p2 =  r"C:\Work\Python\Assignment 3\Dataset\work_orders.csv"
    df = pd.read_csv(p2,parse_dates=["close_date"])
    return df[:5]

@pytest.fixture
def merged_df(sample_orders, sample_shops):
    df = pd.merge(sample_orders,sample_shops,on="shop_id",how="inner")
    df["days_to_close"] = (df["close_date"] - df["open_date"]).dt.days
    return df

def test_groupby_output(merged_df):
    grouped = merged_df.groupby("shop_name")["total_amount"].sum()
    assert not grouped.empty
    assert grouped["VIVE Collision Austin"] == 2750.25

def test_days_to_close_calculation(merged_df):
    
    open_order = merged_df[merged_df['order_id'] == 104].iloc[0]
    closed_order = merged_df[merged_df['order_id'] == 101].iloc[0]
    print(open_order,closed_order)
    assert pd.isna(open_order['days_to_close'])
    assert closed_order['days_to_close'] == 1416

def test_outlier_mask_computation(merged_df):
  amounts = merged_df['total_amount'].to_numpy()
  mean_val = np.mean(amounts)
  std_val = np.std(amounts)
  outlier_mask = amounts > (mean_val + 2 * std_val)

  assert isinstance(outlier_mask, np.ndarray)
  assert outlier_mask.dtype == bool