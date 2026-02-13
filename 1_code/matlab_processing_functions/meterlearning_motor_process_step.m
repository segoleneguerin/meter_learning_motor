%
% Function to compute inter-step intervals and associated dependent 
% variables based on accelerometer measurements.
% 
% Parameters
% ----------
% participant: integral number
%   Participant to process.
%
% Outputs 
% -------
% The outputs are saved as .csv files.
%
% Authors 
% -------
% Ségolène M. R. Guérin
% July 02, 2024
% RnB-Lab (Institute of Neuroscience, UCLouvain)
%

function meterlearning_motor_process_step(participant)

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

% Load axis number file
axis_file = readtable(fullfile(params.experiment_path, ...
    '2_output/checks/step_axis.xlsx')); 

% Compute trial duration
trial_dur_conti = params.tempi/1000 * ....
                  params.n_events_per_pattern * ...
                  params.n_patterns_conti; 
pattern_dur = (params.tempi/1000 * params.n_events_per_pattern);

% Create an empty matrix to store the data
tbl_iri_error = cell2table(cell(0, 6), ...
    'VariableNames', {'group', 'condition', 'participant', 'session', ...
    'trial', 'iri_error'});
tbl_asynch = cell2table(cell(0, 6), ...
    'VariableNames', {'group', 'condition', 'participant', 'session', ...
    'trial', 'signed_asynchrony'});

%% ---- LOAD THE DATA
% Set path for the current participant
raw_dir = fullfile(params.path_output, '/data/1_cleaned', ...
    sprintf('grp-%03d', group), ...
    sprintf('cond-%03d', condition), ...
    sprintf('sub-%03d', participant));

% Indicate file name
file_name = sprintf('grp-%03d_cond-%03d_sub-%03d_task-meterlearning-motor_session-2.lw6', ...
    group, condition, participant);

% Load the current participant file
[header, data] = CLW_load(fullfile(raw_dir, file_name));

% Resize data to have a 2-D matrix
data_accelerometer = squeeze(data);

%% ---- EXTRACT RELEVANT DATA
for trial = 1:(params.nb_trial) % for each trial

    % Extract trigger time
    if (participant == 37)
        trigger_time = header.events(strcmp({header.events.code}, '3'));
    else
        trigger_time = header.events(strcmp({header.events.code}, '1'));
    end

    % Extract current trial (remove the first rhythmic pattern)
    trial_beg = round((trigger_time(trial).latency + pattern_dur) * 1/header.xstep);
    trial_end = (trigger_time(trial).latency * 1/header.xstep) + ...
        (round(params.trial_dur + trial_dur_conti, 1) * 1/header.xstep);

    current_trial = data_accelerometer(:, (trial_beg: trial_end))';

    % Flip signal if need
    if participant == 13 || participant == 15 || participant == 40 || participant == 55 || ...
            participant == 58 || participant == 60 || participant == 65 || participant == 66 || ...
            participant == 83 || participant == 87 || participant == 88 || participant == 93 || ...
            participant == 94
        current_trial = -current_trial;
    end

    %% ---- EXTRACT STEPS
    % Extract axis number
    axis_number = table2array(axis_file(participant, 4));

    % Find step location (arbitrary threshold)
    if condition == 2
        min_pk_dist = (1/header.xstep) * 0.6; % 600 ms for duple
    elseif condition == 3
        min_pk_dist = (1/header.xstep) * 0.4; % 400 ms for triple
    end
    min_pk_height = mean(current_trial(:, axis_number)) + ...
        (3 * std(current_trial(:, axis_number)));

     % Find peaks
    [peak_amp, locs] = findpeaks(current_trial(:, axis_number), ...
        'MinPeakDistance', min_pk_dist, ... % in data point
        'MinPeakHeight', min_pk_height); % on either side of the signal

    % Convert peaks location from data points to seconds
    locs_sec = locs / (1/header.xstep);

    %% ---- RECREATE TRACKER SOUND PATTERN
    % Recreate tracker sound pattern
    if condition == 2
        tracker_position = [1, round(0.8 * (1/header.xstep)) + 1, ...
            round(1.6 * (1/header.xstep)) + 1]; % duple
    elseif condition == 3
        tracker_position = [1, round(0.6 * (1/header.xstep)) + 1, ...
            round(1.2 * (1/header.xstep)) + 1, round(1.8 * (1/header.xstep)) + 1]; % triple
    end

    tracker = zeros(1, round(2.4 * (1/header.xstep)));
    tracker(tracker_position) = 1;
    tracker = repmat(tracker, 1, 19); % 20 repetition - 1 first pattern
    tracker = tracker(1:length(current_trial(:, axis_number)));

    % Find metronome tracker location
    locs_sound = find(tracker);

    % Convert peaks location from data points to seconds
    locs_sound_sec = locs_sound / (1/header.xstep);

    % Find sound location for the first step
    [~, idx_min] = min(abs(locs_sec(1)-locs_sound_sec));

    % Resize sound matrix
    locs_sound_sec = locs_sound_sec(idx_min:length(locs_sound_sec))';

    % Remove continuation part
    final_length = params.trial_dur - params.pattern_dur;
    locs_sound_sec = locs_sound_sec(locs_sound_sec < floor(final_length));
    locs_sec = locs_sec(locs_sec < floor(final_length));
    peak_amp = peak_amp(1:length(locs_sec));

    % Keep only one sound over two
    if participant == 32
        if trial < 7
            locs_sound_sec = locs_sound_sec;
        else
            locs_sound_sec = locs_sound_sec(1:2:end);
        end
    else
        locs_sound_sec = locs_sound_sec(1:2:end);
    end

    %% ---- CHECK IF THE STEP FINDING WAS CORRECTLY EXECUTED
    % Remove continuation
    time_vector = 1:length(current_trial(:, axis_number));
    time_vector = time_vector / (1/header.xstep);

    % Run tap corrector
    [locs_sec, peak_amp] = tap_corrector(time_vector, (1/header.xstep), ...
        tracker * 80000, current_trial(:, axis_number), locs_sec, peak_amp, ...
        final_length, participant, group, condition, trial);

    % If the sound and clap matrices have not the same length
    if length(locs_sound_sec) ~= length(locs_sec)
        waitfor(msgbox("Warning: the sound and step matrices have not the same length, please double check for any missing/extra step."))
        [locs_sec, peak_amp] = tap_corrector(time_vector, (1/header.xstep), ...
            tracker * 100000, current_trial(:, axis_number), locs_sec, peak_amp, ...
            final_length, participant, group, condition, trial);
    end

    %% ---- IN CASE THE SOUND AND STEP MATRICES HAVE NOT THE SAME LENGTH
    if length(locs_sound_sec) ~= length(locs_sec)

        % Match step with closest sound
        for step = 1:length(locs_sec)
            [~, idx_check(step)] = ...
                min(abs(locs_sec(step)-locs_sound_sec));
        end

        % If the first clap is missing
        if idx_check(1) > 1

            locs_sound_sec = locs_sound_sec(idx_check(1):end);
            locs_sound = locs_sound(idx_check(1):end);

        end

    end

    % In case the sound and step matrices STILL have not the same length
    if length(locs_sound_sec) ~= length(locs_sec)

        % Match clap with closest sound
        for step = 1:length(locs_sec)
            [~, idx_check(step)] = ...
                min(abs(locs_sec(step)-locs_sound_sec));
        end

        % Find which sound numbers are not matching steps
        idx_check_diff = diff(idx_check);

        while isempty(find(idx_check_diff ~= 1, 1, 'first')) == false
            
            to_remove = find(idx_check_diff ~= 1, 1, 'first') + 1;
            
            % If ONE additionnal sound
            if idx_check_diff(to_remove - 1) == 2

                % Extract the two possible additional sounds
                vec_idx_sound = [locs_sound_sec(to_remove), ...
                    locs_sound_sec(to_remove + 1)];

                % Find the farthest sound to the step
                [~, idx_sound] = max(abs(locs_sec(to_remove)-vec_idx_sound));

                % Remove additional sound
                if idx_sound == 1
                    locs_sound_sec(to_remove) = NaN;
                elseif idx_sound == 2
                    locs_sound_sec(to_remove + 1) = NaN;
                end

            end

            % If TWO additionnal sounds
            if idx_check_diff(to_remove - 1) == 3

                % Extract the three possible additional sounds
                vec_idx_sound = [locs_sound_sec(to_remove), ...
                    locs_sound_sec(to_remove + 1), ...
                    locs_sound_sec(to_remove + 2)];

                % Find the closest sound to the step
                [~, idx_sound] = min(abs(locs_sec(to_remove)-vec_idx_sound));

                % Remove additional sounds
                if idx_sound == 1
                    locs_sound_sec(to_remove + 1) = NaN;
                    locs_sound_sec(to_remove + 2) = NaN;
                elseif idx_sound == 2
                    locs_sound_sec(to_remove) = NaN;
                    locs_sound_sec(to_remove + 2) = NaN;
                elseif idx_sound == 3
                    locs_sound_sec(to_remove) = NaN;
                    locs_sound_sec(to_remove + 1) = NaN;
                end

            end

            % If THREE additionnal sounds
            if idx_check_diff(to_remove - 1) == 4

                % Extract the three possible additional sounds
                vec_idx_sound = [locs_sound_sec(to_remove), ...
                    locs_sound_sec(to_remove + 1), ...
                    locs_sound_sec(to_remove + 2), ...
                    locs_sound_sec(to_remove + 3)];

                % Find the closest sound to the step
                [~, idx_sound] = min(abs(locs_sec(to_remove)-vec_idx_sound));

                % Remove additional sounds
                if idx_sound == 1
                    locs_sound_sec(to_remove + 1) = NaN;
                    locs_sound_sec(to_remove + 2) = NaN;
                    locs_sound_sec(to_remove + 3) = NaN;
                elseif idx_sound == 2
                    locs_sound_sec(to_remove) = NaN;
                    locs_sound_sec(to_remove + 2) = NaN;
                    locs_sound_sec(to_remove + 3) = NaN;
                elseif idx_sound == 3
                    locs_sound_sec(to_remove) = NaN;
                    locs_sound_sec(to_remove + 1) = NaN;
                    locs_sound_sec(to_remove + 3) = NaN;
                elseif idx_sound == 4
                    locs_sound_sec(to_remove) = NaN;
                    locs_sound_sec(to_remove + 1) = NaN;
                    locs_sound_sec(to_remove + 2) = NaN;
                end

            end

            % If FOUR additionnal sounds
            if idx_check_diff(to_remove - 1) == 5

                % Extract the three possible additional sounds
                vec_idx_sound = [locs_sound_sec(to_remove), ...
                    locs_sound_sec(to_remove + 1), ...
                    locs_sound_sec(to_remove + 2), ...
                    locs_sound_sec(to_remove + 3), ...
                    locs_sound_sec(to_remove + 4)];

                % Find the closest sound to the step
                [~, idx_sound] = min(abs(locs_sec(to_remove)-vec_idx_sound));

                % Remove additional sounds
                if idx_sound == 1
                    locs_sound_sec(to_remove + 1) = NaN;
                    locs_sound_sec(to_remove + 2) = NaN;
                    locs_sound_sec(to_remove + 3) = NaN;
                    locs_sound_sec(to_remove + 4) = NaN;
                elseif idx_sound == 2
                    locs_sound_sec(to_remove) = NaN;
                    locs_sound_sec(to_remove + 2) = NaN;
                    locs_sound_sec(to_remove + 3) = NaN;
                    locs_sound_sec(to_remove + 4) = NaN;
                elseif idx_sound == 3
                    locs_sound_sec(to_remove) = NaN;
                    locs_sound_sec(to_remove + 1) = NaN;
                    locs_sound_sec(to_remove + 3) = NaN;
                    locs_sound_sec(to_remove + 4) = NaN;
                elseif idx_sound == 4
                    locs_sound_sec(to_remove) = NaN;
                    locs_sound_sec(to_remove + 1) = NaN;
                    locs_sound_sec(to_remove + 2) = NaN;
                    locs_sound_sec(to_remove + 4) = NaN;
                elseif idx_sound == 5
                    locs_sound_sec(to_remove) = NaN;
                    locs_sound_sec(to_remove + 1) = NaN;
                    locs_sound_sec(to_remove + 2) = NaN;
                    locs_sound_sec(to_remove + 3) = NaN;
                end

            end

            % If ONE additionnal step
            if idx_check_diff(to_remove - 1) == 0

                % Add an additional sound
                locs_sound_sec = [locs_sound_sec(1:to_remove - 1); ...
                    locs_sound_sec(to_remove - 1) + 0.0001; ... % add a tiny bit of time 
                    % so idx_check match steps with the right sound
                    locs_sound_sec(to_remove:end)];

            end

            % Remove rows with NaN
            locs_sound_sec(any(isnan(locs_sound_sec), 2), :) = [];

            % Match step with closest sound
            for step = 1:length(locs_sec)
                [~, idx_check(step)] = ...
                    min(abs(locs_sec(step)-locs_sound_sec));
            end

            % Find which sound numbers are not matching steps
            idx_check_diff = diff(idx_check);

        end

        % If additionnal sounds AFTER the last synchro step
        if length(locs_sound_sec) > length(locs_sec)

            % Remove additional steps at the end
            locs_sound_sec(find(locs_sound_sec > floor(locs_sec(end)) + 0.5)) = NaN;

            % Remove rows with NaN
            locs_sound_sec(any(isnan(locs_sound_sec), 2), :) = [];
        
        end

        % Round sound matrix (useful is additional sounds were included)
        locs_sound_sec = round(locs_sound_sec, 3);

    end
    
    % Empty vector
    clear idx_check idx_check_diff to_remove

     %% ---- COMPUTE ASYNCHRONY
    % Compute signed asynchrony
    % negative = too early; positive = too late
    if length(locs_sound_sec) ~= length(locs_sec)
        mean_asynch = NaN;
    else
        asynch = locs_sec - locs_sound_sec;
        mean_asynch = mean(asynch);
    end
    
    if length(locs_sound_sec) > length(locs_sec) + 4 || ... % too many sounds compared to claps
       length(locs_sec) > length(locs_sound_sec) + 1        % too many claps compared to sounds
       
        mean_asynch = NaN;       
        
    elseif participant == 2 && trial == 14 || participant == 3 && trial == 3 || ...
            participant == 3 && trial == 4 || participant == 3 && trial == 7 || ...
            participant == 3 && trial == 14 || participant == 4 && trial == 1 || ...
            participant == 4 && trial == 7 || participant == 4 && trial == 9 || ...
            participant == 4 && trial == 10 || participant == 4 && trial == 12 || ...
            participant == 4 && trial == 15 || participant == 4 && trial == 17

        mean_asynch = NaN;

    else
        try
            asynch = locs_sec - locs_sound_sec;
            mean_asynch = mean(asynch);
        catch
            fprintf('Asynchrony couldn''t be computed for participant %i and trial %i', participant, trial)
            mean_asynch = NaN;
        end
    end

    % Organise data
    new_row = [...
        repmat({group}, 1, 1), ... % group
        repmat({condition}, 1, 1), ... % condition
        repmat({participant}, 1, 1), ... % participant
        repmat({2}, 1, 1), ... % session
        repmat({trial}, 1, 1), ... % trial
        num2cell(mean_asynch) ... % asynchrony
        ];

    % Store data
    tbl_asynch = [tbl_asynch; new_row];
    
    grp_name    = sprintf('grp%03d', group);
    cond_name   = sprintf('cond%03 d', condition);
    sub_name    = sprintf('sub%03d', participant);
    trial_name  = sprintf('trial%i', trial);
    
    Asynch.(grp_name).(cond_name).(sub_name).(trial_name) = asynch;    

    %% ---- COMPUTE IRI ERROR
    % Compute inter-response intervals
    if participant == 32
        if trial < 7
            iri = diff(locs_sec);
        else
            iri = diff(locs_sec)/2;
        end
    else
        iri = diff(locs_sec)/2;
    end

    % Compute absolute IRIerror
    if condition == 2
        iri_error = (abs(iri - 0.800) / 0.800) .* 100 ; % duple
    elseif condition == 3
        iri_error = (abs(iri - 0.600) / 0.600) .* 100 ; % triple
    end

    % Compute mean IRIerror
    mean_iri = mean(iri_error);

    % Organise data
    new_row = [...
        repmat({group}, 1, 1), ... % group
        repmat({condition}, 1, 1), ... % condition
        repmat({participant}, 1, 1), ... % participant
        repmat({2}, 1, 1), ... % session
        repmat({trial}, 1, 1), ... % trial
        num2cell(mean_iri) ... % iri error
        ];

    % Store data
    tbl_iri_error = [tbl_iri_error; new_row];

    %% ---- PLOT
    % Plot iri error
    subplot(2,1,1);
    plot(time_vector, current_trial(:, axis_number), 'LineWidth', 1, ...
        'MarkerFaceColor', [0 0.4470 0.7410]);
    hold on
    scatter(locs_sec, peak_amp, 'filled');
    xline(params.trial_dur - params.pattern_dur, ...
        '--r', 'LineWidth', 1);
    title(sprintf('Condition %02d, Participant %02d, Session 02, Trial %02d, Axis %d', ...
        condition, participant, trial, axis_number));
    xlabel('Time', 'fontweight', 'bold', ...
        'fontsize', 12);
    ylabel('Accelerometer Amplitude', 'fontweight', 'bold', ...
        'fontsize', 12);
    set(gca, 'TickDir', 'out');
    hold off
    box off
    grid off

    subplot(2,1,2);
    plot(iri_error, '.-', ...
        'MarkerSize', 15);
    yline(15, '--r', 'Threshold', 'LineWidth', 2);
    text(19, 13, strcat('mean =', {' '}, num2str(mean(iri_error))));
    xlabel('Data Point', 'fontweight', 'bold', ...
        'fontsize', 12);
    ylabel('IRI error (%)', 'fontweight', 'bold', ...
        'fontsize', 12);
    set(gca, 'TickDir', 'out');
    box off

    % Save plot
    name_plot = sprintf(['grp-%03d_cond-%03d_sub-%03d_ses-002_' ...
        'trial-%02d_axis-%d.png'], ...
        group, condition, participant, trial, axis_number);
    path_plot = fullfile(params.path_output, '/plots/step/iri_error/', ...
        sprintf('sub-%03d', participant));

    if ~isfolder(path_plot)
        mkdir(path_plot)
    end

    saveas(gcf, fullfile(path_plot, name_plot));


    % Plot asynchrony
    subplot(2,1,1);
    plot(current_trial(:, 3), 'Color', [0 0.4470 0.7410 0.05])
    hold on
    plot(tracker * 1500000, 'LineWidth', 2)
    plot((current_trial(:, axis_number) - mean(current_trial(:, axis_number))) * 60, ...
        'LineWidth', 2)
    xline((params.trial_dur - params.pattern_dur) * (1/header.xstep), ...
        '--r', 'LineWidth', 1);
    hold off
    title(sprintf('Condition %02d, Participant %02d, Session 02, Trial %02d, Axis %d', ...
        condition, participant, trial, axis_number));
    xlabel('Time', 'fontweight', 'bold', ...
        'fontsize', 12);
    ylabel('Amplitude', 'fontweight', 'bold', ...
        'fontsize', 12);
    legend({'', 'Tracker', 'Step'});
    set(gca, 'TickDir', 'out');
    box off
    
    try
        subplot(2,1,2)
        plot(1)
        subplot(2,1,2)
        plot(asynch, '.-', ...
            'MarkerSize', 15)
        %     xline((length(asynch) - n_step_conti), '--', ...
        %         'Color', [0 0 0], 'LineWidth', 1);
        yline(0, '--r', 'LineWidth', 2)
        ylabel('Signed Asychrony', 'fontweight', 'bold', ...
            'fontsize', 12);
        xlabel('Data Point', 'fontweight', 'bold', ...
            'fontsize', 12);
        set(gca, 'TickDir', 'out');
        box off
    catch
        subplot(2,1,2)
        plot(1)
    end

    % Save plot
    path_plot = fullfile(params.path_output, '/plots/step/asynchrony/', ...
        sprintf('sub-%03d', participant));

    if ~isfolder(path_plot)
        mkdir(path_plot)
    end

    saveas(gcf, fullfile(path_plot, name_plot));

end

%% ---- EXPORT
% Save data
export_name_iri_error = ...
    sprintf('grp-%03d_cond-%03d_sub-%03d_axis-%d_iri_error_learning.csv', ...
    group, condition, participant, axis_number);
export_name_asynch = ...
    sprintf('grp-%03d_cond-%03d_sub-%03d_axis-%d_asynch_learning.csv', ...
    group, condition, participant, axis_number);
export_path_iri_error = fullfile(params.path_output, 'data/4_final/step/iri_error/'); 
export_path_asynch = fullfile(params.path_output, 'data/4_final/step/asynchrony/'); 

if ~isfolder(export_path_iri_error)
    mkdir(export_path_iri_error)
end

if ~isfolder(export_path_asynch)
    mkdir(export_path_asynch)
end

writetable(tbl_iri_error, fullfile(export_path_iri_error, export_name_iri_error));
writetable(tbl_asynch, fullfile(export_path_asynch, export_name_asynch));

% Save asynch structure
save(fullfile(export_path_asynch,'clap_asynch_ses-002.mat'),'Asynch')

% Close plot window
close all
