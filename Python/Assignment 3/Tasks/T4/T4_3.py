from T4_1 import *
import pandas as pd
import requests
import os

PATH = r"C:\Work\Python\Assignment 3\Dataset\T4"

def test_extract_returns_df():
    df = extract()
    assert isinstance(df,pd.DataFrame)
    assert not df.empty
    
def test_transform_no_nulls():
    df = transform()
    assert df["precipitation_sum"].isna().sum() == 0
    assert df["temp_f"].isna().sum() == 0
    assert df["weather_category"].isna().sum() == 0
    
def test_weather_category_values():
    df = transform()
    assert set(df["weather_category"]).issubset({"Hot","Warm","Cool"})

def test_gold_city_count():
    df = aggregate()
    assert len(df) == 3
    
def test_output_files_exist():
    assert os.path.exists(PATH+r"\bronze_weather_raw.csv")
    assert os.path.exists(PATH+r"\gold_weather_summary.csv")
    assert os.path.exists(PATH+r"\silver_weather_raw.csv")