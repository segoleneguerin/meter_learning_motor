%
% Create tables for data checks.
% 
% Parameters
% ----------
% participant: integral number
%   Participant to process.
%
% Output
% -------
% The outputs are saved in .csv format.
%
% Author 
% -------
% Tomas Lenc
% Modified by Ségolène M. R. Guérin (January 11, 2024)
% RnB-Lab (Institute of Neuroscience, UCLouvain)
%

function meterlearning_motor_add_to_check_files(participant)

%% ---- PREAMBLE
% Load parameters file
params = meterlearning_motor_get_params(); 

% Load participants allocation file
alloc_file = readtable(fullfile(params.experiment_path, ...
    '0_data/meterlearning-motor_participant_allocation.xlsx'));

% Extract group and condition
group = table2array(alloc_file(participant, 2));
condition = table2array(alloc_file(participant, 3));

%% ---- CHANNELS
% Indicate file name
fname = fullfile(params.path_output, '/checks/', 'bad_chans.xlsx'); 

% Read the file if existing or create
if isfile(fname)
    tbl = readtable(fname); 
else
    col_names = {'participant', 'group', 'condition', 'bad_chans'}; 
    tbl = cell2table(cell(0, length(col_names)), 'VariableNames', col_names); 
end

% Write current participants row
if ~any(tbl.participant == participant)
    new_row = {participant, group, condition, 0}; 
    tbl = [tbl; new_row]; 
end

if ~isfolder(fullfile(params.path_output, '/checks/'))
    mkdir(fullfile(params.path_output, '/checks/'))
end

% Write the table
writetable(tbl, fname); 

%% ---- INDEPENDENT COMPONENTS
% Indicate file name
fname = fullfile(params.path_output, '/checks/', 'bad_ics.xlsx'); 

% Read the file if existing or create
if isfile(fname)
    tbl = readtable(fname); 
else
    col_names = {'participant', 'group', 'condition', 'bad_ICs'};
    tbl = cell2table(cell(0, length(col_names)), 'VariableNames', col_names); 
end

% Write current participants row
if ~any(tbl.participant == participant)
    new_row = {participant, group, condition, 0}; 
    tbl = [tbl; new_row]; 
end

% Write the table
writetable(tbl, fname); 

%% ---- TRIALS
% Indicate file name
fname = fullfile(params.path_output, '/checks/', 'bad_trials.xlsx'); 

% Read the file if existing or create
if isfile(fname)
    tbl = readtable(fname); 
else
    col_names = {'participant', 'group', 'condition', 'session', 'bad_trials'};
    tbl = cell2table(cell(0, length(col_names)), 'VariableNames', col_names); 
end

% Write current participants row
if ~any(tbl.participant == participant)
    for session = [1 3]
        new_row = {participant, group, condition, session, '?'}; 
        tbl = [tbl; new_row]; 
    end
end

% Write the table
writetable(tbl, fname); 
