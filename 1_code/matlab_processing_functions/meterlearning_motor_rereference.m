%
% Re-reference the EEG data.
% 
% Parameters
% ----------
% participant: integral number
%   Participant to process.
% method: string
%   Method for re-referencing. "mastoids" or "common_average".
%
% Outputs
% -------
% The outputs are saved as LetsWave files.
%
% Authors
% -------
% Tomas Lenc
% Modified by Ségolène M. R. Guérin (January 11, 2024)
% RnB-Lab (Institute of Neuroscience, UCLouvain)
%

function meterlearning_motor_rereference(participant, method)

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

for session = [1 3]
    
    %% ---- DATA LOADING
    % Indicate data file name and path
    file_path = fullfile(params.path_output, 'data/3_preprocessed/', ...
        sprintf('grp-%03d', group), ...
        sprintf('cond-%03d', condition), ...
        sprintf('sub-%03d', participant), 'eeg/');
    
    file_name = sprintf(['grp-%03d_cond-%03d_sub-%03d_task-meterlearning-motor_session-%01d_' ...
                         'filtered_epoched_interp_cleaned-trials-ics.lw6'], ...
                          group, condition, participant, session);
    
    
    % Load the data
    [header, data] = CLW_load(fullfile(file_path, file_name));
    
    %% ---- RE-REFERENCING
    if method == "mastoids"

        % Re-referencing according to mastoide electrodes
        [header, data] = RLW_rereference(header, data, ...
            'apply_list', {header.chanlocs.labels}, ...
            'reference_list', params.ref_mastoid);

        % Rename the data
        header.name = [header.name, sprintf('_ref-%s', params.ref_name{1})];

    elseif method == "common_average"

        
        % Load external channel location
        chan_labels = readtable('chan_labels.csv');

        % Extract channel-to-average names
        chan_to_average = table2array(chan_labels(1:64, 2))';

        % Re-referencing according to common average
        [header, data] = RLW_rereference(header, data, ...
            'apply_list', {header.chanlocs.labels}, ...
            'reference_list', chan_to_average);

        % Rename the data
        header.name = [header.name, sprintf('_ref-%s-chan-%d', ...
            params.ref_name{2}, 64)];

    end

    %% ---- EXPORT
    
    export_path = fullfile(params.path_output, 'data/3_preprocessed/', ...
        sprintf('grp-%03d', group), ...
        sprintf('cond-%03d', condition), ...
        sprintf('sub-%03d', participant), 'eeg/');
 
    if ~isfolder(export_path)
        mkdir(export_path)
    end
    
    % Save the data
    CLW_save(export_path, header, data);
end 
end