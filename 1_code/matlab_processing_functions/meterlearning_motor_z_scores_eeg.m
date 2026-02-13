%
% Compute fast-Fourier transform and z scores on EEG data.
% 
% Parameters
% ----------
% participant: integral number
%   Participant to process.
% ref_method: string
%   Method of channels re-referencencing. "mastoids" or "common-average"
% average_method: string
%   Method of channels averaging. "all" or "cluster".
%
% Outputs 
% -------
% The outputs are saved as .csv files.
% Plots are save as .png files.
%
% Author 
% -------
% Ségolène M. R. Guérin
% January 11, 2022
% RnB-Lab (Institute of Neuroscience, UCLouvain)
%

function meterlearning_motor_z_scores_eeg(participant, ref_method, average_method)

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
mX_all_channel = [];
mX_all_channel_clean = [];

tbl_z_scores_eeg = cell2table(cell(0, 7), ...
    'VariableNames', {'group', 'condition', 'participant', 'session', 'metrical_interp', ...
    'zscore_freq_rel', 'norm_zscore_freq_rel'});

tbl_z_snr = cell2table(cell(0, 5), ...
    'VariableNames', {'group', 'condition', 'participant', 'session', 'z_snr'});

% Add channel number is referencing is common average
if ref_method == "common-average"
    ref_method_chan = "common-average-chan-64";
else
    ref_method_chan = ref_method;
end

for session = [1 3]

    %% ---- DATA LOADING
    % Indicate data path and file name
    file_path = fullfile(params.path_output, 'data/3_preprocessed/', ...
        sprintf('grp-%03d', group), ...
        sprintf('cond-%03d', condition), ...
        sprintf('sub-%03d', participant), 'eeg/');
    
    
    file_name = sprintf(['grp-%03d_cond-%03d_sub-%03d_task-meterlearning-motor_session-%01d_' ...
                         'filtered_epoched_interp_cleaned-trials-ics_ref-%s.lw6'], ...
                         group, condition, participant, session, ref_method);

    % Load the data
    [header, data] = CLW_load(fullfile(file_path, file_name));

    %% ---- REMOVE BUFFFER
    % Segment
    [header, data] = RLW_segmentation(header, data, ...
        {'1'}, ...
        'x_start', params.pattern_dur, ...
        'x_duration', (params.trial_dur - params.pattern_dur));

    % Rename the header
    header.name = [header.name, '_segm'];

    %% ---- TRIAL AVERAGING
    % Average epoch
    [header, data] = RLW_average_epochs(header, data);

    % Rename the header
    header.name = [header.name, '_averaged'];

    % Export the data
    CLW_save(file_path, header, data);
    
    %% ---- FFT
    % Resize data to have a 2-D matrix
    data = squeeze(data);

    for channel = 1:size(data, 1)
        
        % Run the computation
        N = length(data(channel, :));
        mX_current = abs(fft(data(channel, :))) / N;

        % Indicate the maximal frequency value
        maxfreqidx = round(6 / params.fs * N) + 1; % stop at 6 Hz

        % Resize the FFT
        freq = (0 : maxfreqidx - 1) / N * params.fs;
        mX_current(1) = 0;
        mX_current = mX_current(1:maxfreqidx);

        % Store the FFT values for the current channel
        mX_all_channel(channel, :) = mX_current;

        % Create an empty matrice to store the data
        mX_current_clean = zeros(size(mX_current, 2), 1);

        % Clean the FFT
        for bin = find(freq > 0.5, 1, 'first'): ...
                (size(freq, 2) - 5)

            % Compute average amplitude of neighbours (2 to 5)
            mean_neighbour_left = mean(mX_current(bin-5:bin-2));
            mean_neighbour_right = mean(mX_current(bin+2:bin+5));
            mean_neighbour = (mean_neighbour_left + ...
                mean_neighbour_right) / 2;

            % Clean current bin
            mX_current_clean(bin) = mX_current(bin) - mean_neighbour;

        end

        % Store the cleaned FFT values for the current channel
        mX_all_channel_clean(channel, :) = mX_current_clean;

    end

    %% ---- EXPORT CLEANED FFT VALUES FOR TOPOPLOTS
    % Write FFT values
    export_name = sprintf('grp-%03d_cond-%03d_sub-%03d_ses-%03d_ref-%s_cleaned-fft-values-per-channel.csv', ...
        group, condition, participant, session, ref_method);
    writematrix(mX_all_channel_clean, fullfile(file_path, export_name));

    %% ---- AVERAGE CHANNELS
    if average_method == "all"

        mX_averaged = mean(mX_all_channel_clean, 1);
        mX_averaged_not_denoised = mean(mX_all_channel, 1); % for z snr computation

    elseif average_method == "cluster"
        
        % Indicate which channels to average
        cluster_chan = {'F1', 'Fz', 'F2', 'FC1', 'FCz', 'FC2', 'C1', 'Cz', 'C2'};

        % Find row number of channels to average
        mask = matches({header.chanlocs.labels}, cluster_chan);

        mX_averaged = mean(mX_all_channel_clean(mask, :), 1);
        mX_averaged_not_denoised = mean(mX_all_channel(mask, :), 1); % for z snr computation
    end

    %% ---- COMPUTE Z SNR
    % Indicate frequencies of interest
    freq_of_interest = [0.4167 0.8333 1.2500 1.6667 2.0833 ...
        2.5000 2.9167 3.3333 3.7500 4.1667 4.5833 5.0000];

    % Compute z snr
    [z_snr, mean_snip, idx_snip] = get_z_snr(mX_averaged_not_denoised, freq, ...
        freq_of_interest(2:11), ... % frex
        1, ... % bin_from
        10); % bin_to

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
    
    fprintf('grp-%03d, cond-%03d, sub-%03d, ses-%03d: snr = %.3f \n', group, condition, participant, session, z_snr)

    %%  ---- PLOT Z SNR
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
    name_plot = sprintf('grp-%03d_cond-%03d_sub-%03d_ses-%03d_ref-%s_average-%s.svg', ...
        group, condition, participant, session, ref_method, average_method);

    path_plot = fullfile(params.path_plot, 'eeg/z_snr/spectral_analysis/');

    if ~isfolder(path_plot)
        mkdir(path_plot)
    end

    saveas(gcf, fullfile(path_plot, name_plot));

    % Close plot window
    close();

    %% ---- COMPUTE Z SCORES
    % Define the frequency of interest
    freq_all = (0.416666420619319: 0.416666420619319: 5);
    freq_all = round(freq_all, 3);

    % run through the metrical interpretations 
    for metrical_interp = [2 23 3 32] 
        
        % Find position of frequencies
        freq_all_idx = [];
        for i_freq = 1:size(freq_all, 2)

            mask = round(freq(1,:), 3) == freq_all(i_freq);
            new_idx = find(mask);
            freq_all_idx = [freq_all_idx new_idx];
        end 
        
        % Check that the two matrices have the same size
        assert(length(freq_all) == length(freq_all_idx), ...
            'Warning: frequency and frequency index matrices do not match.')        
 
        % Extract meter-related frequencies
        if metrical_interp == 2 % 3-beat 
            idx = [3 9];
        elseif metrical_interp == 23 % 3-beat  with three meter-related frequencies (including the 2.5Hz)
            idx = [3 6 9];
        elseif metrical_interp == 3 % 4-beat
            idx = [2 4 8 10];
        elseif metrical_interp == 32 % 4-beat with two meter-related frequencies
            idx = [4 8];               
        end 
        
        freq_rel = freq_all(idx); 
        freq_rel_idx = freq_all_idx(idx);

        % Remove the first and last frequency
        freq_all_idx = freq_all_idx(2:(end-1));

        % Compute mean and standard deviation
        mean_freq = mean(mX_averaged(freq_all_idx));
        sd_freq = std(mX_averaged(freq_all_idx));
        
        % Compute z scores
        z_scores = zeros(size(mX_averaged, 2), 1);
        for bin = 1:size(mX_averaged, 2)
            z_scores(bin) = (mX_averaged(bin) - mean_freq) / sd_freq;
        end

        % Averaging
        mean_freq_rel = mean(z_scores(freq_rel_idx));        
        
        % Normalize the meter-related zscore between -1 and 1.
        % The extreme z_values correspond to the computation below
        % 2 metre-related frequencies
        % magnitudes = [1e20, 1e20, 0, 0, 0, 0, 0, 0, 0, 0];
        % ans = zscore(magnitudes)            
        % 4 metre-related frequencies
        % magnitudes = [1e20, 1e20, 1e20, 1e20, 0, 0, 0, 0, 0, 0];
        % ans = zscore(magnitudes)                
        if metrical_interp == 3
            extreme_z = 1.161895003862225;
        elseif metrical_interp == 23
            extreme_z = 1.449137674618944;
        else
            extreme_z = 1.897366596101027;
        end
        norm_z = normalize([mean_freq_rel, -extreme_z, extreme_z], 'range', [-1 1]);
        norm_mean_freq_rel = norm_z(1);   
        
        % Organise data
        new_row = [...
            repmat({group}, 1, 1), ...              % group
            repmat({condition}, 1, 1), ...          % condition
            repmat({participant}, 1, 1), ...        % participant
            repmat({session}, 1, 1), ...            % session
            repmat({metrical_interp}, 1, 1), ...    % metrical interpretation
            num2cell(mean_freq_rel), ...            % mean meter related zscore
            num2cell(norm_mean_freq_rel)];          % normalised mean met_rel zscore  
    
        % Store in a matrix
        tbl_z_scores_eeg = [tbl_z_scores_eeg; new_row];                    
    end

    %% ---- CLEAR VARIABLES
    clear data mX_all_channel mX_averaged ...
        mX_averaged_not_denoised freq_all mX_all_channel_clean

end

% Write frequency values
export_name = sprintf('grp-%03d_cond-%03d_sub-%03d_freq-values.csv', ...
    group, condition, participant);
writematrix(freq, fullfile(file_path, export_name));
    
%% ---- SAVE
% Write z-score data  
export_name = sprintf('grp-%03d_cond-%03d_sub-%03d_ref-%s_average-%s_z-scores.csv', ...
    group, condition, participant, ref_method, average_method);

export_path_z_score = fullfile(params.path_output, 'data/4_final/eeg/z_score_fft/');

if ~isfolder(export_path_z_score)
    mkdir(export_path_z_score)
end
writetable(tbl_z_scores_eeg, fullfile(export_path_z_score, export_name));

% Write z-snr data  
export_name = sprintf('grp-%03d_cond-%03d_sub-%03d_ref-%s_average-%s_z-snr.csv', ...
    group, condition, participant, ref_method, average_method);
export_path_z_snr = fullfile(params.path_output, ...
    'data/4_final/eeg/z_snr/');

if ~isfolder(export_path_z_snr)
    mkdir(export_path_z_snr)
end
writetable(tbl_z_snr, fullfile(export_path_z_snr, export_name));
