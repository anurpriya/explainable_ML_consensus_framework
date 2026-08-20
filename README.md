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
|-- Python
    |-- RF.ipynb  
    |-- BRT.ipynb                    
    |-- MLP.ipynb                         
    |-- GAM.ipynb                 
    |-- EDM_SHAP.ipynb 
```
    
## Usage
<ol>
  <li>Run synthetic_data_generation.R. This generates the required simulated data for the analysis. The dataset "only_cyc.csv" generated from this code includes the raw disturbance values and the associated mean hard coral cover (MHCC). This data set can also be found in the data folder.</li>
  <li>synthos_figures.R produces plots for spatial domain, monitoring locations, and heat maps of row and weighted disturbances.</li>
  <li>Model construction, hyperparameter tuning, obtaining SHAP and LIME explanations are performed model-wise, and the python folder includes code for those implementations.</li>
  <li>Once models are fitted and explanations are produced, the explanation discrepancy measure (EDM) is calculated using EDM_SHAP.ipynb.
</li>
</ol>
