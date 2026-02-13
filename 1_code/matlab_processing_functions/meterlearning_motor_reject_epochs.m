%
% Reject bad trials.
% 
% Parameters
% ----------
% participant: integral number
%   Participant to process.
%
% Outputs
% -------
% The outputs are saved as a LetsWave files.
%
% Author 
% -------
% Tomas Lenc
% Modified by Ségolène M. R. Guérin (August 13, 2024)
% RnB-Lab (Institute of Neuroscience, UCLouvain)
%

function meterlearning_motor_reject_epochs(participant)

%% ---- PREAMBLE
% Load parameters file
params = meterlearning_motor_get_params(); 

% Import version 6 of Letswave
import_lw(6)

% Load participants allocation file
alloc_file = readtable(fullfile(params.experiment_path, ...
    '0_data/meterlearning-motor_participant_allocation.xlsx')); 

% Extract group and condition
group = table2array(alloc_file(participant, 2));
condition = table2array(alloc_file(participant, 3));

% Indicate file name
file_name = fullfile(params.path_output, '/checks/', 'bad_trials.xlsx'); 


% Load bad trial table
tbl_bads = readtable(file_name); 

% Indicate data path
file_path = fullfile(params.path_output, 'data/3_preprocessed/', ...
        sprintf('grp-%03d', group), ...
        sprintf('cond-%03d', condition), ...
        sprintf('sub-%03d', participant), 'eeg/');

for session = [1 3]

    % Extract bad channels for the current participant
    bads = tbl_bads{tbl_bads.participant == participant & ...
        tbl_bads.group == group & ...
        tbl_bads.condition == condition & ...
        tbl_bads.session == session, 'bad_trials'}; 

    % Put each number in different cells if needed
    bads = str2num(bads{1}); 

    % Print rejected trial number(s) where necessary
    if ~isempty(bads)
        fprintf('sub-%03d, ses-%03d: rejecting epoch(s) %s\n', ...
            participant, session, num2str(bads)); 
    end
    
    %% ---- LOADING DATA
    % Indicate file name
    file_name = ...
        sprintf('grp-%03d_cond-%03d_sub-%03d_task-meterlearning-motor_session-%01d_filtered_epoched_interp.lw6', ...
        group, condition, participant, session);

    % Load data
    [header, data] = CLW_load(fullfile(file_path, file_name));
    
    %% ---- REJECT BAD TRIALS
    % Find positions of trials to keep
    idx_ep_to_keep = setdiff([1 : header.datasize(1)], bads);
    
    % Remove bad trials
    [header, data] = RLW_arrange_epochs(header, data, idx_ep_to_keep);
    
    % Rename the data file
    header.name = [header.name, '_cleaned-trials']; 
    
    % Save the data
    CLW_save(file_path, header, data);
    
end