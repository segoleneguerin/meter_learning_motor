%
% Extract claps from microphone recordings for the pre/post sessions.
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
% Ségolène M. R. Guérin
% December 22, 2023
% RnB-Lab (Institute of Neuroscience, UCLouvain)
%

function meterlearning_motor_process_clap(participant)

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
tbl_iri_mean = cell2table(cell(0, 6), ...
    'VariableNames', {'group', 'condition', 'participant', 'session', ...
    'trial', 'mean_iri'});
tbl_iri_med = cell2table(cell(0, 6), ...
    'VariableNames', {'group', 'condition', 'participant', 'session', ...
    'trial', 'med_iri'});
tbl_iri_error = cell2table(cell(0, 8), ...
    'VariableNames', {'group', 'condition', 'participant', 'session', ...
    'trial', 'closest_match', 'error_closest_match_%', ...
    'error_from_median_%'});
tbl_time_series = cell2table(cell(0, 6), ...
    'VariableNames', {'group', 'condition', 'participant', 'session', ...
    'trial', 'onset_time'});

for session = [1 3]

    %% ----- LOAD DATA
    % Set path for the current participant
    raw_dir = fullfile(params.path_raw, ...
        sprintf('grp-%03d', group), ...
        sprintf('cond-%03d', condition), ...
        sprintf('sub-%03d', participant), ...
        sprintf('ses-%03d/', session), 'clap/');

    % List file in the current participant folder
    list_files = dir(fullfile(raw_dir));

    % Remove useless rows
    list_files([list_files.isdir]) = [];
    
    to_remove_idx = find(strcmp({list_files.name},'.DS_Store'));
    
    if ~isempty(to_remove_idx)
        list_files(to_remove_idx) = [];
    end

    for trial = 1:5

        % Indicate file name
        file_name = list_files(trial).name;

        % Load .mat data
        load(fullfile(raw_dir, file_name));

        %% ----- SEGMENT DATA
        % Normalise sound
        data_clap = rescale(tapData(1,:), -1, +1);

        % Remove baseline drift
        data_clap = data_clap - mean(data_clap);

        % Extract current trial (remove the first rhythmic pattern)
        trial_beg = round(params.pattern_dur * params.fs_stim);
        trial_end = round(params.trial_dur * params.fs_stim);
        data_clap = data_clap(trial_beg: trial_end)';
        data_sound = tapData(2, trial_beg: trial_end);

        % Save
        export_path = fullfile(params.path_output, 'data/2_segmented/', ...
            sprintf('grp-%03d/cond-%03d/sub-%03d/clap/', ...
            group, condition, participant)); 

        if ~isfolder(export_path)
            mkdir(export_path);
        end

        writetable(array2table(data_clap), fullfile(export_path, ...
            sprintf('grp-%03d_cond-%03d_sub-%03d_ses-%03d_trial-%02d_continuous.csv', ...
            group, condition, participant, session, trial)));


        %% ----- EXTRACT CLAPS
        % Find clap location (arbitrary threshold)
        min_pk_dist = params.fs_stim * 0.2; % 200 ms
        min_pk_prom = mean(data_clap) + (6 * std(data_clap));
        min_pk_height = 0.02;

        % Find peaks
        [peak_amp, locs] = findpeaks(data_clap, ...
            'MinPeakDistance', min_pk_dist, ... % in data point
            'MinPeakProminence', min_pk_prom, ...
            'MinPeakHeight', min_pk_height); % on either side of the signal

        % Convert peaks location from data points to seconds
        locs_sec = locs / params.fs_stim;

        %% ---- CHECK IF THE CLAP FINDING WAS CORRECTLY EXECUTED
        % Remove continuation
        time_vector = 1:length(data_clap);
        time_vector = time_vector / params.fs_stim;

        % Run tap corrector
        [locs_sec, peak_amp] = tap_corrector_smt(time_vector, params.fs_stim, data_clap, ...
            locs_sec, peak_amp, participant, group, condition);
        
        %% INTER-RESPONSE-INTERVALS
        
        % Interval between successive claps
        iri = round(diff(locs_sec),4);
        
        % Transform in table
        iri = array2table(iri, 'VariableNames', {'IRIs'});
        
        % Save
        export_name_iri = sprintf('grp-%03d_cond-%03d_sub-%03d_ses-%03d_trial-%02d_iri.csv', ...
                                   group, condition, participant, session, trial); 
        export_path_iri = fullfile(params.path_output, 'data/4_final/clap/iri/', ...
                                   sprintf('grp-%03d/cond-%03d/sub-%03d', ...
                                   group, condition, participant)); 

        if ~isfolder(export_path_iri)
            mkdir(export_path_iri);
        end
            
        writetable(iri, fullfile(export_path_iri, export_name_iri));
        
        %% ----- BUILD BINARY TIME SERIES
        % Create an empty matrix
        time_series = zeros(length(data_clap), 1);

        % Indicate where claps are located
        time_series(locs) = 1;

        % Add time
        time_series = ...
            [(1/params.fs_stim: ...
            (1/params.fs_stim): ...
            (length(data_clap)/params.fs_stim))', ...
            time_series];

        % Transform in table
        time_series = array2table(time_series, ...
            'VariableNames', {'time', 'ampl'});

        % Save
        export_path = fullfile(params.path_output, 'data/2_segmented/', ...
            sprintf('grp-%03d/cond-%03d/sub-%03d/clap/', ...
            group, condition, participant)); 

        writetable(time_series, fullfile(export_path, ...
            sprintf('grp-%03d_cond-%03d_sub-%03d_ses-%03d_trial-%02d_binary.csv', ...
            group, condition, participant, session, trial)));

        %% ----- COMPUTE NEAREST METER
        % Compute inter-response intervals
        iri = diff(locs_sec);

        % Compute mean and median IRIerror
        mean_iri = mean(iri);
        med_iri = median(iri);

        % Organise data
        new_row = [...
            repmat({group}, 1, 1), ... % group
            repmat({condition}, 1, 1), ... % condition
            repmat({participant}, 1, 1), ... % participant
            repmat({session}, 1, 1), ... % tempo
            repmat({trial}, 1, 1), ... % trial
            num2cell(mean_iri), ... % mean iri
            ];

        % Store
        tbl_iri_mean = [tbl_iri_mean; new_row];

        % Organise data
        new_row = [...
            repmat({group}, 1, 1), ... % group
            repmat({condition}, 1, 1), ... % condition
            repmat({participant}, 1, 1), ... % participant
            repmat({session}, 1, 1), ... % tempo
            repmat({trial}, 1, 1), ... % trial
            num2cell(med_iri), ... % median iri
            ];

        % Store
        tbl_iri_med = [tbl_iri_med; new_row];

        % Find the closest match with frequencies of interest
        freq_of_interest = [0.4 0.6 0.8];
        [~, idx] = min(abs(freq_of_interest - med_iri));
        closest_match  = freq_of_interest(idx);

        %% ---- COMPUTE IRI ERROR
        % Compute IRIerror in relation to closest-match
        error_closest_match = (abs(iri - closest_match) / ...
            closest_match) .* 100;

        % Compute IRIerror in relation to median IRI
        error_from_median = (abs(iri - med_iri) / med_iri) .* 100;

        % Organise data
        new_row = [...
            repmat({group}, 1, 1), ... % group
            repmat({condition}, 1, 1), ... % condition
            repmat({participant}, 1, 1), ... % participant
            repmat({session}, 1, 1), ... % tempo
            repmat({trial}, 1, 1), ... % trial
            num2cell(closest_match), ... % match
            num2cell(mean(error_closest_match)), ... % error from closest
            num2cell(mean(error_from_median)), ... % error from median
            ];

        % Store IRI error data
        tbl_iri_error = [tbl_iri_error; new_row];

        %% ---- STACKED PLOT
        % Create an empty matrix to store the data
        data2plot = zeros(12, params.n_patterns_per_trial - 1);

        % Set the increment pattern index
        pattern_idx = params.pattern_dur;

        for pattern = 1:(params.n_patterns_per_trial - 1)

            % Extract tap locations
            tap_loc = locs_sec(locs_sec > (pattern_idx - 2.4) ...
                & locs_sec < pattern_idx)';

            % Center pattern beginning to 0
            tap_loc = tap_loc - (pattern_idx - 2.4);

            % Store tap locations
            data2plot(1:length(tap_loc), pattern) = tap_loc;

            % Increment pattern index
            pattern_idx = pattern_idx + 2.4;

        end

        % Recreate sound pattern
        sound_pattern = [0; ones(199, 1);  zeros(200, 1); ...
            ones(200, 1);  zeros(200, 1);  ...
            ones(200, 1);  0; ones(199, 1);  ...
            zeros(200, 1);  ones(200, 1);  ...
            zeros(200, 1);  ones(200, 1);  ...
            zeros(200, 1);  ones(199, 1); 0];
        sound_pattern = sound_pattern * 16;

        % Build a time vector
        time = (1:2400)/1000';

        % Plot
        plot(time, sound_pattern, 'LineWidth', 2)
        hold on
        for pattern = 1:(params.n_patterns_per_trial - 1)
            plot(data2plot(find(data2plot(:, pattern)), pattern), ...
                repmat(pattern, ...
                size(find(data2plot(:, pattern)), 1), 1), ...
                '.', 'MarkerSize', 20)
        end
        rectangle('Position', [0, 0, 0.2, 16], 'FaceColor',[0 0.4470 0.7410, 0.2])
        rectangle('Position', [0.4, 0, 0.2, 16], 'FaceColor',[0 0.4470 0.7410, 0.2])
        rectangle('Position', [0.8, 0, 0.4, 16], 'FaceColor',[0 0.4470 0.7410, 0.2])
        rectangle('Position', [1.4, 0, 0.2, 16], 'FaceColor',[0 0.4470 0.7410, 0.2])
        rectangle('Position', [1.8, 0, 0.2, 16], 'FaceColor',[0 0.4470 0.7410, 0.2])
        rectangle('Position', [2.2, 0, 0.2, 16], 'FaceColor',[0 0.4470 0.7410, 0.2])
        hold off
        ylabel 'Pattern Number';
        xlabel 'Time (s)';
        title(sprintf(['Condition %02d, Participant %02d, Session %02d, ' ...
            'Trial %02d'], ...
            condition, participant, session, trial));
        box off

        % Save
        name_plot = sprintf(['grp-%03d_cond-%03d_sub-%03d_ses-%02d_' ...
            'trial-%02d.png'], ...
            group, condition, participant, session, trial);
        path_plot = fullfile(params.path_output, '/plots/clap/stacked_plots/', ...
            sprintf('sub-%03d', participant));

        if ~isfolder(path_plot)
            mkdir(path_plot);
        end

        saveas(gcf, fullfile(path_plot, name_plot));

        % Close plot
        close all

        %% ---- REGULAR PLOT
        subplot(2,1,1)
        plot(time_vector, data_clap, 'LineWidth', 1, ...
            'MarkerFaceColor', [0 0.4470 0.7410]);
        hold on
        scatter(locs_sec, peak_amp, 'filled');
        xlabel 'Time (s)';
        ylabel 'Sound Amplitude';
        title(sprintf('Condition %02d, Participant %02d, Session %02d, Trial %02d', ...
            condition, participant, session, trial));
        hold off
        box off

        
        subplot(2,1,2)
        plot(iri, '-o', 'LineWidth', 1, ...
            'MarkerFaceColor', [0 0.4470 0.7410])
        xlabel 'Data Point';
        ylabel 'Inter-Response Interval';
        axis([0 length(iri) 0.2 0.9])
        yline(0.6, '--', 'Triple', 'LineWidth', 2, ...
            'Color', [0.8500 0.3250 0.0980]);
        yline(0.4, '--', 'Duple', 'LineWidth', 2, ...
            'Color', [0.9290 0.6940 0.1250]);
        yline(0.8, '--', 'Duple', 'LineWidth', 2, ...
            'Color', [0.9290 0.6940 0.1250]);
        box off

        % Save plot
        name_plot = sprintf(['grp-%03d_cond-%03d_sub-%03d_ses-%03d_' ...
            'trial-%02d.png'], ...
            group, condition, participant, session, trial);
        path_plot = fullfile(params.path_output, '/plots/clap/iri_error/', ...
            sprintf('sub-%03d', participant));

        if ~isfolder(path_plot)
            mkdir(path_plot);
        end

        saveas(gcf, fullfile(path_plot, name_plot));

        % Close plot
        close all


    end

end

%% ---- EXPORT 
sessionName = '001-003';

% Indicate file names and paths
export_name_iri_error = ...
    sprintf('grp-%03d_cond-%03d_sub-%03d_ses-%s_iri_error.csv', group, condition, participant, sessionName);
export_name_med_iri = ...
    sprintf('grp-%03d_cond-%03d_sub-%03d_ses-%s_iri_median.csv', group, condition, participant, sessionName);
export_name_mean_iri = ...
    sprintf('grp-%03d_cond-%03d_sub-%03d_ses-%s_iri_mean.csv', group, condition, participant, sessionName);      
export_path_iri_error = fullfile(params.path_output, 'data/4_final/clap/iri_error/'); 
export_path_median = fullfile(params.path_output, 'data/4_final/clap/iri_median/'); 
export_path_mean = fullfile(params.path_output, 'data/4_final/clap/iri_mean/'); 

if ~isfolder(export_path_iri_error)
    mkdir(export_path_iri_error);
end

if ~isfolder(export_path_median)
    mkdir(export_path_median);
end

if ~isfolder(export_path_mean)
    mkdir(export_path_mean);
end

% Save data
writetable(tbl_iri_error, fullfile(export_path_iri_error, export_name_iri_error));
writetable(tbl_iri_med, fullfile(export_path_median, export_name_med_iri));
writetable(tbl_iri_mean, fullfile(export_path_mean, export_name_mean_iri));
