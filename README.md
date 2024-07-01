*Follow these steps (for model projection):*

Step 1: Prepare Variables and Fill Missing Values
Create a directory named input.
Run the script Prepare_needed_vars_for_RMM.ncl to fill in missing values in the data.

Step 2: Calculate Anomalies
Create a directory named anom.
Run the script get_anom_HighResMIP.ncl to calculate anomalies by removing the first three harmonics.

Step 3: Calculate RMM Index
Create a directory named final_output.
Run the script get_RMM_HighResMIP.ncl to calculate the RMM index based on the observed EOF pattern from OBS.

Step 4: Run Python Code
Navigate to the directory final_output.
Run the Python script read_PC1_PC2.py.
