def code():
    # Pseudo-code — trace the output 
    import pandas as pd, numpy as np 
    
    data = {'store': ['A','B','A','C','B','A'], 
            'sales': [100, 200, 150, 80, 220, 130]} 
    df = pd.DataFrame(data) 
    grp = df.groupby('store')['sales'].agg(['sum','mean','count']) 
    arr = np.array(df['sales']) 
    mask = arr > arr.mean() 
    df['above_avg'] = np.where(mask, 'Y', 'N') 
    
    result = df[df['store'] == 'A'].merge( 
        grp.reset_index(), on='store', how='left') 
    print(result[['store','sales','above_avg','sum']].to_string(index=False)) 
if __name__ == "__main__":
    code()
    

# Questions to answer as comments :
# ● Q1: What is arr.mean()? Show your working.
#   np.arr[...] will create sales array where mean or avg is  880/6 = 146.66

# ● Q2: Which rows in df have above_avg = 'Y'? 
#   which have above mean - index - 1,2,4

# ● Q3: How many rows does result have, and why? 
#   rows = 4 | all A will merge

# ● Q4: What is the value in the 'sum' column for every row in result? 
#   380    

# ● Q5: If you changed the merge to how='inner', would the row count change? Why or why not?
#   row count - 3 bcz A,B,C will remain with intersection