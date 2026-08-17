import pandas as pd

def merge_and_groupby(p1,p2):
    df1 = pd.read_csv(p1,parse_dates=["open_date"])
    df2 = pd.read_csv(p2,parse_dates=["close_date"])

    wo_detail = pd.merge(df1,df2,on = "shop_id",how="inner")
    print(wo_detail.dtypes)
    print(wo_detail)  

    print("\ncond 1")

    c1 = wo_detail.groupby("shop_name")["total_amount"].sum()
    c2 = wo_detail.groupby("shop_name")["total_amount"].mean()

    print(c1,c2)

    c3 = wo_detail.groupby(["order_id","status","state"]).value_counts()

    print(c3)

    c4 = wo_detail.groupby(["total_amount","shop_name"]).max()

    print(c4)

    wo_detail["days_to_close"] = wo_detail["close_date"] - wo_detail["open_date"]

    print(wo_detail)

    print("1.3 - 3rd ques")

    cn = wo_detail.loc[wo_detail["state"] == 'TX']
    print(cn)

    return wo_detail

# import pandas as pd
 
 
# def merge_and_groupby(shop_path, work_orders_path):
#     """Merge shops + work_orders, run groupby aggregations, add days_to_close."""
#     shops = pd.read_csv(shop_path, parse_dates=["open_date"])
#     work_orders = pd.read_csv(work_orders_path, parse_dates=["close_date"])
 
#     # Inner join on shop_id
#     wo_detail = pd.merge(shops, work_orders, on="shop_id", how="inner")
 
#     # .loc[] — TX rows
#     tx_orders = wo_detail.loc[wo_detail["state"] == "TX"]
#     print("\n=== .loc[] — TX shop orders ===")
#     print(tx_orders)
 
#     # a) Total and mean total_amount per shop_name
#     per_shop_stats = wo_detail.groupby("shop_name")["total_amount"].agg(["sum", "mean"])
#     per_shop_stats.columns = ["total_amount_sum", "total_amount_mean"]
#     print("\n=== a) Total & mean total_amount per shop_name ===")
#     print(per_shop_stats)
 
#     # b) Count of orders per status per state (multi-level groupby)
#     status_by_state = wo_detail.groupby(["state", "status"])["order_id"].count()
#     status_by_state = status_by_state.rename("order_count")
#     print("\n=== b) Count of orders per status per state ===")
#     print(status_by_state)
 
#     # c) Highest single order per shop
#     highest_per_shop = wo_detail.groupby("shop_name")["total_amount"].max()
#     print("\n=== c) Highest single order per shop ===")
#     print(highest_per_shop)
 
#     # Derived column: days_to_close (NaT stays NaN for still-open orders)
#     wo_detail["days_to_close"] = (
#         wo_detail["close_date"] - wo_detail["open_date"]
#     ).dt.days
#     print("\n=== days_to_close ===")
#     print(
#         wo_detail[
#             ["order_id", "shop_name", "status", "open_date", "close_date", "days_to_close"]
#         ]
#     )
 
#     return wo_detail