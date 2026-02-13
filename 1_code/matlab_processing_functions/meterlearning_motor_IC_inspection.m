%
% Visually check the data.
% 
% Parameters
% ----------
% participant: integral number
%   Participant to process.
%
% Output
% -------
% There is no outputs. ICs are visually inspected and those related to eye
% movements are manually indicated in the associatied .csv files.
%
% Procedure
% -------
% Select the cleaned-trials files, select the Preprocess tab, Spatial
% Filter, then ICA Apply Spatial Filter.
% Look at the signal of the first 5 ICs and their respective topographies
% and check for eye blinks and horizontal eye movements.
% Manually indicate the ICs to remove in the bad_ics.xlsx file. 
%
% Author 
% -------
% Tomas Lenc
% Modified by Emmanuel Coulon (December 13, 2024)
% RnB-Lab (Institute of Neuroscience, UCLouvain)


function meterlearning_motor_IC_inspection(participant)

%% ---- PREAMBLE
% Load parameters file
params = meterlearning_motor_get_params(); 

% Load participants allocation file
alloc_file = readtable(fullfile(params.experiment_path, ...
    '0_data/meterlearning-motor_participant_allocation.xlsx')); 

% Extract condition
group = table2array(alloc_file(participant, 2));
condition = table2array(alloc_file(participant, 3));

% Import version 6 of Letswave
import_lw(6)

% Indicate path
cd(fullfile(params.path_output, 'data/3_preprocessed/', ...
        sprintf('grp-%03d', group), ...
        sprintf('cond-%03d', condition), ...
        sprintf('sub-%03d', participant), 'eeg')); 

% Open Letswave
letswave

