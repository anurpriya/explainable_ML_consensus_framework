import pandas as pd
import numpy as np

from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

def process_data():
    df = prepare_dataset()
    return split_and_scale_data(df)

def process_perturbed_data(random_seed):
    df = prepare_dataset()

    np.random.seed(random_seed)
    noise = np.random.normal(
    loc = 0,
    scale = 2.77,
    size = len(df)
    )

    df_perturbed = df.copy()
    df_perturbed["mean_hcc"] = df_perturbed["mean_hcc"] + noise

    return split_and_scale_data(df_perturbed)


def prepare_dataset():
    df = pd.read_csv("../data/only_cyc.csv")
    df = df[df["survey_depth"] == 10].copy() # Considered one of the depths, depth = 10m

    df = df.sort_values(['site_name', 'year']).reset_index(drop=True)

    # Lag within each site group
    df['cyc_lag1'] = df.groupby(['site_name'])['cyc_dis'].shift(1)
    df['dhw_lag1'] = df.groupby(['site_name'])['dhw_dis'].shift(1)
    df['other_lag1'] = df.groupby(['site_name'])['other_dis'].shift(1)

    df['cyc_lag2'] = df.groupby(['site_name'])['cyc_dis'].shift(2)
    df['dhw_lag2'] = df.groupby(['site_name'])['dhw_dis'].shift(2)
    df['other_lag2'] = df.groupby(['site_name'])['other_dis'].shift(2)
 
    return df

def split_and_scale_data(df):
    trainval = df[df['year'].between(1,29)].copy()
    test  = df[df['year']==30].copy()


    trainval = trainval.dropna(subset=['cyc_lag2']) # removed rows that don’t have a lag value (first and second year in each group)
  
    covariates = [
        'cyc_dis', 'dhw_dis', 'other_dis',
        'cyc_lag1', 'dhw_lag1', 'other_lag1',
        'cyc_lag2', 'dhw_lag2', 'other_lag2',
        'year', 'site_longitude', 'site_latitude'
    ]
    response = 'mean_hcc'

    # select a random subset (70%) of observations from year 3 to 29 for training, and use the remaining 30% and the first forecast year (year 30) for testing.
    train, val = train_test_split(
        trainval,
        test_size= 0.3,
        random_state=  1,
        shuffle= True
    )
    test  = pd.concat([val,test])

    X_train, y_train = train[covariates], train[response]
    X_test, y_test = test[covariates], test[response]

    print("Train shape:", X_train.shape, y_train.shape)
    print("Test shape: ", X_test.shape, y_test.shape)
    scaler = StandardScaler()

    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled  = scaler.transform(X_test)

    # data farames with same column names
    X_train_scaled = pd.DataFrame(X_train_scaled, columns=covariates, index=X_train.index)
    X_test_scaled  = pd.DataFrame(X_test_scaled, columns=covariates, index=X_test.index)

    return (train, test, y_train, y_test, X_train_scaled, X_test_scaled)

