import pandas as pd
import matplotlib.pyplot as plt
import lime
import lime.lime_tabular

from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score, root_mean_squared_error,mean_absolute_percentage_error
from lime.lime_tabular import LimeTabularExplainer 


def plot_prd_vs_obs(y_train, Predictions_train, y_test, Predictions_test):
    plt.figure(figsize=(10, 6))

    plt.subplot(1,2,1)
    plt.scatter(y_train, Predictions_train, alpha=0.6)
    plt.plot([y_train.min(), y_train.max()], [y_train.min(), y_train.max()], '--r', label='Ideal Fit')
    plt.gca().set_aspect('equal', adjustable='box')
    plt.title('Training')
    plt.xlabel('Observed MHCC (%)')
    plt.ylabel('Predicted MHCC (%)')
    plt.legend()
    plt.grid(True)

    plt.subplot(1,2,2)
    plt.scatter(y_test, Predictions_test, alpha=0.6)
    plt.plot([y_test.min(), y_test.max()], [y_test.min(), y_test.max()], '--r', label='Ideal Fit')
    plt.gca().set_aspect('equal', adjustable='box')
    plt.title('Test')
    plt.xlabel('Observed MHCC (%)')
    plt.ylabel('Predicted MHCC (%)')
    plt.legend()
    plt.grid(True)

    plt.tight_layout()
    # plt.show()



def calculate_performance_metrics (y_train, Predictions_train, y_test, Predictions_test):
    test_mae = round(mean_absolute_error(y_test, Predictions_test),3)
    test_mse = round(mean_squared_error(y_test, Predictions_test),3)
    test_rmse = round(root_mean_squared_error(y_test, Predictions_test),3)
    test_mape = round(mean_absolute_percentage_error(y_test, Predictions_test),3)
    test_r2_score = round(r2_score(y_test, Predictions_test),3)

    train_mae = round(mean_absolute_error(y_train, Predictions_train),3)
    train_mse = round(mean_squared_error(y_train, Predictions_train),3)
    train_rmse = round(root_mean_squared_error(y_train, Predictions_train),3)
    train_mape = round(mean_absolute_percentage_error(y_train, Predictions_train),3)
    train_r2_score = round(r2_score(y_train, Predictions_train),3)
        
    
    print(f"Training-> MAPE: {train_mape}, RMSE: {train_rmse}, MSE: {train_mse}, MAE: {train_mae}, R_2: {train_r2_score}")    
    print(f"Test -> MAPE: {test_mape}, RMSE: {test_rmse}, MSE: {test_mse}, MAE: {test_mae},  R_2: {test_r2_score}")

    return{
        "Train_MAPE": train_mape,
        "Train_RMSE": train_rmse,
        "Train_MSE": train_mse,
        "Train_MAE": train_mae,
        "Train_R2": train_r2_score,
        "Test_MAPE": test_mape,
        "Test_RMSE": test_rmse,
        "Test_MSE": test_mse,
        "Test_MAE": test_mae,
        "Test_R2": test_r2_score
    }

def get_feature_names(columns):
    rename_dict = {
        "cyc_dis": "cyc (t)",
        "dhw_dis": "dhw (t)",
        "other_dis": "other (t)",
        "cyc_lag1": "cyc (t-1)",
        "dhw_lag1": "dhw (t-1)",
        "other_lag1": "other (t-1)",
        "cyc_lag2": "cyc (t-2)",
        "dhw_lag2": "dhw (t-2)",
        "other_lag2": "other (t-2)",
        "year": "year",
        "site_longitude": "longitude",
        "site_latitude": "latitude"
    }

    feature_names = [rename_dict.get(col, col) for col in columns]
    print(feature_names)
    return feature_names


def get_lime_explanation(idx, training_data, feature_names, model):
    explainer = lime.lime_tabular.LimeTabularExplainer(
        training_data=training_data.to_numpy(),
        feature_names=feature_names,
        mode="regression",
        discretize_continuous=False,
        random_state=42
    )

    exp = explainer.explain_instance(
        training_data.iloc[idx].to_numpy(),
        model.predict,
        num_features=12
    )
    return exp






