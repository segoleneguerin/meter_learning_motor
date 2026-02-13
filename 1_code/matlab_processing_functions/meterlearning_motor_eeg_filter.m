%
% Filter EEG data.
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
% Modified by Ségolène M. R. Guérin (January 08, 2024)
% RnB-Lab (Institute of Neuroscience, UCLouvain)
%

function meterlearning_motor_eeg_filter(participant)

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

% Indicate participant folder
cleaned_dir = fullfile(params.path_output, '/data/1_cleaned', ...
    sprintf('grp-%03d', group), ...
    sprintf('cond-%03d', condition), ...
    sprintf('sub-%03d', participant));

for session = [1 3] % for the pre- and post-training sessions

    %% ---- DATA LOADING
    % Indicate file name
    file_name = sprintf('grp-%03d_cond-%03d_sub-%03d_task-meterlearning-motor_session-%01d.lw6', ...
        group, condition, participant, session);

    % Load data
    [header, data] = CLW_load(fullfile(cleaned_dir, file_name));

    % Remove clapping trials
    header.events(find(strcmp({header.events.code}, '2'))) = [];

    % Load channel position
    chan_labels = readtable('chan_labels.csv');

    % Keep only EEG channels
    [header, data] = RLW_arrange_channels(header, data, ...
        chan_labels{:, 'new'});

    % Check number of channels
    assert(length(header.chanlocs) == 66, ...
        'Warning: wrong number of channels.')

    
    %% ---- FILTER
    % High-pass filter 
    [header, data] = RLW_butterworth_filter(header, data, ...
        'filter_type', 'highpass', ...
        'low_cutoff', params.cutoff_low_preproc, ...
        'filter_order', params.order_hpf_preproc);

    % Low-pass filter
    [header, data] = RLW_butterworth_filter(header, data, ...
        'filter_type', 'lowpass', ...
        'high_cutoff', params.cutoff_high_preproc, ...
        'filter_order', params.order_lpf_preproc);

    % Change header name
    header.name = sprintf('%s_filtered', header.name);

    %% ---- SEGMENTATION
    % Segment data while keeping a 5-s buffer at the beginning and end
    % Special case for sub-037 and sub-041 (not enough time between two trials)
    if participant == 37 && session == 1 || participant == 41 && session == 3 || ...
        participant == 67 && session == 3 || participant == 75 && session == 3 ...
        || participant == 76 && session == 1 || participant == 79 && session == 1 ...
        || participant == 81 && session == 1
        [header, data] = RLW_segmentation(...
            header, data, {'1'}, ...
            'x_start', -2, ...
            'x_duration', params.trial_dur + (2 * 2));
    else
        [header, data] = RLW_segmentation(...
            header, data, {'1'}, ...
            'x_start', -params.dur_epoch_buffer, ...
            'x_duration', params.trial_dur + (2 * params.dur_epoch_buffer));
    end

    % Change header name
    header.name = sprintf('%s_epoched', header.name);

    %% ---- SAVE
    % Indicate export path and name
    export_path = fullfile(params.path_output, 'data/2_segmented/', ...
        sprintf('grp-%03d', group), ...
        sprintf('cond-%03d', condition), ...
        sprintf('sub-%03d', participant), 'eeg/');

    if ~isfolder(export_path)
        mkdir(export_path)
    end

    % Save
    CLW_save(export_path, header, data); 

end
