%% ----- INFO
% Safe way of running the main experiment script without accidentally
% typing into the file while open in editor
  

%% ----- CLEAN WORKSPACE
clear all 

%% ----- TRIAL INDEX
% Set index that counts trials to from the design table (note that the
% same trial can repeat multiple times when repetition is requested by the
% researcher).
% However, these different repetitions will have distinct iEvent index. 
iTrial = 1;

% ==============================================================================
% IMPORTANT in case of a hard crash: 
% - quit matlab and stop EEG recording
% - look at the last trial that was presented (you can find this in the
%   tsv logfile for the current subject)
% - set the iTrial variable equal to that particular trial 
% - start a new PTB session and new EEG recording (there will be a
%   warning but ignore it)

% This way, it will be easy to reconstruct what was happening afterwards,
% (using the datetime stamp in filenames) and recover all the data with no
% problem. 
% ==============================================================================

%% Run the experiment 
meterlearning_motor_experiment()
