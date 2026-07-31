# An explainable machine learning consensus framework for robust estimations of environmental effects on population dynamics
This repository contains scripts to implement explainable machine learning consensus framework - explanation discrepancy framework (EDF) for robust estimations of environmental effects on population dynamics.

## Developers
Anuradha Dhananjanie$^{1, 2}$ anuradha.dewage@hdr.qut.edu.au

1. School of Mathematical Sciences, Faculty of Science, Queensland Univeristy of Technology, Australia
2. Centre for Data Science, Queensland University of Technology, Australia

## Citation Information
This code is provided as supplementary information to the paper,\
Anuradha Dhananjanie, Helen Thompson, Julie Vercelloni, David J Warne. An explainable machine learning consensus framework for robust estimations of environmental effects on population dynamics. https://doi.org/10.64898/2026.05.10.724190.

## Contents

    
## Usage
1. Start R and browse to the repository folder explainable_ML_consensus_framework/R
3. Run synthetic_data_generation.R. This generates the required simulated data for the analysis. The dataset "only_cyc.csv" generated from this code contains the row disturbance values and the associated mean hard coral cover. This data set can also be found in the data folder
4. synthos_figures.R produces plots  Spatial domain, Monitoring locations, Heat maps of row and weighted disturbances.
5. Model construction, hyperparameter tuning, obtaining SHAP and LIME explanations are performed model-wise and python folder includes code for those implementations. 
