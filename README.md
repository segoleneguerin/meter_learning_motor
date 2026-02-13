# Meter Leaning Motor

## Table of contents
* [General info](#general-info)
* [Requirements](#requirements)
* [Project structure](#structure)


## General info
Scripts for the MeterLearning_Motor project.
This is a programmatic registered report that received in-principle acceptance by PCI-RR: [https://rr.peercommunityin.org/articles/rec?id=646](https://rr.peercommunityin.org/articles/rec?id=646).
The associated rawn and processed data can be found [here](https://zenodo.org/doi/10.5281/zenodo.10221480).

## Requirements

| Requirements  |      Version      |
|---------------|:-----------------:|
| Matlab   		|     >= R2020a		|
| [PsychoToolBox](https://github.com/Psychtoolbox-3) |         3		    |
| [CPP_BIDS](https://github.com/cpp-lln-lab/CPP_BIDS)		|       1.0.0		|
| [LetsWave](https://github.com/NOCIONS/letswave6)		|       6 & 7		|
| [rnb_tools](https://github.com/TomasLenc/rnb_tools)		|       1			|
| R   			|     >= 4.4.1		|
| R Studio   	|  >= 2024.09.0+375	|


## Project structure
```
.
├── 0_data
│   ├── grp-001
│   ├── grp-002
│   ├── meterlearning-motor_participant_allocation.xlsx
│   └── meterlearning-motor_questionnaires.xlsx
├── 1_code
│   ├── chan_labels.csv
│   ├── external_scr
│   │   ├── allcomb.m
│   │   ├── balLatSquare.m
│   │   ...
│   │   └── textprogressbar
│   ├── ica_gui_data.mat
│   ├── instr
│   │   ├── instr_afterTrial.txt
│   │   ├── instr_askMoreRep.txt
│   │   ...
│   │   └── instr_tappingTrial.txt
│   ├── lib
│   │   ├── CPP_BIDS
│   │   ├── letswave6-master
│   │   ├── ...
│   │   └── PTB
│   ├── matlab_plotting_functions
│   │   ├── meterlearning_motor_paper_figures_clap_spectra.m
│   │   ├── meterlearning_motor_paper_figures_clap_zscores_main_effect_cond.m
│   │   ├── ...
│   │   └── meterlearning_motor_topoplots.m
│   ├── matlab_processing_functions
│   │   ├── meterlearning_motor_add_to_check_files.m
│   │   ├── meterlearning_motor_asynch_vector_strength.m
│   │   ├── ...
│   │   └── meterlearning_motor_z_scores_eeg.m
│   ├── meterlearning_motor_create_stimuli.m
│   ├── meterlearning_motor_experiment.m
│   ├── ...
│   ├── participants_final_pool.xlsx
│   ├── r_functions
│   │   ├── calc_age.R
│   │   ├── guess_delim.R
│   │   ├── ...
│   │   └── plots.R
│   ├── record_smt.m
│   ├── sounds
│   │   ├── clave_high.wav
│   │   ├── clave_low.wav
│   │   ├── ...
│   │   └── kick.wav
│   └── stimuli
│       ├── carrier_for_calibration_bembe.wav
│    	├── stimuli_bembe.mat
│    	├── ...
│    	└── track-bembe_gridIOI-0.200s_eventType-tone.wav
└── 2_output
    ├── checks
    │   ├── bad_chans.xlsx
    │   ├── bad_ics.xlsx
    │   ├── bad_trials.xlsx
    │   └── step_axis.xlsx
	├── data
	└── plots
```
