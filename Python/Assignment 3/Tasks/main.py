from T1 import *
from T2 import *
def task1():
    shop = r"Python\Assignment 3\Dataset\shops.csv"
    work_orders = r"Python\Assignment 3\Dataset\work_orders.csv"

    inspect(shop,"open_date")
    inspect(work_orders,"close_date")

    filter_data(work_orders)

    wo_detail = merge_and_groupby(shop, work_orders)

    numpy_stats(wo_detail)


if __name__=="__main__":
    task1()
 