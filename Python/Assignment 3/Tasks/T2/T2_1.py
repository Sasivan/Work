from T1 import *
import pandas as pd
import numpy as np
import pytest

def test_high_value_column(p1 = r"C:\Work\Python\Assignment 3\Dataset\shops.csv"
                     ,p2 =  r"C:\Work\Python\Assignment 3\Dataset\work_orders.csv"):

    df3 = merge_and_groupby(p1,p2)
    mean_val = np.mean(df3["total_amount"])
    df3["high_value"] = np.where(df3["total_amount"] > mean_val, "Y", "N")

    assert set(df3["high_value"].unique()).issubset({"Y", "N"})
def test_normalise_range(p1 = r"C:\Work\Python\Assignment 3\Dataset\shops.csv"
                     ,p2 =  r"C:\Work\Python\Assignment 3\Dataset\work_orders.csv"):

    df3 = merge_and_groupby(p1,p2)
    df = norm(df3)

    assert df.min() == pytest.approx(0.0)
    assert df.max() == pytest.approx(1.0)

    assert np.isclose(df.min(),0.0)
    assert np.isclose(df.max(),1.0)
    print("Success")


def test_merge_shape(p1 = r"C:\Work\Python\Assignment 3\Dataset\shops.csv"
                     ,p2 =  r"C:\Work\Python\Assignment 3\Dataset\work_orders.csv"):
    df1 = pd.read_csv(p1)
    df2 = pd.read_csv(p2)

    df3 = merge_and_groupby(p1,p2)

    assert df3.shape[1] > df1.shape[1]
    assert df3.shape[1] > df2.shape[1]
    print("Success")

def test_inspect_df_runs():

    df = pd.DataFrame({
        "order_id": [1, 2, 3],
        "status": ["Open", "Closed", "Open"],
        "total_amount": [100, 200, 300]
    })
    inspect_df(df)