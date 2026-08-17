import pandas as pd

def filter_data(path):
    df = pd.read_csv(path, parse_dates=["close_date"])
    print(df)
    print("\ncond 1")
    df = df[(df["status"] == "Closed")&(df["total_amount"] > 2000)]
    print(df)
    print("\ncond 2")
    res = df.sort_values(by="total_amount",ascending=False)
    df = res.reset_index(drop=True)
    print(df)
    print("\ncond 4")
    print(df.iloc[:5])
    print(df.iloc[-3:])

# import pandas as pd
 
 
# def filter_data(work_orders_path):
#     """Filter/sort work_orders and demonstrate .iloc[] slicing."""
#     work_orders = pd.read_csv(work_orders_path, parse_dates=["close_date"])
 
#     # Filter: Closed orders with total_amount > 2000
#     closed_high_value = work_orders[
#         (work_orders["status"] == "Closed") & (work_orders["total_amount"] > 2000)
#     ]
 
#     # Sort by total_amount descending, reset index
#     closed_high_value_sorted = closed_high_value.sort_values(
#         "total_amount", ascending=False
#     ).reset_index(drop=True)
 
#     print("\n=== Closed orders > $2000 (sorted desc by total_amount) ===")
#     print(closed_high_value_sorted)
 
#     # .iloc[] — first 5 rows and last 3 rows
#     print("\n=== .iloc[] — first 5 rows of work_orders ===")
#     print(work_orders.iloc[0:5])
 
#     print("\n=== .iloc[] — last 3 rows of work_orders ===")
#     print(work_orders.iloc[-3:])
 
#     return closed_high_value_sorted
 