# Meter Leaning Motor

## Table of contents
* [General info](#general-info)
* [Requirements](#requirements)
* [Project structure](#structure)


## General info
Scripts for the MeterLearning_Motor project.
The Stage 1 manuscript and associated pilot data can be found [here](https://zenodo.org/doi/10.5281/zenodo.10221480).

Note that to run the `meterlearning_motor_create_stimuli.m` script, you need to add a .wav file (to build the tracker) in the `sounds` folder. 
You can request this .wav file to the owner of this repository.


## Requirements

| Requirements  |      Version      |
|---------------|:-----------------:|
| Matlab   		|     >= R2022a		|
| PsychoToolBox |         3		    |
| CPP_BIDS		|       1.0.0		|
| LetsWave		|       6 & 7		|


## Project structure
```
.
├── 0_data
├── 1_code
│   ├── external_scr
│   │   ├── allcomb.m
│   │   ├── balLatSquare.m
│   │   ...
│   │   └── textprogressbar
│   ├── instr
│   │   ├── instr_afterTrial.txt
│   │   ├── instr_askMoreRep.txt
│   │   ...
│   │   └── instr_tappingTrial.txt
│   ├── lib
│   │   ├── CPP_BIDS
│   │   ├── letswave6-master
│   │   ...
│   │   └── PTB
│   ├── matlab_processing_functions
│   │   ├── meterlearning_motor_add_to_check_files.m
│   │   ├── meterlearning_motor_clean_raw.m
│   │   ├── ...
│   │   └── meterlearning_motor_z_scores_eeg.m
│   ├── meterlearning_motor_create_stimuli.m
│   ├── meterlearning_motor_experiment.m
│   ├── ...
│   ├── meterlearning_motor_power_analysis.Rmd
│   ├── r_functions
│   │   ├── motor_delta_plot.R
│   │   ├── motor_parallel_plot.R
│   │   ...
│   │   └── plots
│   ├── sounds
│   └── stimuli
│       ├── carrier_for_calibration_bembe.wav
│    	├── stimuli_bembe.mat
│    	...
│    	└── track-bembe_gridIOI-0.200s_eventType-tone.wav
└── 2_output
    ├── checks
	├── data
	└── plots
```
