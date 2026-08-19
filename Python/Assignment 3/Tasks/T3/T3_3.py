import requests
import pandas as pd
import logging,time
from T3_2 import get

logging.basicConfig(level=logging.INFO,
                             format="%(asctime)s [%(levelname)s] %(message)s",)
logger = logging.getLogger(__name__)

def fetch_all_posts(userID = 1,delay = 0.3):
    data = []
    for _ in range(1,6):
        try:
            dt = get(userID)
            data.extend(dt)
            logger.info("Fetched %d posts for user_id=%s",len(dt),userID)
        except (ValueError, ConnectionError) as e:
                logger.error("Failed to fetch posts for user_id=%s: %s", userID, e)
        finally:
            time.sleep(delay)
    return data
            
if __name__ == "__main__":
    data = fetch_all_posts()
    df = pd.DataFrame(data)
    res = df.groupby("userId").size().rename("Post counts")
    logger.info(res)
    # print(res)
    # counts = df.groupby("userId")["id"].count().rename("post_count")
    # print("\n=== Post count per user ===")
    # print(counts)
    
