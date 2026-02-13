%
% To call parameters for the current project.
%
% Output
% -------
% The output is a MATLAB structure.
%
% Authors
% -------
% Tomas Lenc
% Modified by Ségolène M. R. Guérin (January 11, 2024)
% RnB-Lab (Institute of Neuroscience, UCLouvain)


function params = meterlearning_motor_get_params()

% Extract current machine name
[~, hostname] = system('hostname');
hostname = deblank(hostname); 

% Add a case for your own machine
if strcmp(hostname, 'mac-BX22-210.local')
    experiment_path = '/Users/segoleneguerin/Documents/research/meter_learning_motor/empirical';  
elseif strcmp(hostname, 'mac-114-319.local')
    experiment_path = '/Users/emmanuelcoulon/Documents/MATLAB/PROJECTS/meter_learning_motor';   
else
    waitfor(msgbox('Computer not recognised. Please locate the project folder (e.g. /Users/emmanuelcoulon/Documents/MATLAB/PROJECTS/meterlearning_motor'))
    experiment_path = uigetdir;
end

% Letswave paths
letswave6_path  = fullfile(experiment_path,'1_code/lib/letswave6-master');
letswave7_path  = fullfile(experiment_path,'1_code/lib/letswave7-master');

%% Participants to keep

grp1_cond2 = [24, 30, 32, 35, 36, 49, 51, 55, 57, 60, 67, 68, 71, 76, 78, 79, 81, 87, 94, 98]; 
grp1_cond3 = [13, 31, 33, 37, 46, 48, 53, 54, 58, 63, 66, 75, 77, 80, 83, 86, 88, 91, 93, 95];
grp2_cond2 = [1, 3, 5, 7, 9, 11, 16, 18, 20, 22, 25, 27, 28, 40, 42, 43, 45, 69, 89, 90];    
grp2_cond3 = [2, 4, 8, 12, 15, 17, 23, 26, 29, 34, 39, 41, 44, 47, 52, 61, 65, 74, 84, 97]; 
all_part   = [grp1_cond2,grp1_cond3,grp2_cond2,grp2_cond3];

%% Define parameters
path_source = fullfile(experiment_path, '0_data/'); 
path_raw    = fullfile(experiment_path, '2_output/data/0_raw/'); 
path_output = fullfile(experiment_path, '2_output/');
path_plot   = fullfile(experiment_path, '2_output/plots/'); 

fs      = 1024; % in hz
fs_stim = 44100; % in hz
tempi   = 200; % in ms

nb_trial    = 18; 
nb_deviant  = 2;
n_events_per_pattern = 12;
n_patterns_per_trial = 17;
n_patterns_conti = 3;

dur_epoch_buffer = 5; 

cutoff_low_preproc = 0.1; 
order_hpf_preproc = 2; 

cutoff_high_preproc = 64; 
order_lpf_preproc = 2; 

n_chan_interp = 3; 

% Compute trial duration
trial_dur = tempi/1000 * n_events_per_pattern * n_patterns_per_trial;
trial_dur_conti = tempi/1000 * n_events_per_pattern * n_patterns_conti;

% Compute pattern duration
pattern_dur = (tempi/1000 * n_events_per_pattern);

% Filters applied for ICA training (ONLY)
fs_ica = 256;
cutoff_low_ica = 1.0;
order_hpf_ica = 4; 
cutoff_high_ica = fs_ica/4;
order_lpf_ica = 4; 

% For re-referencing
ref_name = {'mastoids', 'common-average'};
ref_mastoid = {'TP9', 'TP10'};

%% Figure parameters

fig_size  = [1 1 15 12];
font      = 'Arial';
linewidth = 1.25;
fontsize  = 17;

%% Return structure 
% List workspace variables
w = whos;

% Create an empty structure to store the data
params = []; 

% Store the workspace variables in the structure
for i = 1:length(w) 
    params.(w(i).name) = eval(w(i).name); 
end

