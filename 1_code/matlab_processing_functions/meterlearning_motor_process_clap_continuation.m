%
% Extract claps from microphone recordings for the learning_continuation session.
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
% Author
% -------
% Ségolène M. R. Guérin, adapted by E. Coulon
% June 10, 2024
% RnB-Lab (Institute of Neuroscience, UCLouvain)
%

function meterlearning_motor_process_clap_continuation(participant)

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
session = 2;

% Create an empty matrix to store the data
tbl_iri_error = cell2table(cell(0, 7), ...
    'VariableNames', {'group', 'condition', 'participant', 'session', ...
    'trial', 'mean_iri', 'iri_error'});
tbl_asynch = cell2table(cell(0, 8), ...
    'VariableNames', {'group', 'condition', 'participant', 'session', ...
    'trial', 'signed_asynchrony','std_asynch','r_asynch'}); 

% load asynchrony structure
path_asynch = fullfile(params.path_output, 'data/4_final/clap/asynchrony/'); 
if isfile(fullfile(path_asynch,'clap_asynch_ses-002_continuation.mat'))
    load(fullfile(path_asynch,'clap_asynch_ses-002_continuation.mat'))
end
    

%% ----- DATA LOADING
% Set path for the current participant
raw_dir = fullfile(params.path_raw, ...
    sprintf('grp-%03d', group), ...
    sprintf('cond-%03d', condition), ...
    sprintf('sub-%03d', participant), ...
    'ses-002/', 'clap/');

% List file in the current participant folder
list_files = dir(fullfile(raw_dir));

% Remove useless rows
list_files([list_files.isdir]) = [];

for trial = 1:params.nb_trial
    
    % Indicate file name
    file_name = list_files(trial).name;

    % Load .mat data
    load(fullfile(raw_dir, file_name));
    
    %% ----- PREPARE DATA
    % Normalise sound
    data_clap = rescale(tapData(1,:), -1, +1);

    % Remove baseline drift
    data_clap = data_clap - mean(data_clap);

    % Extract current continuation snippet
    buffer = 0.2; % take 
    trial_beg  = round((params.trial_dur  - buffer) * params.fs_stim); % start from 200ms before the end of the learning trial to include the first clap of the continuation task
    trial_end  = round((params.trial_dur + params.trial_dur_conti + buffer) * params.fs_stim) - 1;
    data_clap  = data_clap(trial_beg: trial_end)';
    data_sound = tapData(2, trial_beg: trial_end);  
    
    %% ----- AVERAGE CHUNKS
    % Compute pattern duration in time point
    time_point_pattern = 2.4 * params.fs_stim;
    
    % Create an empty matrix to store the data
    data_chunks = zeros(time_point_pattern, params.n_patterns_conti);

    % Segment the data by chunks
    for chunk = 1:params.n_patterns_conti
       
        % Compute beginning point
        conti_beg = buffer * params.fs_stim;
        beg_chunk = conti_beg +((chunk * time_point_pattern) - time_point_pattern) + 1;

        % Extract current chunks
        data_chunks(:, chunk) = data_clap(beg_chunk : ...
            ((beg_chunk + time_point_pattern) - 1));
    end
    
    % Build a time vector
    time_vector = 1:time_point_pattern;
    time_vector = time_vector / params.fs_stim;    
    
    % Plot
    subplot(2,1,1);
    for chunk = 1:params.n_patterns_conti
        plot(time_vector, data_chunks(:, chunk), 'LineWidth', 2); hold on
    end
    hold off
    title(sprintf('Condition %02d, Participant %02d, Session 02, Trial %02d', ...
            condition, participant, trial));
    xlabel('Time (s)', 'fontweight', 'bold', ...
        'fontsize', 12);
    ylabel('Sound Amplitude', 'fontweight', 'bold', ...
        'fontsize', 12);
    box off
    set(gca, 'TickDir', 'out');

    subplot(2,1,2);
    plot(time_vector, mean(data_chunks, 2), 'k', 'LineWidth', 2)
    box off
    xlabel('Time (s)', 'fontweight', 'bold', ...
        'fontsize', 12);
    ylabel('Sound Amplitude', 'fontweight', 'bold', ...
        'fontsize', 12);
    set(gca, 'TickDir', 'out');
    legend('Average')

    % Save
    name_plot = sprintf(['grp-%03d_cond-%03d_sub-%03d_ses-002_' ...
            'trial-%02d.png'], ...
            group, condition, participant, trial);
    path_plot = fullfile(params.path_output, '/plots/clap_continuation/chunks/', ...
        sprintf('sub-%03d', participant));

    if ~isfolder(path_plot)
        mkdir(path_plot)
    end

    saveas(gcf, fullfile(path_plot, name_plot));
    
    %% ----- EXTRACT CLAPS
    % Find clap location (arbitrary threshold)
    if condition == 2
        min_pk_dist = params.fs_stim * 0.3; % 300 ms for duple
    elseif condition == 3
        min_pk_dist = params.fs_stim * 0.2; % 200 ms for triple
    end
    min_pk_prom = mean(data_clap) + (6 * std(data_clap));
    min_pk_height = 0.02;

    % Find peaks
    [peak_amp, locs] = findpeaks(data_clap, ...
        'MinPeakDistance', min_pk_dist, ... % in data point
        'MinPeakProminence', min_pk_prom, ...
        'MinPeakHeight', min_pk_height); % on either side of the signal

    % Convert peaks location from data points to seconds
    locs_sec = locs / params.fs_stim;   

    
    %% ---- RECREATE TRACKER SOUND PATTERN
    % Recreate tracker sound pattern (with the initial and end buffers)
    if condition == 2
        tracker_position = [1, round(0.8 * params.fs_stim) + 1, ...
            round(1.6 * params.fs_stim) + 1]; % duple
    elseif condition == 3
        tracker_position = [1, round(0.6 * params.fs_stim) + 1, ...
            round(1.2 * params.fs_stim) + 1, round(1.8 * params.fs_stim) + 1]; % triple
    end

    tracker = zeros(1, round(2.4 * params.fs_stim));
    tracker(tracker_position) = 1;
    tracker = repmat(tracker, 1, params.n_patterns_conti); 
    tracker = [zeros(1,round(buffer * params.fs_stim)), ...
               tracker, ...
               ones(1,1), ...
               zeros(1,round(buffer * params.fs_stim)-1)];
        
    % Find metronome tracker location
    locs_sound = find(tracker);

    % Convert peaks location from data points to seconds
    locs_sound_sec = locs_sound / params.fs_stim;  
    
    % Find sound location for the first step
    [~, idx_min] = min(abs(locs_sec(1)-locs_sound_sec));

    % Resize sound matrix
    locs_sound_sec = locs_sound_sec(idx_min:length(locs_sound_sec))';

    %% ---- CHECK IF THE CLAP FINDING WAS CORRECTLY EXECUTED
    % time vector for the continuation snippet
    time_vector = 1:length(data_clap);
    time_vector = time_vector / params.fs_stim;
    final_length = time_vector(end);

    % Run tap corrector
    [locs_sec, peak_amp] = tap_corrector(time_vector, params.fs_stim, tracker, data_clap, ...
        locs_sec, peak_amp, final_length , participant, group, condition, trial);

    % If the sound and clap matrices have not the same length
    if length(locs_sound_sec) ~= length(locs_sec)
        waitfor(msgbox("Warning: the sound and clap matrices have not the same length, please double check for any missing/extra clap."))
        [locs_sec, peak_amp] = tap_corrector(time_vector, params.fs_stim, tracker, data_clap, ...
            locs_sec, peak_amp, final_length, participant, group, condition, trial);
    end  
    
    %% ---- IN CASE THE SOUND AND STEP MATRICES HAVE NOT THE SAME LENGTH
    if length(locs_sound_sec) ~= length(locs_sec)
        
        % Match clap with closest sound
        for clap = 1:length(locs_sec)
            [~, idx_check(clap)] = ...
                min(abs(locs_sec(clap)-locs_sound_sec));
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
        for clap = 1:length(locs_sec)
            [~, idx_check(clap)] = ...
                min(abs(locs_sec(clap)-locs_sound_sec));
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

                % Find the farthest sound to the clap
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

                % Find the closest sound to the clap
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
            
            % If ONE additionnal clap
            if idx_check_diff(to_remove - 1) == 0

                % Add an additional sound
                locs_sound_sec = [locs_sound_sec(1:to_remove - 1); ...
                    locs_sound_sec(to_remove - 1) + 0.0001; ... % add a tiny bit of time 
                    % so idx_check match claps with the right sound
                    locs_sound_sec(to_remove:end)];
            end
            
            % Remove rows with NaN
            locs_sound_sec(any(isnan(locs_sound_sec), 2), :) = [];

            % Match clap with closest sound
            for clap = 1:length(locs_sec)
                [~, idx_check(clap)] = ...
                    min(abs(locs_sec(clap)-locs_sound_sec));
            end

            % Find which sound numbers are not matching steps
            idx_check_diff = diff(idx_check);            
        end
        
        % If additionnal sounds AFTER the last synchro clap
        if length(locs_sound_sec) > length(locs_sec)

            % Remove additional claps at the end
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
        asynch      = NaN;
        mean_asynch = NaN;        
        std_asynch  = NaN;
        r_asynch    = NaN;
        
    else
        asynch      = locs_sec - locs_sound_sec;
        mean_asynch = mean(asynch);
        std_asynch  = std(asynch);
        r_asynch    = meterlearning_motor_asynch_vector_strength(participant, asynch, locs_sound_sec);
    end
    
    % Organise data
    new_row = [...
        repmat({group}, 1, 1), ...      % group
        repmat({condition}, 1, 1), ...  % condition
        repmat({participant}, 1, 1), ... % participant
        repmat({2}, 1, 1), ...          % session
        repmat({trial}, 1, 1), ...      % trial
        num2cell(mean_asynch), ...      % asynchrony
        num2cell(std_asynch), ...       % std of the asynchrony
        num2cell(r_asynch)];            % vector strength of the asynchrony 

    
    % Store data
    tbl_asynch = [tbl_asynch; new_row];
    
    grp_name    = sprintf('grp%03d',group);
    cond_name   = sprintf('cond%03d',condition);
    sub_name    = sprintf('sub%03d',participant);
    trial_name  = sprintf('trial%i',trial);
    
    struct_asynch_conti.(grp_name).(cond_name).(sub_name).(trial_name) = asynch;
    
    %% ---- COMPUTE IRI ERROR
    % Compute inter-response intervals
    iri = diff(locs_sec);

    % Compute absolute IRIerror
    if condition == 2
        iri_error = (abs(iri - 0.800) / 0.800) .* 100 ; % duple
    elseif condition == 3
        iri_error = (abs(iri - 0.600) / 0.600) .* 100 ; % triple
    end

    
    % Compute mean IRIerror
    mean_iri        = mean(iri);
    mean_iri_error  = mean(iri_error);

    % Organise data
    new_row = [...
        repmat({group}, 1, 1), ...      % group
        repmat({condition}, 1, 1), ...  % condition
        repmat({participant}, 1, 1), ... % participant
        repmat({2}, 1, 1), ...          % session
        repmat({trial}, 1, 1), ...      % trial
        num2cell(mean_iri), ...         % mean iri
        num2cell(mean_iri_error) ...    % mean iri error
        ];

    % Store data
    tbl_iri_error = [tbl_iri_error; new_row];

    %% ---- PLOT
    % Plot iri error
    subplot(2,1,1);
    plot(time_vector, data_clap, 'LineWidth', 1, ...
        'MarkerFaceColor', [0 0.4470 0.7410]);
    hold on
    scatter(locs_sec, peak_amp, 'filled');
    title(sprintf('Condition %02d, Participant %02d, Session 02, Trial %02d', ...
        condition, participant, trial));
    xlabel('Time', 'fontweight', 'bold', ...
        'fontsize', 12);
    ylabel('Sound Amplitude', 'fontweight', 'bold', ...
        'fontsize', 12);
    set(gca, 'TickDir', 'out');
    hold off
    box off
    grid off

    subplot(2,1,2);
    plot(iri_error, '.-', ...
        'MarkerSize', 15);
    %     xline((length(iri_error) - (n_clap_conti)), '--', ...
    %         'Color', [0 0 0], 'LineWidth', 1);
    yline(15, '--r', 'Threshold', 'LineWidth', 2);
    text(22, 13, strcat('mean =', {' '}, num2str(mean(iri_error))));
    xlabel('Data Point', 'fontweight', 'bold', ...
        'fontsize', 12);
    ylabel('IRI error (%)', 'fontweight', 'bold', ...
        'fontsize', 12);
    set(gca, 'TickDir', 'out');
    box off

    % Save plot
    name_plot = sprintf(['grp-%03d_cond-%03d_sub-%03d_ses-002_' ...
        'trial-%02d.png'], ...
        group, condition, participant, trial);
    path_plot = fullfile(params.path_output, '/plots/clap_continuation/iri_error/', ...
        sprintf('sub-%03d', participant));

    if ~isfolder(path_plot)
        mkdir(path_plot)
    end

    saveas(gcf, fullfile(path_plot, name_plot));


    % Plot asynchrony
    subplot(2,1,1);
    plot(data_sound, 'Color', [0 0.4470 0.7410 0.05])
    hold on
    plot(tracker, ...
        'LineWidth', 2)
    plot(data_clap, 'LineWidth', 2)
    hold off
    title(sprintf('Condition %02d, Participant %02d, Session 02, Trial %02d', ...
        condition, participant, trial));
    xlabel('Time', 'fontweight', 'bold', ...
        'fontsize', 12);
    ylabel('Amplitude', 'fontweight', 'bold', ...
        'fontsize', 12);
    set(gca, 'TickDir', 'out');
    box off
    legend({'', 'Tracker', 'Clap', ''});


    subplot(2,1,2)
    if ~exist('asynch')
        subplot(2,1,2)
        plot(1)
    else
        plot(asynch, '.-', ...
            'MarkerSize', 15)
        yline(0, '--r', 'LineWidth', 2)
        xlabel('Data Point', 'fontweight', 'bold', ...
            'fontsize', 12);
        ylabel('Signed Asychrony', 'fontweight', 'bold', ...
            'fontsize', 12);
        set(gca, 'TickDir', 'out');
        box off
    end

    % Save plot
    path_plot = fullfile(params.path_output, '/plots/clap_continuation/asynchrony/', ...
        sprintf('sub-%03d', participant));

    if ~isfolder(path_plot)
        mkdir(path_plot)
    end

    saveas(gcf, fullfile(path_plot, name_plot));
end

%% ---- EXPORT    
% Save data
export_name_iri_error = ...
    sprintf('grp-%03d_cond-%03d_sub-%03d_ses-%03d_iri_error_continuation.csv', group, condition, participant, session);
export_name_asynch = ...
    sprintf('grp-%03d_cond-%03d_sub-%03d_ses-%03d_asynch_continuation.csv', group, condition, participant, session);
export_path_iri_error = fullfile(params.path_output, 'data/4_final/clap/iri_error/'); 
export_path_asynch = fullfile(params.path_output, 'data/4_final/clap/asynchrony/'); 

if ~isfolder(export_path_iri_error)
    mkdir(export_path_iri_error)
end

if ~isfolder(export_path_asynch)
    mkdir(export_path_asynch)
end

writetable(tbl_iri_error, fullfile(export_path_iri_error, export_name_iri_error));
writetable(tbl_asynch, fullfile(export_path_asynch, export_name_asynch));

% save asynch structure
save(fullfile(export_path_asynch,'clap_asynch_ses-002_continuation.mat'),'struct_asynch_conti')

% Close plot window
close all

end

