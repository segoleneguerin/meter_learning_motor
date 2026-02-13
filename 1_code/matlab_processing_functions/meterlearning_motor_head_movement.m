%
% Compute head movements based on accelerometer measurements.
% 
% Parameters
% ----------
% participant: integral number
%   Participant to process.
% axis_number: integral number
%   Axis of the accelerometer. 1 = 'Ana1', 2 = 'Ana2'
%
% Output
% -------
% The output is saved as a .csv file.
%
% Author 
% -------
% Ségolène M. R. Guérin
% January 18, 2024
% RnB-Lab (Institute of Neuroscience, UCLouvain)
%

function meterlearning_motor_head_movement(participant, axis_number)

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
tbl_z_snr = cell2table(cell(0, 5), ...
    'VariableNames', {'group', 'condition', 'participant', 'session', 'z_snr'});

% Indicate participant folder
cleaned_dir = fullfile(params.path_output, 'data/1_cleaned/', ...
        sprintf('grp-%03d', group), ...
        sprintf('cond-%03d', condition), ...
        sprintf('sub-%03d', participant));

for session = [1 3] % for the pre- and post-training sessions

    %% ---- LOAD THE DATA
    % Indicate file name
    file_name = sprintf('grp-%03d_cond-%03d_sub-%03d_task-meterlearning-motor_session-%01d.lw6', ...
        group, condition, participant, session);

    % Load the relevant data file
    [header, data] = CLW_load(fullfile(cleaned_dir, file_name));

    %% ---- FORMATE DATA
    % Keep only accelerometer channels
    [header, data] = RLW_arrange_channels(header, data, ...
        {'Erg1', 'Erg2', 'Ana8'});

    % Keep only listening markers
    header.events = header.events(strcmp({header.events.code}, '1'));

    % Remove clapping trials
    header.events((end - 4):end) = [];

    % Epoch trials
    [header, data] = RLW_segmentation(header, data, ...
        {'1'}, ...
        'x_start', -params.dur_epoch_buffer, ...
        'x_duration', params.trial_dur + (2 * params.dur_epoch_buffer));

    % Average trials
    [header, data] = RLW_average_epochs(header, data);

    %% ---- COMPUTE FFT
    % Resize data to have a 2-D matrix
    data_accelerometer = squeeze(data);

    % Remove the 5 sec pre/post and the first rhythmic pattern
    beg_file = round((params.dur_epoch_buffer * params.fs) + ...
        (params.pattern_dur * params.fs)) + 1; % otherwise start at 0
    end_file = length(data) - (params.dur_epoch_buffer * params.fs) + 1;
    data_accelerometer = data_accelerometer(:, beg_file:end_file);

    % Declare FFT parameters
    N = length(data_accelerometer); % data lenght
    maxfreqidx = round(6 / params.fs * N) + 1; % max FFT freq value (6 Hz)

    % ----- Accelerometer
    % Run the computation
    mX = abs(fft(data_accelerometer(axis_number, :))) / N;

    % Resize FFT
    freq = (0 : maxfreqidx - 1) / N * params.fs;
    mX(1) = 0;
    mX = mX(1 : maxfreqidx);

    % ----- Sound
    % Run the computation
    mX_sound = abs(fft(data_accelerometer(3, :))) / N;

    % Resize FFT
    freq_sound = (0 : maxfreqidx - 1) / N * params.fs;
    mX_sound(1) = 0;
    mX_sound = mX_sound(1 : maxfreqidx);

    %% ---- PLOT
    plot_fft(freq, mX, ...
        'frex_meter_rel', ...
        [0.42, 0.83, 1.25, 1.67, 2.08, 2.5, 2.92, 3.33, 3.75, 4.17, 4.58, 5]);
    title(sprintf(['Raw Accelerometer Spectrum Participant %02d, ' ...
        'Session %02d, Axis %d'], ...
        participant, session, axis_number));

    % Save
    name_plot = sprintf('grp-%03d_cond-%03d_sub-%03d_ses-%03d_axis-%01d.png', ...
        group, condition, participant, session, axis_number);
    path_plot = fullfile(params.path_plot, 'head/raw_fft_spectrum/');

    if ~isfolder(path_plot)
        mkdir(path_plot)
    end

    saveas(gcf, fullfile(path_plot, name_plot));

    % Close plot window
    close();

    %% ---- COMPUTE Z SNR
    % Meter-related frequencies
    if condition == 2
        [z_snr, mean_snip, idx_snip] = get_z_snr(mX, freq, ...
            [1.25, 3.75], ... % frex duple
            1, ... % bin_from
            10); % bin_to
    elseif condition == 3
        [z_snr, mean_snip, idx_snip] = get_z_snr(mX, freq, ...
            [0.83, 1.67, 3.33, 4.17], ... % frex triple
            1, ... % bin_from
            10); % bin_to
    end

    % Organise data
    new_row = [...
        repmat({group}, 1, 1), ... % group
        repmat({condition}, 1, 1), ... % condition
        repmat({participant}, 1, 1), ... % participant
        repmat({session}, 1, 1), ... % session
        num2cell(z_snr), ... % z snr
        ];

    % Store in a matrix
    tbl_z_snr = [tbl_z_snr; new_row];

    %% ---- PLOT
    plot(mean_snip, '.-', 'MarkerSize', 15)
    xlabel('Bin Number', 'fontweight', 'bold', ...
        'fontsize', 12);
    ylabel('Amplitude', 'fontweight', 'bold', ...
        'fontsize', 12);
    hold on
    plot(11, mean_snip(11), 'r.', 'MarkerSize', 15)
    hold off
    box off
    set(gca, 'TickDir', 'out');

    % Save
    name_plot = sprintf('grp-%03d_cond-%03d_sub-%03d_ses-%03d_axis-%01d_z-snr.png', ...
        group, condition, participant, session, axis_number);
    path_plot = fullfile(params.path_plot, 'head/z_snr/');

    if ~isfolder(path_plot)
        mkdir(path_plot)
    end

    saveas(gcf, fullfile(path_plot, name_plot));

    % Close plot window
    close();

end

%% ---- SAVE
export_name = sprintf('grp-%03d_cond-%03d_sub-%03d_axis-%d_z-snr.csv', ...
    group, condition, participant, axis_number);
export_path = fullfile(params.path_output, 'data/4_final/head/z_snr/');

if ~isfolder(export_path)
    mkdir(export_path)
end

writetable(tbl_z_snr, fullfile(export_path, export_name));
