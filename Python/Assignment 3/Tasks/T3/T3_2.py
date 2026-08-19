import requests
import pandas as pd

def get(userId):
    try:
        url = "https://jsonplaceholder.typicode.com/posts"

        params = {
                "userId": userId
                }
        headers = {"Accept": "application/json"}

        
        response = requests.get(url,
                                params=params,
                                headers=headers)
        if response.status_code != 200:
                    raise ValueError(f"API returned status {response.status_code}")
        data = response.json()
        # print(data[:1])
        return data

        # print(type(response.json()))
        # print(type(response.json()[0]))
        # df.to_csv(r"Python\Assignment 3\Dataset\x.csv")    
    except requests.exceptions.RequestException as e:
        raise ConnectionError("Conn error")

def post():
    data = {
        "userId": 1,
        "title": "Sasivan",
        "body": "Great post!"
        }
    try:
        url = "https://jsonplaceholder.typicode.com/posts"
        headers = {"Content-type": "application/json"}

        
        response = requests.post(url,
                                json=data,
                                headers=headers)
        if response.status_code != 201:
                    raise ValueError(f"API returned status {response.status_code}")
                
        data = response.json()
        return data
        # print(type(response.json()))
        # print(type(response.json()[0]))
        # df.to_csv(r"Python\Assignment 3\Dataset\x.csv")    
    except requests.exceptions.RequestException as e:
        raise ConnectionError("Conn error")

if __name__ == "__main__":
    try:
        post()
        get(1)
    except Exception as e:
        print(e)