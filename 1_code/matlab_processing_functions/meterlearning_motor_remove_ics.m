%
% Remove eye-related independent component(s).
% 
% Parameters
% ----------
% participant: integral number
%   Participant to process.
%
% Outputs
% -------
% Eye-related independent component(s) is visually selected and indicated 
% manually in the associatied .csv files.
% The outputs are saved as LetsWave files.
%
% Procedure
% -------
% Open Letswave GUI (you can use the meterlearning_motot_visual_inspection script with 
% Letswave 6 loading) and click on 'Preprocess' > 'Spatial filters' > 'ICA 
% apply spacial filter'.
% Plot the first 10 components ('IC topo').
% Identify eye blinks (horizontal polaroty) and eye movements (vertical
% polarity).
% Indicate in the 'bad_ics.xlsx' file the eye-related component number(s) -
% there should be no more than two.
%
% Author 
% -------
% Tomas Lenc
% Modified by Ségolène M. R. Guérin (January 11, 2024)
% RnB-Lab (Institute of Neuroscience, UCLouvain)
%

function meterlearning_motor_remove_ics(participant)

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
file_name = fullfile(params.path_output, '/checks/', 'bad_ics.xlsx');

% Load bad ICs table
tbl_bads = readtable(file_name, 'Format', 'auto'); 

% Extract IC for the current participant
bads = tbl_bads{tbl_bads.participant == participant & ...
    tbl_bads.group == group & ...
    tbl_bads.condition == condition, 'bad_ICs'};

% Put each number in different cells if needed
try 
    bads = str2num(bads{1}); 
catch
    bads = bads(1);
end

% Print to-be-removed IC number(s)
fprintf('Removing IC %s\n', num2str(bads));

% Indicate IC matrix name and path
file_path = fullfile(params.path_output, 'data/3_preprocessed/', ...
        sprintf('grp-%03d', group), ...
        sprintf('cond-%03d', condition), ...
        sprintf('sub-%03d', participant), 'eeg/');
    
file_name = sprintf('grp-%03d_cond-%03d_sub-%03d_ica-matrix', ...
    group, condition, participant); 

% Load the IC matrix
load(fullfile(file_path, file_name));

for session = [1 3]
    
    %% ---- LOADING DATA
    % Indicate file name
    file_name = ...
        sprintf(['grp-%03d_cond-%03d_sub-%03d_task-meterlearning-motor_session-%01d_' ...
        'filtered_epoched_interp_cleaned-trials.lw6'], ...
        group, condition, participant, session);

    % Load the data
    [header, data] = CLW_load(fullfile(file_path, file_name));

    %% ---- IC REMOVAL
    % Find the number of ICs
    n_ic = size(matrix_ICA.ica_mm, 2);

    % Extract ICs to keep
    ic2keep = setdiff(1 : n_ic, bads);
    
    % Remove bad IC(s)
    [header, data] = RLW_ICA_apply_filter(header, data, ...
        matrix_ICA.ica_mm, ...
        matrix_ICA.ica_um, ...
        ic2keep);

    % Rename the data
    header.name = [header.name, '-ics'];
    
    %% ---- EXPORT
    % Save the data
    CLW_save(file_path, header, data); 
    
end