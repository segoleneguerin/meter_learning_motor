%
% Run independent-component analysis.
% 
% Parameters
% ----------
% participant: integral number
%   Participant to process.
%
% Output
% -------
% The output is saved as a MATLAB matrix.
%
% Author 
% -------
% Tomas Lenc
% Modified by Ségolène M. R. Guérin (August 13, 2024)
% RnB-Lab (Institute of Neuroscience, UCLouvain)
%

function meterlearning_motor_run_ica(participant)

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

% Create an empty matrix to store the data
data_all = cell(1, 2); 

for session = [1 3]
    
    % Indicate data path
    file_path = fullfile(params.path_output, 'data/3_preprocessed/', ...
        sprintf('grp-%03d', group), ...
        sprintf('cond-%03d', condition), ...
        sprintf('sub-%03d', participant), 'eeg/');

    % Indicate file name
    file_name = ...
        sprintf(['grp-%03d_cond-%03d_sub-%03d_task-meterlearning-motor_session-%01d_' ...
        'filtered_epoched_interp_cleaned-trials.lw6'], ...
        group, condition, participant, session);

    % Load the data
    [header, data] = CLW_load(fullfile(file_path, file_name));
        
    %% ---- FILTER
    % Apply anti-aliasing filter (i.e., strict low-pass filter to prevent
    % aliasing after downsampling in the following steps)
    [header, data] = RLW_butterworth_filter(header, data, ...
        'filter_type', 'lowpass', ...
        'high_cutoff', params.cutoff_high_ica, ...
        'filter_order', params.order_lpf_ica);

    % high-pass filter to remove slow drifts (ICA converges faster)
    [header, data] = RLW_butterworth_filter(header, data, ...
        'filter_type', 'highpass', ...
        'low_cutoff', params.cutoff_low_ica, ...
        'filter_order', params.order_hpf_ica);
           
    % Segment the data from time 0 to trial end
    [header, data] = RLW_segmentation(...
        header, data, {'1'}, ...
        'x_start', 0, ...
        'x_duration', params.trial_dur...
        );
    
    %% ---- DOWNSAMPLE
    % Indicate down-sampling ratio
    ds_ratio = round((1/header.xstep) / params.fs_ica);
    
    % Re-sample the data
    [header, data] = RLW_downsample(header, data,...
        'x_downsample_ratio', ds_ratio);
                   
    % Check if the downsampling was correctly executed
    assert(1/header.xstep == params.fs_ica, ...
        'Warning: downsampling was not correctly executed.');
    
    %% ---- CONCATENATE TRIALS
    % First, concatenate all the epochs for this tempo condition. Matlab
    % reshape function only performs fortran-like reshape, which means it
    % always starts from the first dimension. But we have the time on the LAST
    % dimension (which would be C-style reshape). So, we first have to re-order
    % the dimensions so that time is first.
    data = permute(data, [6, 1, 2, 3, 4, 5]);

    % Perform the reshape (we'll have time x channel)
    data = reshape(...
        data, ...
        [header.datasize(1) * header.datasize(6), header.datasize(2)]...
        );
    
    % Store the epoch-concatenated data into all-tempo matrix
    data_all{session} = data;
    
end

% Concatenate the data
data_all_concat = cat(1, data_all{:});

% Format the data to follow Letswave requirments
data_ica = [];
data_ica(1, :, 1, 1, 1, :) = data_all_concat';

% Correct header information
header_ica = header;
header_ica.events = [];
header_ica.datasize = size(data_ica);
header_ica.xstart = 0;

%% ---- RUN ICA
% Run ICA
matrix_ICA = RLW_ICA_compute(header_ica, data_ica, ...
    'PICA_percentage', 99,...
    'ICA_mode', 'LAP');

% Indicate file name
file_name = sprintf('grp-%03d_cond-%03d_sub-%03d_ica-matrix', ...
    group, condition, participant); 

% Save ICA matrix
save(fullfile(file_path, file_name), 'matrix_ICA');

%% ---- ASSIGN ICA INFO
% Load the ICA matrix info
cd(fullfile(params.experiment_path,'1_code'))
load('ica_gui_data.mat')   

for session = [1 3]
    
    % Indicate file name
    file_name = ...
        sprintf(['grp-%03d_cond-%03d_sub-%03d_task-meterlearning-motor_session-%01d_' ...
        'filtered_epoched_interp_cleaned-trials.lw6'], ...
        group, condition, participant, session);

    % Load the data (unfiltered for ICA)
    [header, data] = CLW_load(fullfile(file_path, file_name));

    % Add the ICA info in history
    header.history = [];
    header.history(end + 1).configuration.gui_info = ica_gui_data;
    header.history(end).configuration.parameters.ICA_um = matrix_ICA.ica_um;
    header.history(end).configuration.parameters.ICA_mm = matrix_ICA.ica_mm;

    % Save the data
    CLW_save(file_path, header, data);
    
end