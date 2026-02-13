%% ----- PREAMBLE
% Clear workspace and commmand window
clear
clc

% Add libraries
addpath(genpath(fullfile('.', 'lib')));

% Add code
addpath(genpath(fullfile('.', 'scr')));

% Get parameters and BIDS logFile 
[cfg,logFile] = meterlearning_motor_get_cfg_smt();

% Initialize PTB
cfg = PTB_init(cfg);

% Pause script for 2 sec
pause(2);

%% ----- AUDIO RECORDINGS
% Create a fake audio stimulus
s = zeros(1, size(cfg.stim.track.s, 2)); 

% Wait for user to start trial
fprintf('\npress SPACE to start...\n')
PTB_waitForKeyKbCheck(cfg.keyboard.keySpace); 

% Run the trial
[tapData, startTime, trialTerminated] = ...
    PTB_playSound(s, ...
    cfg.audio.fs, ...
    cfg.audio.pahandle, ...
    cfg.audio.nChannelsOut, ...
    cfg.audio.nChannelsIn, ...
    1, ...
    cfg.audio.initPushDur, ...
    cfg.audio.pushDur, ...
    cfg.keyboard.keyStop);



% 
% currTapIdx = 0; 
% tapData = zeros(2, round((5 + 10) * 44100) ); 
% 
% InitializePsychSound(1);
% pahandle = PsychPortAudio('Open', [], 3, 3, 44100);
% 
% % preallocate tapping buffer
% bufferSamples = cfg.audio.fs * cfg.audio.tapBuffDur;
% PsychPortAudio('GetAudioData', ...
%     pahandle, ...
%     bufferSamples);
% 
% PsychPortAudio('GetAudioData', pahandle); 
% 
% PsychPortAudio('Close');
% 
% 
% % Stop sound capture
% % PsychPortAudio('Stop', pahandle , [], [], [], start_time + 5);
% 
% % Initialise progress bar
% textprogressbar('trial progress: '); 
% 
% % Start timer
% tic
% 
% % Update progress bar
% while toc < 40
%     pause(2.5)
%     percentProgress = toc / 40.8 * 100;
%     textprogressbar(percentProgress);
% end
% 
% % End of trial
% textprogressbar(' end of playback');

%% ----- SAVE DATA
% Indicate file name
fileName = fullfile(cfg.dir.outputSubject, ...
    [char(strcat(extractBefore(cfg.fileName.base, '_ses'), ...
            extractAfter(cfg.fileName.base, 'ses-'))), ...
    cfg.fileName.suffix.run, ...
    '_date-', cfg.fileName.date, ...
    '_smt.mat']);

% Save
save(fileName, 'tapData');

