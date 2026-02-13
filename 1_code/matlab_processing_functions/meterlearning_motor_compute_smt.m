%
% Compute spontaneous-motor tempo from microphone recordings.
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
% The outputs are saved as .csv files.
%
% Author
% -------
% Ségolène M. R. Guérin
% December 22, 2023
% RnB-Lab (Institute of Neuroscience, UCLouvain)
%

function meterlearning_motor_compute_smt(participant)

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
tbl_smt = cell2table(cell(0, 4), ...
    'VariableNames', {'group', 'condition', 'participant', 'smt'});

%% ----- LOAD DATA
% Set path for the current participant
raw_dir = fullfile(params.path_source, ...
    sprintf('grp-%03d', group), ...
    sprintf('cond-%03d', condition), ...
    sprintf('sub-%03d/', participant));

% Indicate participant file name
file_name = dir(fullfile(raw_dir, '*_smt.mat'));

% Load the data
load(fullfile(raw_dir, file_name.name));

%% ----- SEGMENT DATA
% Normalise sound
data_clap = rescale(tapData(1,:), -1, +1);

% Remove baseline drift
data_clap = data_clap - mean(data_clap);

% Extract current trial
trial_end = round(params.trial_dur * params.fs_stim);
data_clap = data_clap(1: trial_end)';

%% ----- EXTRACT CLAPS
% Find clap location (arbitrary threshold)
min_pk_dist = params.fs_stim * 0.2; % 200 ms
min_pk_prom = mean(data_clap) + (2 * std(data_clap));
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

%% ----- COMPUTE SMT
% Compute inter-response intervals
iri = diff(locs_sec);

% Compute SMT
smt = mean(iri);

% Organise data
new_row = [...
    repmat({group}, 1, 1), ... % group
    repmat({condition}, 1, 1), ... % condition
    repmat({participant}, 1, 1), ... % participant
    num2cell(smt), ... % smt
    ];

% Store
tbl_smt = [tbl_smt; new_row];

%% ----- PLOT
subplot(2,1,1)
plot(time_vector, data_clap, 'LineWidth', 1, ...
    'MarkerFaceColor', [0 0.4470 0.7410]);
hold on
scatter(locs_sec, peak_amp, 'filled');
xlabel 'Time (s)';
ylabel 'Sound Amplitude';
title(sprintf('Group %d, Participant %02d', ...
    group, participant));
hold off
set(gca, 'TickDir', 'out')
box off


subplot(2,1,2)
plot(iri, '-o', 'LineWidth', 1, ...
    'MarkerFaceColor', [0 0.4470 0.7410])
xlabel 'Data Point';
ylabel 'Inter-Response Interval';
axis([0 length(iri) 0.2 1])
yline(0.6, '--', 'Triple', 'LineWidth', 2, ...
    'Color', [0.8500 0.3250 0.0980]);
yline(0.4, '--', 'Duple', 'LineWidth', 2, ...
    'Color', [0.9290 0.6940 0.1250]);
yline(0.8, '--', 'Duple', 'LineWidth', 2, ...
    'Color', [0.9290 0.6940 0.1250]);
set(gca, 'TickDir', 'out')
box off

% Save
name_plot = sprintf('grp-%03d_cond-%03d_sub-%03d_smt.png', ...
    group, condition, participant);
path_plot = fullfile(params.path_output, '/plots/clap/smt/');

if ~isfolder(path_plot)
    mkdir(path_plot)
end

saveas(gcf, fullfile(path_plot, name_plot));

% Close plot
close all

%% ---- EXPORT    
% Indicate file names and path
export_name = sprintf('grp-%03d_cond-%03d_sub-%03d_smt.csv', ...
    group, condition, participant);
export_path = fullfile(params.path_output, 'data/4_final/clap/smt/');

if ~isfolder(export_path)
    mkdir(export_path)
end

% Save
writetable(tbl_smt, fullfile(export_path, export_name));
