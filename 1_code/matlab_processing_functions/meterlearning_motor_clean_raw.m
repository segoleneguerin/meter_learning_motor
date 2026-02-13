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
% The output are saved as LetsWave and Matlab files.
%
% Authors
% -------
% Tomas Lenc
% Modified by Ségolène M. R. Guérin (April 16, 2024)
% RnB-Lab (Institute of Neuroscience, UCLouvain)
%

function meterlearning_motor_clean_raw(participant)

%% ---- PREAMBLE
% Load parameters file
params = meterlearning_motor_get_params();

% Load LetsWave 6
import_lw(6); 

% Load participants allocation file
alloc_file = readtable(fullfile(params.experiment_path, ...
    '0_data/meterlearning-motor_participant_allocation.xlsx')); 

% Extract group and condition
group = table2array(alloc_file(participant, 2));
condition = table2array(alloc_file(participant, 3));

for session = 1:3

    % Indicate participant raw folder
    raw_dir = fullfile(params.path_raw, ...
        sprintf('grp-%03d', group), ...
        sprintf('cond-%03d', condition), ...
        sprintf('sub-%03d', participant), ...
        sprintf('ses-%03d', session), 'eeg/');

    % Indicate participant file name
    fname = ...
        sprintf('grp-%03d_cond-%03d_sub-%03d_task-meterlearning-motor_session-%d.bdf', ...
        group, condition, participant, session);

    % Load participant data file
    [header, data] = RLW_import_BDF(fullfile(raw_dir, fname));

    %% FOR SESSIONS 1 & 3
    if session == 1 || session == 3
        %% ---- CHANNELS
        % Load external channel location
        chan_labels = readtable('chan_labels.csv');

        % External channels for sub-074 to sub-078
        if participant > 73 && participant < 79

            % Add aditionnal electrode label
            new_rows = [{'EXG3'}, {'Fp1'}; {'EXG4'}, {'Fpz'}];

            % Store
            chan_labels = [; chan_labels([2:32,34:size(chan_labels, 1)], :); new_rows];

        end

        % Extract file channel location
        chanlocs = header.chanlocs;

        % Rename channels to have 10-20 nomenclature
        for i_chan=1:length(chanlocs)

            old_lab = chanlocs(i_chan).labels;

            idx = find(strcmpi(old_lab, chan_labels.old));

            if length(idx) == 1
                chanlocs(i_chan).labels = chan_labels.new{idx};
            end

        end

        header.chanlocs = chanlocs;

        % Only keep relevant channels (EEG,  AIB and sound)
        chans_to_keep = [chan_labels.new; {'Erg1'; 'Erg2'; 'Ana8'}];
        [header, data] = RLW_arrange_channels(header, data, chans_to_keep);

        % Edit electrode coordinates
        loc_file_path = fullfile(params.letswave6_path, ...
            'core_functions', ...
            'Standard-10-20-Cap81.locs');

        locs = readlocs(loc_file_path);

        for i_chan=1:length(header.chanlocs)

            % Check if the current row is an EEG channel
            idx_chan = find(strcmpi(header.chanlocs(i_chan).labels, {locs.labels}));

            if ~isempty(idx_chan) % if the current row is an EEG channel
                header.chanlocs(i_chan).theta           = locs(idx_chan).theta;
                header.chanlocs(i_chan).radius          = locs(idx_chan).radius;
                header.chanlocs(i_chan).sph_theta       = locs(idx_chan).sph_theta;
                header.chanlocs(i_chan).sph_phi         = locs(idx_chan).sph_phi;
                header.chanlocs(i_chan).sph_theta_besa  = locs(idx_chan).sph_theta_besa;
                header.chanlocs(i_chan).sph_phi_besa    = locs(idx_chan).sph_phi_besa;
                header.chanlocs(i_chan).X               = locs(idx_chan).X;
                header.chanlocs(i_chan).Y               = locs(idx_chan).Y;
                header.chanlocs(i_chan).Z               = locs(idx_chan).Z;
                header.chanlocs(i_chan).topo_enabled    = 1;
                header.chanlocs(i_chan).SEEG_enabled    = 0;
            end
        end

        %% ---- TRIGGERS
        epoch_trig = find(strcmp({header.events.code}, 'Epoch'));

        % Delete additionnal 'epoch' trigger if needed
        if size(epoch_trig, 2) > 1
            header.events(epoch_trig(2:end)) = [];
        end

        % Add 'epoch' trigger if needed
        if size(epoch_trig, 2) < 1
            new_row = struct('code', 'Epoch', 'latency', 0.0009765625, 'epoch', 1);
            header.events = [new_row, header.events];
        end

        % Load the trigger file
        tname = ...
            sprintf('grp-%03d_cond-%03d_sub-%03d_ses-%03d_task-meterlearning-motor_events.tsv', ...
            group, condition, participant, session);

        events = readtable(fullfile(raw_dir, tname), ...
            'Delimiter', '\t',...
            'FileType', 'text', ...
            'HeaderLines', 0, ...
            'ReadVariableNames', true);

        % Special case (additional event)
        if participant == 88 && session == 1
            events(1,:)  = [];
            events{1,12} = 0;
        end 
        
        % special case 
        if participant == 98 && session == 1
            % (two first clappping following the pattern)
            events(20,11)  = {1};
            events(21,12)  = {1};
            events(24,12)  = {0};
        elseif participant == 98 && session == 3
            % large deflection on trial 1
            events(2,12)   = {1};
            % electrical artefact  
            events(10,12)  = {1};
            % two repeated trials to compensate with the two previously
            % deleted ones
            events(11,12)  = {0};
            events(18,12)  = {0};
        end         
        
        % Special case (only trigger 3)
        if participant == 37 && session == 1
            for i = [2:7, 10:11, 14:37]
                header.events(i).code = '1';
            end

            for i = [8:9, 12:13, 38:51]
                header.events(i).code = '2';
            end
        elseif participant == 37 && session == 3
            for i = [2:15, 18:33, 36:37]
                header.events(i).code = '1';
            end

            for i = [16:17, 34:35, 38:47]
                header.events(i).code = '2';
            end
        end

        % Special case (additional trigger)
        if participant == 46 && session == 1
            header.events(2) = [];
        elseif participant == 95 && session == 3
            header.events(2) = [];
        end

        % Special case (missing triggers)
        if participant == 53 && session == 3
            header.events = [header.events(1:2), header.events(2),...
                header.events(3:end)];
            header.events(3).latency = header.events(2).latency + 40.7988;

            header.events = [header.events(1:22), header.events(22),...
                header.events(23:end)];
            header.events(22).latency = header.events(22).latency - 40.7988;
        end

        for trig = 1 % only for regular-listening and tapping trials

            % Check the number of triggers
            n_trig_events_file = sum(events.trigger == trig);
            n_trig_eeg_file = sum(strcmp({header.events.code}, num2str(trig)));
            
            if participant ==85         
                test = zeros(30,2);
                test_events = diff(events.onset);

                for i=1:length(header.events) 
                    latencies(i) = header.events(i).latency;
                end   
                test_header = diff(latencies);

                test(1:length(test_events),1) = test_events;
                test(1:length(test_header),2) = test_header;
                disp(test)
            end

            % Remove trigger 3, 4, 7
            header.events = header.events(~strcmp({header.events.code}, num2str(3)));
            header.events = header.events(~strcmp({header.events.code}, num2str(4)));
            header.events = header.events(~strcmp({header.events.code}, num2str(7)));

            % Correct if double trigger
            if n_trig_eeg_file > 31

                % Delete double trigger
                diff_temp = diff([header.events.latency])';
                to_remove = find(diff_temp < 1) + 1;

                if ~isempty(to_remove) && to_remove(1) == 2 % time between beginning of EEG recording and 1st trigger
                    to_remove = to_remove(2:end);
                end

                header.events(to_remove) = [];

                % Delete trigger at the end
                diff_temp = diff([header.events.latency])';
                header.events = header.events([1; find(round(diff_temp, 2) ~= 40.8 & ...
                    round(diff_temp, 2) ~= 40.98) + 1]);

                if participant == 38 && session == 1
                    header.events(20) = [];
                end

            end

            n_trig_eeg_file = sum(strcmp({header.events.code}, num2str(trig)));

            % Special case (empty log file)
            if participant == 30 && session == 1

            else
                assert(n_trig_eeg_file == n_trig_events_file, ...
                    'Error: number of triggers do not match.')

                % Check the time of triggers
                trig_onset_diff_events = diff(events{events.trigger == trig, 'onset'});
                trig_onset_diff_eeg = diff([header.events(strcmp({header.events.code}, ...
                    num2str(trig))).latency])';

                %         fprintf('Inter-trigger intervals for trig == %d\n', trig);
                %         disp([trig_onset_diff_events, trig_onset_diff_eeg])

                err = abs(trig_onset_diff_events - trig_onset_diff_eeg);

                assert(all(err < 0.100), 'Error: inter-trigger intervals do not match.')

            end

        end


        %% ---- BAD TRIALS
        
        % Special case (participant 86: error in repeated trials. iEvents 4
        % & 6 to remove and iEvents 7,8,9 to keep)
        if participant == 86 && session == 1
            events.repeatedPrevTrial(7) = 1;
            events.repeatedPrevTrial(9) = 0;
            for iEvent = 7:9
                events.iTrial(iEvent) = events.iTrial(iEvent)-1;
            end            
        end
        
        
        % Remove bad trials (i.e., those redone)
        for trig = 1 % for regular-listening 

            idx_header = find(strcmp({header.events.code}, num2str(trig)));

            idx_events = find(events.trigger == trig);

            idx_repeated = find(events{idx_events, 'repeatedPrevTrial'});

            header.events(idx_header(idx_repeated - 1)) = [];

            events(idx_events(idx_repeated - 1), :) = [];

        end
        
        for trig = 2 % for clapping trials
            
            idx_clap = find(strcmp(events.trial_type,'tap'));
            
            idx_repeated = find(events{idx_clap, 'repeatedPrevTrial'});
            
            % no -1 here as the first trigger (i.e., epoch) is the
            % beginning of the eeg recording
            header.events(idx_clap(idx_repeated)) = []; 
            
            events(idx_clap(idx_repeated - 1), :) = []; 
        end
            

        % Special case (empty log file)
        if participant == 30 && session == 1

        else

            % Check the time of triggers
            trig_onset_diff_events = diff(events{ismember(events.trigger, [1]), 'onset'});
            trig_onset_diff_eeg = ...
                diff([header.events(ismember({header.events.code}, ...
                {'1'})).latency])';

            % Display time of triggers
            fprintf('Inter-trigger intervals for trig == 1 \n');
            disp([trig_onset_diff_events, trig_onset_diff_eeg])

            % Compute difference between triggers from the .bdf and .tsv files
            err = abs(trig_onset_diff_events - trig_onset_diff_eeg);

            % Check if the difference is not too big
            assert(all(err < 0.100), 'Error: inter-trigger intervals do not match after removal of bad trials.')

        end

        %% ---- DEVIANT TRIALS
        % Find and remove deviant trials
        idx = find(strcmp({header.events.code}, '2'));
        idx = idx(find(idx < 20));

        % Check if there is indeed two deviant trials
        % Special case for sub-060 (deviant trials redone)
        if participant == 60 && session == 3

        else
            assert(length(idx) == 2, 'Error: wrong number of deviant trials.')
        end

        % Remove deviant trials
        header.events(idx) = [];

    end

    %% FOR SESSION 2
    if session == 2
        %% ---- CHANNELS
        % Only keep relevant channels (AIB and sound)
        chans_to_keep = [{'Erg1'; 'Erg2'; 'Ana8'}];
        [header, data] = RLW_arrange_channels(header, data, chans_to_keep);

        %% ---- TRIGGERS
        epoch_trig = find(strcmp({header.events.code}, 'Epoch'));

        % Delete additionnal 'epoch' trigger if needed
        if size(epoch_trig, 2) > 1
            header.events(epoch_trig(2:end)) = [];
        end

        % Load the trigger file
        tname = ...
            sprintf('grp-%03d_cond-%03d_sub-%03d_ses-%03d_task-meterlearning-motor_events.tsv', ...
            group, condition, participant, session);

        events = readtable(fullfile(raw_dir, tname), ...
            'Delimiter', '\t',...
            'FileType', 'text', ...
            'HeaderLines', 0, ...
            'ReadVariableNames', true);

        % Special case for sub-046 (mess in repeting trials)
        if participant == 46
            events = events(2:end,:);
            events.repeatedPrevTrial(3) = 0;
            for i = 1:2
                events.iTrial(i) = events.iTrial(i) -1;
            end
        end
        
        if participant == 90
            events(1,:) = [];
            events{1,12} = 0;
            for i = 1:size(events,1)
                events.iEvent(i) = events.iEvent(i)-1;
            end
        end

        for trig = 1 % only for regular trials

            % Special case for sub-037 (only triggers 3), sub-046 (mess in
            % repeting trials), and sub-067 (missing trigger)
            if participant == 37
                trig = 3;
            elseif participant == 46
                header.events(1) = [];
            elseif participant == 67
                header.events = [header.events(1:24), header.events(24),...
                    header.events(25:end)];
                header.events(24).latency = header.events(25).latency - 47.9990;
            end

            % Remove trigger 2 & 4 if needed
            header.events = header.events(~strcmp({header.events.code}, num2str(2)));
            header.events = header.events(~strcmp({header.events.code}, num2str(4)));

            % Special case for sub-001 & sub-012
            if participant == 1 ||  participant == 12
                header.events = header.events([1, 3:end]);
            end

            % Check the number of triggers
            if participant == 37
                n_trig_events_file = sum(events.trigger == 1);
            else
                n_trig_events_file = sum(events.trigger == trig);
            end
            n_trig_eeg_file = sum(strcmp({header.events.code}, num2str(trig)));

            % Correct if double trigger
            if n_trig_eeg_file > 31

                % Delete double trigger
                diff_temp = diff([header.events.latency])';
                to_remove = find(diff_temp < 1) + 1;

                if ~isempty(to_remove) && to_remove(1) == 2 % time between beginning of EEG recording and 1st trigger
                    to_remove = to_remove(2:end);
                end

                header.events(to_remove) = [];

                % Delete trigger at the end
                diff_temp = diff([header.events.latency])';
                header.events = header.events([1; find(round(diff_temp, 2) ~= 48) + 1]);

            end

            n_trig_eeg_file = sum(strcmp({header.events.code}, num2str(trig)));

            % Check if the number of triggers is right
            assert(n_trig_eeg_file == n_trig_events_file, ...
                'Error: number of triggers do not match.')

            % Check the time of triggers
            if participant == 37
                trig_onset_diff_events = diff(events{events.trigger == 1, 'onset'});
            else
                trig_onset_diff_events = diff(events{events.trigger == trig, 'onset'});
            end
            trig_onset_diff_eeg = diff([header.events(strcmp({header.events.code}, ...
                num2str(trig))).latency])';

            err = abs(trig_onset_diff_events - trig_onset_diff_eeg);

            assert(all(err < 0.100), 'Error: inter-trigger intervals do not match.')

        end

        %% ---- BAD TRIALS
        % Remove bad trials (i.e., those redone)
        for trig = 1

            % Special case for sub-037
            if participant == 37
                trig = 3;
            end

            idx_header = find(strcmp({header.events.code}, num2str(trig)));

            if participant == 37
                idx_events = find(events.trigger == 1);
            else
                idx_events = find(events.trigger == trig);
            end

            idx_repeated = find(events{idx_events, 'repeatedPrevTrial'});

            header.events(idx_header(idx_repeated - 1)) = [];

            events(idx_events(idx_repeated - 1), :) = [];

        end

        % Check the time of triggers
        trig_onset_diff_events = diff(events{ismember(events.trigger, [1]), 'onset'});
        if participant == 37
            trig_onset_diff_eeg = ...
                diff([header.events(ismember({header.events.code}, ...
                {'3'})).latency])';
        else
            trig_onset_diff_eeg = ...
                diff([header.events(ismember({header.events.code}, ...
                {'1'})).latency])';
        end

        % Display time of triggers
        fprintf('Inter-trigger intervals for trig == 1 \n');
        disp([trig_onset_diff_events, trig_onset_diff_eeg])

        % Compute difference between triggers from the .bdf and .tsv files
        err = abs(trig_onset_diff_events - trig_onset_diff_eeg);

        % Check if the difference is not too big
        assert(all(err < 0.100), 'Error: inter-trigger intervals do not match after removal of bad trials.')

    end
    
    %% ---- SAVE
    deriv_dir = fullfile(params.path_output, 'data/1_cleaned', ...
        sprintf('grp-%03d', group), ...
        sprintf('cond-%03d', condition), ...
        sprintf('sub-%03d', participant));

    if ~isfolder(deriv_dir)
        mkdir(deriv_dir)
    end

    CLW_save(deriv_dir, header, data);

end

