%
% Format file names.
% 
% Parameters
% ----------
% participant: integral number
%   Participant to process.
% group: integral number
%   Experimental group. 1 = African and 2 = Western.
% condition: integral number
%   Experimental condition. 2 = three-beat metre and 3 = four-beat metre.
%
% Outputs
% -------
% The outputs are saved in a similar format as the inputs.
%
% Authors
% -------
% Tomas Lenc
% Modified by Ségolène M. R. Guérin (April 16, 2024)
% RnB-Lab (Institute of Neuroscience, UCLouvain)
%

function meterlearning_motor_source_to_raw(participant)

%% ---- PREAMBLE
% Load parameters file
params = meterlearning_motor_get_params(); 

% Create an empty object
to_remove = [];

% Load participants allocation file
alloc_file = readtable(fullfile(params.experiment_path, ...
    '0_data/meterlearning-motor_participant_allocation.xlsx')); 

% Extract group and condition
group = table2array(alloc_file(participant, 2));
condition = table2array(alloc_file(participant, 3));

for session = 1:3
    %% ---- EEG
    % Indicate participant source folder
    source_dir = fullfile(params.path_source, ...
        sprintf('grp-%03d', group), ...
        sprintf('cond-%03d', condition), ...
        sprintf('sub-%03d', participant), ...
        sprintf('ses-%03d', session), 'eeg/');

    % List files
    d = dir(source_dir);

    % Remove useless rows
    d([d.isdir]) = [];

    % Find rows that do not contrain data of interest
    for idx_d = 1:length(d)
        if isempty(strfind(d(idx_d).name, 'sub'))
            to_remove(idx_d) = idx_d;
        end
    end
    to_remove = find(to_remove);

    % Remove unrelevant rows
    d(to_remove) = [];

    % Clear matrix
    to_remove = [];

    % Indicate participant raw folder
    raw_dir = fullfile(params.path_raw, ...
        sprintf('grp-%03d', group), ...
        sprintf('cond-%03d', condition), ...
        sprintf('sub-%03d', participant), ...
        sprintf('ses-%03d', session), 'eeg');

    % Create a folder if not existing
    if ~isfolder(raw_dir)
        mkdir(raw_dir);
    end
                  
    % Rename file
    for i_file = 1:length(d)

        fname_old = d(i_file).name;

        fname_new = fname_old;

        [~, fname_new] = regexp(fname_new, '_date-\d+', 'match', 'split');
        fname_new = join(fname_new, '');
        fname_new = fname_new{1};

        [~, fname_new] = regexp(fname_new, '_run-\d+', 'match', 'split');
        fname_new = join(fname_new, '');
        fname_new = fname_new{1};

        % If errors in nomenclature
        if fname_new(8) == '-'
            fname_new = replaceBetween(fname_new, 8, 8, "_");
        end

        if fname_new(44) == '_'
            fname_new = replaceBetween(fname_new, 44, 44, "-");
        end

        copyfile(fullfile(source_dir, fname_old), ...
            fullfile(raw_dir, fname_new));

    end
    
    %% ---- AUDIO
    % Indicate participant source folder
    source_dir = fullfile(params.path_source, ...
        sprintf('grp-%03d', group), ...
        sprintf('cond-%03d', condition), ...
        sprintf('sub-%03d', participant), ...
        sprintf('ses-%03d', session));

    % List files
    d = dir(source_dir);

    % Remove useless rows
    d([d.isdir]) = [];

    % Find rows that do not contrain data of interest
    for idx_d = 1:length(d)
        if isempty(strfind(d(idx_d).name, 'audio_recording'))
            to_remove(idx_d) = idx_d;
        end
    end
    to_remove = find(to_remove);

    % Remove unrelevant rows
    d(to_remove) = [];

    % Clear matrix
    to_remove = [];
   
    % Special case for sub-046 (mess in repeting trials)
    if participant == 46 && session == 2
        d = d(2:end);
    end
    
    if participant == 98 && session == 1
        d = d(3:end);
        
    elseif participant == 98 && session == 3
        d = d(2:end);
    end
    
    % Indicate participant raw folder
    raw_dir = fullfile(params.path_raw, ...
        sprintf('grp-%03d', group), ...
        sprintf('cond-%03d', condition), ...
        sprintf('sub-%03d', participant), ...
        sprintf('ses-%03d', session), 'clap');

    % Create a folder if not existing
    if ~isfolder(raw_dir)
        mkdir(raw_dir);
    end

    % Rename file
    for i_file = 1:length(d)

        fname_old = d(i_file).name;

        fname_new = fname_old;

        [~, fname_new] = regexp(fname_new, '_date-\d+', 'match', 'split');
        fname_new = join(fname_new, '');
        fname_new = fname_new{1};

        [~, fname_new] = regexp(fname_new, '_run-\d+', 'match', 'split');
        fname_new = join(fname_new, '');
        fname_new = fname_new{1};

        [~, fname_new] = regexp(fname_new, '_event-\d+', 'match', 'split');
        fname_new = join(fname_new, '');
        fname_new = fname_new{1};

        % Special case for sub-046 (mess in repeting trials)
        if participant == 46 && session == 2
            fname_new = replaceBetween(fname_new, 65, 67, sprintf('%03d', i_file));
        end
        

        copyfile(fullfile(source_dir, fname_old), ...
            fullfile(raw_dir, fname_new));

    end

end