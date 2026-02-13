%
% Interpolate bad channels.
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
% Modified by Ségolène M. R. Guérin (August 13, 2024)
% RnB-Lab (Institute of Neuroscience, UCLouvain)
%

function meterlearning_motor_interpolate_bads(participant)

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

% Indicate file name
file_name = fullfile(params.path_output, '/checks/', 'bad_chans.xlsx'); 

% Load bad channels table
tbl_bads = readtable(file_name); 

% Extract bad channels for the current participant
bads = tbl_bads{tbl_bads.participant == participant & ...
                tbl_bads.group == group & ...
                tbl_bads.condition == condition, 'bad_chans'};
bads = strrep(bads{1}, ' ', '');
bads = strsplit(bads, ',');

% Indicate participant folder
file_path = fullfile(params.path_output, 'data/2_segmented/', ...
        sprintf('grp-%03d', group), ...
        sprintf('cond-%03d', condition), ...
        sprintf('sub-%03d', participant), 'eeg/');

for session = [1 3]

    % Indicate participant file name
    file_name = ...
        sprintf('grp-%03d_cond-%03d_sub-%03d_task-meterlearning-motor_session-%01d_filtered_epoched.lw6', ...
        group, condition, participant, session);

    % Load participant data
    [header, data] = CLW_load(fullfile(file_path, file_name)); 
    
    %% ---- INTERPOLATE BAD CHANNELS
    if all(~cellfun(@isempty, bads))
        
        % Create a mask with good-channel positions
        good_chans_mask = cellfun(@(x) ~any(strcmpi(x, bads)), ...
                            {header.chanlocs.labels}); 

        % Extract good channel information
        good_chans = header.chanlocs(good_chans_mask); 

        for i_bad = 1:length(bads)

            % Create a mask with the current bad channel position
            bad_chan_mask = strcmpi({header.chanlocs.labels}, bads{i_bad});
            
            % Extract the bad channel information
            bad_chan = header.chanlocs(bad_chan_mask); 

            % Create an empty matrix
            dist = nan(1, length(good_chans));        

            % Compute distance between the bad channel and all other channels
            for i = 1:length(good_chans)
                dist(i) = sqrt((good_chans(i).X - bad_chan.X)^2 ...
                    + (good_chans(i).Y - bad_chan.Y)^2 ...
                    + (good_chans(i).Z - bad_chan.Z)^2);
            end

            % List in ascending order according to position
            [~, idx_closest] = sort(dist);

            % Find the closest three channels
            closest_channels = good_chans(idx_closest(1 : params.n_chan_interp));

            % Assert if any of the closest channels are within the bad channel list
            closest_match_bad_mask = cellfun(@(x) any(strcmpi(x, bads)),...
                {closest_channels.labels});
            
            if any(closest_match_bad_mask)
                error(['Interpolating channel %s: closest channel %s overlaps with ' ...
                    'another bad channel...'], ...
                    bad_chan.labels, closest_channels(closest_match_bad_mask).labels);
            end
            
            % Print interpolation resume
            tmp = join({closest_channels.labels}, ' ');
            fprintf('Interpolating channel %s with average of %s\n', ...
                bad_chan.labels,  tmp{1});
            
            % Interpolate
            [header, data] = RLW_interpolate_channel(header, data, ...
                bad_chan.labels, {closest_channels.labels});
            
        end
        
    end
    
    %% ---- EXPORT
    % Change header name
    header.name = sprintf('%s_interp', header.name); 

    % Indicate export folder
    export_path = fullfile(params.path_output, 'data/3_preprocessed/', ...
        sprintf('grp-%03d', group), ...
        sprintf('cond-%03d', condition), ...
        sprintf('sub-%03d', participant), 'eeg/');

    if ~isfolder(export_path)
        mkdir(export_path)
    end
    
    % Save data
    CLW_save(export_path, header, data);     
    
end