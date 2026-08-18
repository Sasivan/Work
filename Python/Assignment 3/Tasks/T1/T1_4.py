import numpy as np

def high_value(amounts, mean_val=None):
    amounts = np.asarray(amounts, dtype=float)
    if mean_val is None:
        mean_val = np.mean(amounts)
    return np.where(amounts > mean_val, "Y", "N")
 

def normalize(df):
  # Convert input to numpy array if it is a list/Series
  arr = np.array(df, dtype=float)

  min_val = np.min(arr)
  max_val = np.max(arr)
  ptp = max_val - min_val

  # Return an array of 0.0s when all values are the same
  if ptp == 0:
    return np.zeros_like(arr, dtype=float)

  return (arr - min_val) / ptp

def norm(df):
    df = df["total_amount"].to_numpy()
    return ((df-np.min(df))/(np.max(df)-np.min(df)))
def numpy_stats(df):
    data = df
    df = df["total_amount"].to_numpy()
    print(df)

    print(f"mean : {np.mean(df)}\n \
            median : {np.median(df)}\n \
            std : {np.std(df):.2f}\n \
            max : {np.max(df)}\n \
            min : {np.min(df)}\n  \
                ")

    print("95% : ",np.percentile(df,95))

    mask = data["total_amount"]  > np.mean(df)+2*np.std(df)
    print("filtering : ",data.loc[mask,["order_id", "shop_name", "total_amount"]])
    nm = norm(data)
    print("norm : ",nm)
    data["norm"] = nm
    data["high_value"] = np.where(df>np.mean(df),'Y','N')

    print(df)
    return data

# import numpy as np


# def numpy_stats(wo_detail):
#     """Compute NumPy stats on total_amount, flag outliers, normalise, add high_value."""
#     amounts = wo_detail["total_amount"].to_numpy()

#     mean_val = np.mean(amounts)
#     median_val = np.median(amounts)
#     std_val = np.std(amounts)
#     min_val = np.min(amounts)
#     max_val = np.max(amounts)
#     p95 = np.percentile(amounts, 95)

#     print("\n=== Descriptive stats (NumPy) ===")
#     print(f"Mean:   {mean_val:.2f}")
#     print(f"Median: {median_val:.2f}")
#     print(f"Std:    {std_val:.2f}")
#     print(f"Min:    {min_val:.2f}")
#     print(f"Max:    {max_val:.2f}")
#     print(f"95th percentile: {p95:.2f}")

#     # Outlier mask: more than 2 std devs above the mean
#     outlier_mask = amounts > (mean_val + 2 * std_val)
#     print("\n=== Outlier mask (amount > mean + 2*std) ===")
#     print(outlier_mask)
#     print("Outlier orders:")
#     print(wo_detail.loc[outlier_mask, ["order_id", "shop_name", "total_amount"]])

#     # Min-max normalisation to 0-1 range
#     normalised = (amounts - min_val) / (max_val - min_val)
#     wo_detail["total_amount_normalised"] = normalised

#     # np.where() — high_value flag
#     wo_detail["high_value"] = np.where(amounts > mean_val, "Y", "N")
#     print("\n=== high_value flag ===")
#     print(wo_detail[["order_id", "total_amount", "total_amount_normalised", "high_value"]])

#     return wo_detail