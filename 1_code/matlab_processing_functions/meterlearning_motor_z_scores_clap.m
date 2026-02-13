%
% Compute fast-Fourier transform and z scores on tapping data.
% 
% Parameters
% ----------
% participant: integral number
%   Participant to process.
% data_type: integral number
%   Type of data. 1 = continous and 2 = binary.
%
% Outputs 
% -------
% The outputs are saved as a .csv file.
%
% Author 
% -------
% Ségolène M. R. Guérin
% December 22, 2023
% RnB-Lab (Institute of Neuroscience, UCLouvain)
%

function meterlearning_motor_z_scores_clap(participant, data_type)
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
tbl_z_scores = cell2table(cell(0, 7), ...
    'VariableNames', {'group', 'condition', 'participant', 'session', 'metrical_interp' ...
    'zscore_freq_rel', 'norm_zscore_freq_rel'});
        
tbl_z_snr = cell2table(cell(0, 5), ...
    'VariableNames', {'group', 'condition', 'participant', 'session', 'z_snr'});

% Set path for the current participant
path_segmented = fullfile(params.path_output, 'data/2_segmented/', ...
    sprintf('grp-%03d/cond-%03d/sub-%03d/clap/', group, condition, participant));


for session = [1 3] % for the pre- and post-training sessions (1 & 3)
    
    %% ---- LOAD DATA
    % List files
    d = dir(path_segmented);

    % Remove useless rows
    d([d.isdir]) = [];

    % Indicate which file to read
    if data_type == 1
        data_type_name = 'continuous';
    elseif data_type == 2
        data_type_name = 'binary';
    end

    % Clear matrix
    to_remove = [];

    % Find rows that do not contrain data of interest
    for idx_d = 1:length(d)
        if isempty(strfind(d(idx_d).name, data_type_name))
            to_remove(idx_d) = idx_d;
        end
    end
    to_remove = find(to_remove);

    % Remove unrelevant rows
    d(to_remove)    = [];
    to_remove       = [];
    
    % Further remove hidden files (generated from MacOS)
    to_remove       = contains({d.name},'._grp');
    d(to_remove)    = [];
    to_remove       = [];
    
    to_remove = find(strcmp({d.name},'.DS_Store'));
    d(to_remove)    = [];
    to_remove       = [];

    % Indicate rows to read
    if session == 1
        d = d(1:5);
    elseif session == 3
        d = d(6:10);
    end

    for trial = 1:5

        % Load data
        data_temp = readtable(fullfile(path_segmented, d(trial).name));

        % Remove time column if needed
        if data_type == 2
            data_temp = data_temp(:, "ampl");
        end

        if trial == 1 || trial == 6
            data_all = data_temp;
            data_all.Properties.VariableNames = "trial_1";
        else 
            data_all = [data_all data_temp];
            data_all.Properties.VariableNames = ...
                [data_all.Properties.VariableNames(1:trial-1), ...
                sprintf("trial_%d", trial)];
        end

    end

    %% ---- AVERAGE TRIALS
    data_all.mean = mean(data_all{:,1:5}, 2);

    %% ---- COMPUTE FFT
    if data_type == 1
        data_all.mean = abs(hilbert(data_all.mean));
    end

    % Run the computation
    N = height(data_all);
    mX = abs(fft(data_all.mean)) / N;

    % Indicate max FFT freq value
    maxfreqidx_average = round(6 / params.fs_stim * N) + 1;

    % Resize FFT
    freq = (0 : maxfreqidx_average - 1) / N * params.fs_stim;
    mX(1) = 0;
    mX = mX(1 : maxfreqidx_average);

    %% ---- DENOISE SIGNAL
    mX_clean = zeros(size(mX, 1), 1);

    for bin = find(freq > 0.5, 1, 'first'):(size(freq, 2) - 5)

        % Compute average amplitude of neighbours (2 to 5)
        mean_neighbour_left = mean(mX(bin-5:bin-2, 1));
        mean_neighbour_right = mean(mX(bin+2:bin+5, 1));
        mean_neighbour = (mean_neighbour_left + ...
            mean_neighbour_right) / 2;

        mX_clean(bin, 1) = mX(bin, 1) - mean_neighbour;
    end
  
    %% ---- COMPUTE Z SNR
    % All frequencies
    [z_snr, mean_snip, idx_snip] = get_z_snr(mX', freq, ...
        [0.42, 0.83, 1.25, 1.67, 2.08, 2.5, 2.92, 3.33, 3.75, 4.17, 4.58, 5], ... % frex
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

    %% ---- PLOT Z SNR
    plot(mean_snip, '.-', 'MarkerSize', 15)
    xlabel 'Bin Number'
    ylabel 'Amplitude'
    hold on
    plot(11, mean_snip(11), 'r.', 'MarkerSize', 15)
    hold off

    % Save
    name_plot = sprintf('grp-%03d_cond-%03d_sub-%03d_ses-%03d_type-%s.png', ...
        group, condition, participant, session, data_type_name);
    path_plot = fullfile(params.path_plot, 'clap/z_snr/');

    if ~isfolder(path_plot)
        mkdir(path_plot)
    end

    saveas(gcf, fullfile(path_plot, name_plot));

    % Close plot window
    close all;

    %% ---- Z-SCORE COMPUTING
    % Define the frequency of interest
    freq_all = (0.416666666666667: 0.416666666666667: 5.01);
    freq_all = round(freq_all, 4);
    
    % run through the metrical interpretations 
    for metrical_interp = [2 23 3 32] 
        
        % Find position of frequencies
        freq_all_idx = [];
        for i_freq = 1:size(freq_all, 2)
            mask = round(freq(1,:), 4) == freq_all(i_freq);
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
        mean_freq = mean(mX_clean(freq_all_idx));
        sd_freq = std(mX_clean(freq_all_idx));

        % Compute z scores
        z_scores = zeros(length(mX_clean), 1);
        
        for bin = 1:length(mX_clean)
            z_scores(bin) = (mX_clean(bin) - mean_freq) / sd_freq;
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
        tbl_z_scores = [tbl_z_scores; new_row];        

    end
end

%% ---- EXPORT
% Write data  
export_name = sprintf('grp-%03d_cond-%03d_sub-%03d_type-%s_z-scores.csv', ...
    group, condition, participant, data_type_name);
export_path_z_score = fullfile(params.path_output, ...
    'data/4_final/clap/z_score/');
if ~isfolder(export_path_z_score)
    mkdir(export_path_z_score)
end
writetable(tbl_z_scores, fullfile(export_path_z_score, export_name));

export_name_z_snr = sprintf('grp-%03d_cond-%03d_sub-%03d_type-%s_z-snr.csv', ...
    group, condition, participant, data_type_name);
export_path_z_snr = fullfile(params.path_output, ...
    'data/4_final/clap/z_snr/');
if ~isfolder(export_path_z_snr)
    mkdir(export_path_z_snr)
end
writetable(tbl_z_snr, fullfile(export_path_z_snr, export_name_z_snr));