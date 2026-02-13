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
% There is no outputs. Bad channels and trials are visually selected and indicated 
% manually in the associatied .csv files.
%
% Procedure
% -------
% Once the GUI is open, click on 'View' > 'Multiviewer Waveform'.
% Set the Y-axis from -200 to 200.
% Check all the epochs together channel by channel; should not be
% above/below +50/-50.
% Check all the electrodes together epoch by epoch; should be all within
% the same range, ideally between +50/-50.
%
% Author 
% -------
% Tomas Lenc
% Modified by Ségolène M. R. Guérin (January 11, 2024)
% RnB-Lab (Institute of Neuroscience, UCLouvain)
%

function meterlearning_motor_visual_inspection(participant)

%% ---- PREAMBLE
% Load parameters file
params = meterlearning_motor_get_params(); 

% Load participants allocation file
alloc_file = readtable(fullfile(params.experiment_path, ...
    '0_data/meterlearning-motor_participant_allocation.xlsx')); 

% Extract group and condition
group = table2array(alloc_file(participant, 2));
condition = table2array(alloc_file(participant, 3));

% Import version 7 of Letswave
import_lw(7)

% Indicate path
cd(fullfile(params.path_output, 'data/2_segmented/', ...
        sprintf('grp-%03d', group), ...
        sprintf('cond-%03d', condition), ...
        sprintf('sub-%03d', participant), 'eeg/')); 

% Open Letswave
letswave