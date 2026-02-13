%
% Plot topoplots for meter-related and meter-unrelated frequencies for the two sessions.
%
% Parameters
% ----------
% participant: integral number
%   Participant to process.
% ref_method: string
%   Method of channels re-referencencing. "mastoids" or "common_average"
%
% Output
% -------
% The output is saved as .png image.
%
% Author
% -------
% Ségolène M. R. Guérin
% January 18, 2024
% RnB-Lab (Institute of Neuroscience, UCLouvain)
%

function meterlearning_motor_topoplots(participant, ref_method)

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

% Create empty matrices to store the data
mean_freq_related = zeros(66, 2);
mean_freq_unrelated = zeros(66, 2);

% Indicate data path
file_path = fullfile(params.path_output, 'data/3_preprocessed/', ...
        sprintf('grp-%03d', group), ...
        sprintf('cond-%03d', condition), ...
        sprintf('sub-%03d', participant), 'eeg/');   

% Load the frequency values
file_name_freq = sprintf('grp-%03d_cond-%03d_sub-%03d_freq-values.csv', ...
    group, condition, participant);
freq = readmatrix(fullfile(file_path, file_name_freq));

for session = [1 3]

    %% ---- DATA LOADING
    % Indicate data path and file name
    file_name = sprintf(['grp-%03d_cond-%03d_sub-%03d_ses-%03d_ref-%s_' ...
        'cleaned-fft-values-per-channel.csv'], ...
        group, condition, participant, session, ref_method);
    file_name_header = ...
        sprintf(['grp-%03d_cond-%03d_sub-%03d_task-meterlearning-motor_session-%01d_' ...
        'filtered_epoched_interp_cleaned-trials-ics_ref-%s.lw6'], ...
        group, condition, participant, session, ref_method);

    % Load the FFT values
    denoised_fft_values = readtable(fullfile(file_path, file_name));

    % Load the data header
    [header, ~] = CLW_load(fullfile(file_path, file_name_header));

    %% ---- COMPUTE MEAN VALUES
    % Compute mean FFT values for meter-related frequencies
    if condition == 2
        related = get_mean_freq(denoised_fft_values, freq, ...
            [1.25, 3.75]); % duple
    elseif condition == 3
        related = get_mean_freq(denoised_fft_values, freq, ...
            [0.83, 1.67, 3.33, 4.17]); % triple
    end

    % Compute mean FFT values for meter-unrelated frequencies
    if condition == 2
        unrelated = get_mean_freq(denoised_fft_values, freq, ...
            [0.83, 1.67, 2.08, 2.5, 2.92, 3.33, 4.17, 4.58]); % duple
    elseif condition == 3
        unrelated = get_mean_freq(denoised_fft_values, freq, ...
            [1.25, 2.08, 2.5, 2.92, 3.75, 4.58]); % triple
    end

    %% ---- STORE THE OBTAINED VALUES IN GENERAL MATRICES
    % Find index of the current session
    if session == 1
        idx_session = 1;
    elseif session == 3
        idx_session = 2;
    end

    % Store the data
    mean_freq_related(:, idx_session) = related;
    mean_freq_unrelated(:, idx_session) = unrelated;

end

%% ---- TOPOPLOT
% Adapt the scaling to the reference method
if strcmp(ref_method,"mastoids")
    topo_scaling = [0, 0.3];
elseif strcmp(ref_method,"common_average")
    topo_scaling = [0, 0.15];
end

% Session 1
subplot(2,2,1)
topoplot(mean_freq_related(:, 1), header.chanlocs, 'style', 'map', ...
    'gridscale', 256, ...
    'electrodes', 'on', ...
    'emarkersize', 6, ...
    'maplimits', topo_scaling);
title('Meter-related frequencies');
colorbar % add the color bar
colormap jet % change palette

subplot(2,2,3)
topoplot(mean_freq_unrelated(:, 1), header.chanlocs, 'style', 'map', ...
    'gridscale', 256, ...
    'electrodes', 'on', ...
    'emarkersize', 6, ...
    'maplimits', topo_scaling);
title('Meter-unrelated frequencies');
colorbar % add the color bar
colormap jet % change palette

% Session 3
subplot(2,2,2)
topoplot(mean_freq_related(:, 2), header.chanlocs, 'style', 'map', ...
    'gridscale', 256, ...
    'electrodes', 'on', ...
    'emarkersize', 6, ...
    'maplimits', topo_scaling);
title('Meter-related frequencies');
colorbar % add the color bar
colormap jet % change palette

subplot(2,2,4)
topoplot(mean_freq_unrelated(:, 2), header.chanlocs, 'style', 'map', ...
    'gridscale', 256, ...
    'emarkersize', 6, ...
    'electrodes', 'on', ...
    'maplimits', topo_scaling);
title('Meter-unrelated frequencies');
colorbar % add the color bar
colormap jet % change palette

% Save plot
name_plot = sprintf('grp-%03d_cond-%03d_sub-%03d_ref-%s.png', ...
    group, condition, participant, ref_method);
path_plot = fullfile(params.path_plot, ...
    'eeg/topoplots/');

if ~isfolder(path_plot)
        mkdir(path_plot)
end

saveas(gcf, fullfile(path_plot, name_plot));

% Close plot window
close();
