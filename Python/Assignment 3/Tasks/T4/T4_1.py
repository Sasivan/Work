import pandas as pd
import numpy as np
import requests
import logging

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)

logger = logging.getLogger(__name__)


CITIES = {
    "Austin": {"latitude": 30.2672, "longitude": -97.7431},
    "Chicago": {"latitude": 41.8781, "longitude": -87.6298},
    "Miami": {"latitude": 25.7617, "longitude": -80.1918},
}

BASE_URL = "https://api.open-meteo.com/v1/forecast"
TIMEZONE = "America/Chicago"
FORECAST_DAYS = 7
PATH = r"C:\Work\Python\Assignment 3\Dataset\T4"

def fetch(name,lat,long):
    params = {
        "latitude": lat,
        "longitude": long,
        "daily": "temperature_2m_max,precipitation_sum",
        "timezone": TIMEZONE,
        "forecast_days": FORECAST_DAYS,
    }
    response = requests.get(BASE_URL,params=params)
    data = response.json()
    daily = data["daily"]
    
    df = pd.DataFrame(
        {
            "date": daily["time"],
            "max_temp_c": daily["temperature_2m_max"],
            "precipitation_sum": daily["precipitation_sum"],
        }
    )
    df["city"] = name
    df = df.rename_axis("index")
    return df

def extract():

    frames = []
    for k,v in CITIES.items():
        df = fetch(k,v["latitude"],v["longitude"])
        # logger.info(df)
        frames.append(df)
    raw_df = pd.concat(frames,ignore_index=True)
    raw_df.to_csv(PATH+r"\bronze_weather_raw.csv")
    logger.info("EXTRACT complete — %d rows loaded", len(raw_df))
    return raw_df
    
def category(temp_f):
    if temp_f>90: return "Hot"
    elif 90<= temp_f <= 70: return "Warm"
    else: return "Cool"    

def transform():
    df = pd.read_csv(PATH+r"\bronze_weather_raw.csv")
    clean_df = df.dropna(subset=["precipitation_sum"])
    clean_df["temp_f"] = clean_df["max_temp_c"] * 9 / 5 + 32
    clean_df["weather_category"] = clean_df["temp_f"].apply(category)
    logger.info("EXTRACT complete — %d rows loaded", len(clean_df))
    clean_df.to_csv(PATH+r"\silver_weather_raw.csv")
    return clean_df
    
def aggregate():
    df = pd.read_csv(PATH+r"\silver_weather_raw.csv")
    # def common(d): return d.mode().iloc[0]
    summary = (
        df.groupby("city").agg(
            mean_temp_f = ("temp_f","mean"),
            total_precipitation_mm = ("precipitation_sum","sum"),
            most_common_category = ("weather_category",lambda x:x.mode().iloc[0])
        ).reset_index()
    )
    # logger.info(summary)
    summary.to_csv(PATH+r"\gold_weather_summary.csv")
    logger.info("EXTRACT complete — %d rows loaded", len(summary))
    print(summary.to_string())
    return summary
if __name__ == "__main__":
    extract()
    transform()
    aggregate()