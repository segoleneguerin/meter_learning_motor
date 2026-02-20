% Ségolène M. R. Guérin
% Created: April 16, 2023

%% ---- PREAMBLE
% Clear workspace and commmand window
clear
clc

% Empty lib paths
restoredefaultpath;

% Load project lib paths
addpath(genpath('lib'))
addpath(genpath('scr'))
addpath(genpath('external_scr'))
addpath(genpath('matlab_processing_functions'))
addpath(genpath('matlab_plotting_functions'))

% Get parameters file
params = meterlearning_motor_get_params();

% Load LetsWave 6
import_lw(6)

%% ---- SET PARAMETERS

% analysis parameters
data_type = 2; 
ref_method = "mastoids";
average_method = "cluster";

% plotting parameters
analysis_type    = 1;
normalization    = true;
disp_stim_zscore = false;

%% ---- RUN PROCESSING AND ANALYSIS SCRIPTS

% % ---- Data preparation
for participant = params.all_part
   
    meterlearning_motor_source_to_raw(participant);
    
    meterlearning_motor_clean_raw(participant);
    
end

% ---- Clapping data
% Note: SMT file for sub-011 is missing
for participant = params.all_part

    meterlearning_motor_compute_smt(participant);
    
    meterlearning_motor_process_clap_learning(participant);

    meterlearning_motor_process_clap_continuation(participant)
    
    meterlearning_motor_process_clap(participant);

    meterlearning_motor_z_scores_clap(participant, 1);  
    
end

% ---- Stepping data
for participant = params.all_part
    

    meterlearning_motor_process_step(participant);

end


% ---- EEG data
for participant = params.all_part

    meterlearning_motor_eeg_filter(participant);

    meterlearning_motor_add_to_check_files(participant);
    
end

meterlearning_motor_visual_inspection(participant);

for participant = params.all_part
    
    meterlearning_motor_interpolate_bads(participant);

    meterlearning_motor_reject_epochs(participant);

    meterlearning_motor_run_ica(participant);

end

meterlearning_motor_IC_inspection(participant)

for participant = params.all_part

    meterlearning_motor_remove_ics(participant);

    meterlearning_motor_rereference(participant, ref_method);

    meterlearning_motor_z_scores_eeg(participant, ref_method, average_method); 

    meterlearning_motor_topoplots(participant, ref_method);  

end

% Control
% No accelerometer data for sub-007 (ses-001), sub-014 (ses-003), sub-022,
% (ses-003), sub-043 (ses-003)
for participant = params.all_part

    meterlearning_motor_head_movement(participant, 1);

end

%% ---- FIGURES STAGE 2_1

% BEHAVIOURAL DATA
    % IRI
    meterlearning_motor_paper_figures_iri_ses1

    meterlearning_motor_paper_figures_iri_ses1_3

    % spectra
    meterlearning_motor_paper_figures_clap_spectra(analysis_type)

    % zscores 
    meterlearning_motor_paper_figures_clap_zscores(analysis_type, ...
                                                   normalization, ...
                                                   disp_stim_zscore)
    
    meterlearning_motor_paper_figures_clap_zscores_main_effect_cond(analysis_type, ...
                                                   normalization, ...
                                                   disp_stim_zscore)  
    
% NEURAL DATA
    % ERP
    meterlearning_motor_paper_figures_time_domain

    % spectra
    meterlearning_motor_paper_figures_eeg_spectra(analysis_type)
    meterlearning_motor_paper_figures_topoplots(analysis_type)

    % zscores
    meterlearning_motor_paper_figures_eeg_zscores(analysis_type, ...
                                                  normalization, ...
                                                  disp_stim_zscore)
    
    