# An explainable machine learning consensus framework for robust estimations of environmental effects on population dynamics
This repository contains scripts to implement explainable machine learning consensus framework - explanation discrepancy framework (EDF) for robust estimations of environmental effects on population dynamics.

## Citation Information
This code is provided as supplementary information to the paper,\
Anuradha Dhananjanie, Helen Thompson, Julie Vercelloni, David J Warne. An explainable machine learning consensus framework for robust estimations of environmental effects on population dynamics. https://doi.org/10.64898/2026.05.10.724190.

## Vesion information

## Contents
The directory structure is as follows.
```text
|-- R
    |-- synthetic_data_generation.R
    |-- synthos_figures.R
    |-- heatmaps_three_examples.R
    |-- pred_vs_obs_scatterplots.R                                 
|-- Python
    |-- RF.ipynb  
    |-- BRT.ipynb                    
    |-- MLP.ipynb                         
    |-- GAM.ipynb                 
    |-- EDM_SHAP.ipynb
    |-- EDM_LIME.ipynb
    |-- bootstrap_intervals.ipynb
    |-- time_series_obs_pred.ipynb
    |-- times_series_plot_observed_MHCC.ipynb
    |-- SHAP_discrepancy_vs_prediction_discrepancy.ipynb
    |-- projected_SHAP_discrepancy.ipynb
```
    
## Usage
<ol>
  <li>Run synthetic_data_generation.R. This generates the required simulated data for the analysis. The dataset "only_cyc.csv" generated from this code includes the raw disturbance values and the associated mean hard coral cover (MHCC). This data set can also be found in the data folder.</li>
  <li>synthos_figures.R produces plots for spatial domain, monitoring locations, and heat maps of row and weighted disturbances.</li>
  <li>heatmaps_three_examples.R produces the heatmaps corresponding to the three representative examples of EDM analysis implemented with SHAP (Figure 7). pred_vs_obs_scatterplots.R plots the predicted versus observed MHCC for within and out-of-sample data. </li>
  <li>Model construction, hyperparameter tuning, obtaining SHAP and LIME explanations are performed model-wise, and the python folder includes code (RF.ipynb, BRT.ipynb, MLP.ipynb, and GAM.ipynb) for those implementations. </li>
  <li>Once models are fitted and explanations are produced, the explanation discrepancy measure (EDM) is calculated using EDM_SHAP.ipynb and EDM_LIME.ipynb for SHAP and LIME, respectively.
  <li>bootstrap_intervals.ipynb calculates the bootstrap intervals for the the three representative examples ($E_1$, $E_2$, and $E_3$). </li>
</li>
</ol>
