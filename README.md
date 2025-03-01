# EEG Brain Waves Analysis GUI

## Overview
The EEG Brain Waves Analysis GUI is a MATLAB-based graphical user interface for analyzing EEG (Electroencephalography) signals. This tool enables users to load EEG data from EDF files, visualize raw and filtered EEG signals, extract brain wave components, and compute the power spectral density (PSD).

## Features
- **Load EDF Files**: Supports loading EEG data from EDF format.
- **Channel Selection**: Allows users to select EEG channels for analysis.
- **Raw & Filtered Data Visualization**: Displays both raw and preprocessed EEG signals.
- **Brain Wave Decomposition**: Extracts Delta, Theta, Alpha, Beta, and Gamma frequency bands.
- **Power Spectral Density Analysis**: Computes and visualizes the power spectral density of brain wave components.

## Installation
1. Ensure MATLAB is installed on your system.
2. Download the script `AnalysisGUI.m`.
3. Install the **EEGLAB** toolbox if not already installed (required for EDF file processing):
   ```matlab
   addpath('path_to_eeglab_folder');
   eeglab;
   ```

## Usage
1. Run the GUI by executing:
   ```matlab
   AnalysisGUI
   ```
2. Click the **"Load EDF File"** button to select an EEG data file.
3. Choose a channel from the dropdown menu.
4. Adjust the time window slider to navigate through the data.
5. View raw, filtered EEG signals, brain wave decomposition, and PSD plots in respective tabs.

## Dependencies
- MATLAB
- EEGLAB Toolbox (for EDF file handling)

## Brain Wave Bands
| Band  | Frequency Range (Hz) |
|-------|------------------|
| Delta | 0.5 - 4        |
| Theta | 4 - 8         |
| Alpha | 8 - 13        |
| Beta  | 13 - 30       |
| Gamma | 30 - 50       |
