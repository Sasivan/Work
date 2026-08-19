import pandas as pd
import requests
import os

def weather():
    url = "https://api.open-meteo.com/v1/forecast"
    params = {
    "latitude": 30.2672,
    "longitude": -97.7431,
    "timezone": "America/Chicago",
    "forecast_days": 7,
    "daily": [
        "temperature_2m_max",
        "precipitation_sum"
    ]
}
    response = requests.get(url,params=params)
    # print(response.status_code)
    data = pd.DataFrame(response.json()["daily"])
    data["time"] = pd.to_datetime(data["time"])
    # print(data.dtypes)

    data = data.rename(columns={
        "time":"date",
         "temperature_2m_max":"max_temp_c",
         "precipitation_sum":"precipitation_mm"
    })
    # print(data.dtypes)

    data["temp_f"] = round(data["max_temp_c"] * 9/5 + 32,1)
    # print(data.dtypes)

    ht = data.loc[data["max_temp_c"].idxmax()]
    mr = data.loc[data["precipitation_mm"].idxmax()]
    # print(ht,'\n',mr)
    ht_mr = data[
    (data["max_temp_c"] == data["max_temp_c"].max()) &
    (data["precipitation_mm"] == data["precipitation_mm"].max())]
    # print(ht_mr)

    data = data.rename_axis("index")
    data.to_csv(r"Python\Assignment 3\Dataset\weather_austin.csv")

    # print(os.path.exists(r"Python\Assignment 3\Dataset\weather_austin.csv"))

    return data

if __name__ == "__main__":
    weather()