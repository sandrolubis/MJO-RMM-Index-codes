# MJO RMM Index Codes

**Author:** Sandro W. Lubis

This repository contains NCL and Python scripts for calculating the **Real-time Multivariate MJO (RMM) Index** from observational or model data.


# MJO RMM Index Codes

This repository contains NCL and Python scripts for calculating the **Real-time Multivariate MJO (RMM) Index** from observational or model data.

The workflow uses daily fields of:

* Outgoing Longwave Radiation (**OLR**)
* Zonal wind at 850 hPa (**U850**)
* Upper-tropospheric zonal wind (**U250** in the current model-processing scripts)

The processed anomalies can either be:

1. projected onto a prescribed observational EOF pattern to calculate model RMM indices, or
2. used to calculate EOFs directly for observations or an individual model.

The final output includes **RMM1 (PC1), RMM2 (PC2), MJO amplitude, and MJO phase (1–8)**.

## Repository Structure

```text
MJO-RMM-Index-codes/
│
├── projection/
│   ├── OBS_EOFs/
│   ├── Prepare_needed_vars_for_RMM.ncl
│   ├── get_anom_HighResMIP.ncl
│   ├── get_RMM_HighResMIP.ncl
│   └── read_PC1_PC2.py
│
├── cal_EOF/
│   └── get_EOF_HighResMIP.ncl
│
├── LICENSE
└── README.md
```

## Requirements

The workflow requires:

* [NCL](https://www.ncl.ucar.edu/)
* Python 3
* NumPy
* pandas
* SciPy
* matplotlib
* netCDF4

For example, the required Python packages can be installed with:

```bash
pip install numpy pandas scipy matplotlib netCDF4
```

## 1. RMM Index for Model Data Using Observed EOFs

This is the recommended workflow when the goal is to project model data onto the observational RMM EOF patterns.

### Step 1: Prepare the required variables

Go to the `projection` directory and create an `input` directory:

```bash
cd projection
mkdir -p input
```

Edit the input file paths, model name, pressure levels, time period, and output filenames in:

```text
Prepare_needed_vars_for_RMM.ncl
```

Then run:

```bash
ncl Prepare_needed_vars_for_RMM.ncl
```

This script prepares the required daily fields:

```text
OLR
U850
U250
```

and writes them into the `input/` directory.

The script also fills missing values when necessary.

---

### Step 2: Calculate anomalies

Create the anomaly directory:

```bash
mkdir -p anom
```

Edit the model name, experiment name, and analysis period in:

```text
get_anom_HighResMIP.ncl
```

Then run:

```bash
ncl get_anom_HighResMIP.ncl
```

This step calculates the anomalies used for the RMM analysis, including removal of the seasonal cycle represented by the first three harmonics.

The resulting files are written to:

```text
anom/
```

---

### Step 3: Project onto the observational EOFs

Create the output directory:

```bash
mkdir -p final_output
```

Make sure the observational EOF file is available under:

```text
projection/OBS_EOFs/
```

Then run:

```bash
ncl get_RMM_HighResMIP.ncl
```

The script projects the model OLR and zonal-wind anomalies onto the prescribed observational EOF patterns and calculates:

```text
PC1
PC2
MJO_INDEX
```

where

```text
MJO_INDEX = sqrt(PC1^2 + PC2^2)
```

The NetCDF output is written to:

```text
final_output/
```

---

### Step 4: Calculate MJO phases and create text output

Move to the output directory or modify the paths in `read_PC1_PC2.py` as appropriate.

Run:

```bash
python read_PC1_PC2.py
```

The script converts PC1 and PC2 into the conventional **eight MJO phases** and produces text files containing information such as:

```text
Year  Month  Day  RMM1  RMM2  Amplitude  Phase
```

An MJO event can subsequently be selected using an amplitude threshold such as:

```text
Amplitude >= 1
```

depending on the purpose of the analysis.

## 2. EOF Calculation for Observations or a Single Model

If you want to calculate the EOF patterns directly instead of projecting onto the supplied observational EOFs, first complete the preprocessing and anomaly calculations described above.

Then use:

```text
cal_EOF/get_EOF_HighResMIP.ncl
```

Run:

```bash
ncl get_EOF_HighResMIP.ncl
```

This script calculates the combined EOFs from the processed OLR, U850, and upper-level zonal-wind anomalies.

After calculating the EOFs, the resulting patterns can be used for the subsequent RMM calculation.

## Important Notes

The scripts were originally developed for specific model datasets and therefore contain several **hard-coded settings**, including:

* input paths
* model names
* experiment names
* analysis periods
* NetCDF variable names
* pressure-level indices
* output filenames

Please modify these settings according to your own dataset before running the scripts.

In particular, carefully check that the correct pressure levels corresponding to the lower- and upper-tropospheric zonal winds are selected.

## Citation

**Please cite the following paper if you use this code in your research:**

> Lubis, S. W., Hagos, S., Chang, C.-C., Balaguru, K., & Leung, L. R. (2023). Cross-equatorial surges boost MJO's southward detour over the Maritime Continent. *Geophysical Research Letters, 50*, e2023GL104770. https://doi.org/10.1029/2023GL104770

### BibTeX

```bibtex
@article{Lubis2023,
  author  = {Lubis, Sandro W. and Hagos, Samson and Chang, Chih-Chieh and Balaguru, Karthik and Leung, L. Ruby},
  title   = {Cross-Equatorial Surges Boost MJO's Southward Detour over the Maritime Continent},
  journal = {Geophysical Research Letters},
  volume  = {50},
  pages   = {e2023GL104770},
  year    = {2023},
  doi     = {10.1029/2023GL104770}
}
```

## License

This repository is distributed under the **MIT License**. See the `LICENSE` file for details.

## Contact

For questions about the code or its application, please open an issue in this repository.
