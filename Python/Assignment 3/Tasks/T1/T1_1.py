import os
import pandas as pd


def inspect_df(df, name=''):
    print(f"\n{'=' * 50}")
    print(f"INSPECTING: {name}")
    print(f"{'=' * 50}")
    print(f"\nShape: {df.shape}")
    print(f"\nDtypes:\n{df.dtypes}")
    print(f"\nNull counts:\n{df.isnull().sum()}")


def inspect(path = r"C:\Work\Python\Assignment 3\Dataset\shops.csv", date_col = "open_date"):
    df = pd.read_csv(path, parse_dates=[date_col])
    name = os.path.basename(path)
    inspect_df(df, name)
    return df