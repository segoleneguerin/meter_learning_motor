%% SCRIPT FROM TOMAS (TempoRhythm Project) %%
% Downloaded on December 2, 2022
% https://github.com/TomasLenc/TempoRhythm_PTB

function [cfg,logFile] = meterlearning_motor_get_cfg_smt()

%% ----- PREAMBLE
% Init parameter structure
cfg = struct(); 

%% ----- DEBUG MODE SETTING
% Set 'true' if you want to run in debug mode
cfg.debug.do = false;

% If cfg.debug.do is true, these settings will be used 
cfg.debug.smallWin = false;
cfg.debug.transpWin = false;

% Use RME Firecace soundcard in the debug mode
% if false, default computer soundcard will be used
cfg.debug.useFirefaceForDebug = true;

% Trim trials for debugging (to debugTrialDur seconds) instead 
% of using original durations (e.g. 50s)
cfg.debug.shortStim = false;
debugTrialDur = 6; % has to be more than 5 seconds

%% ----- PATHS
% Output folder
cfg.dir.output = 'output_experiment'; 

% Stimuli folder
cfg.dir.stim = 'stimuli';

%% ----- STIMULI
% Load stimuli
dStim = dir(fullfile(cfg.dir.stim, '*.mat')); 
stim = load(fullfile(cfg.dir.stim, dStim.name)); 
cfg.stim = stim.stim;

%% ----- AUDIO
% Indicate audio device
cfg.audio.deviceName = 'Fireface';

% Indicate to user which devide is used when in debug mode
if cfg.debug.do && cfg.debug.useFirefaceForDebug
    fprintf('Using Fireface for debugging'); 
elseif cfg.debug.do && ~cfg.debug.useFirefaceForDebug
    fprintf('Using internal sound card for debugging'); 
end

% Open 8 channels (max 18 on RME)
if cfg.debug.useFirefaceForDebug == false
    cfg.audio.nChannelsIn = 2;
    cfg.audio.nChannelsOut = 2;
else
    cfg.audio.nChannelsIn = 8;
    cfg.audio.nChannelsOut = 8;
end

% Indicate playback mode
% 1: playback, 2: capture, 3: simulus playback+capture
cfg.audio.playbackMode = 3;

% Indicate latency
% 3: most drastic setting
cfg.audio.requestedLatencyClass = 3;

% Volume
cfg.audio.soundVolume = 0.6; 

% Downsampling frequency (to log tap data in mat file)
cfg.audio.fsDs = 1000; 

% Mapping of trigger values onto audio output channels
cfg.audio.trigChanMapping = containers.Map({1, 2, 3}, ...
                                           {[3], [4], [3,4]}); 

% each small buffer push small duration only (e.g. 0.100 s)
cfg.audio.pushDur  = 0.200;

% first push will be longer (e.g. 5 s)
cfg.audio.initPushDur = 5;

% if we're doing capture, we need to initialize buffer with enough space to
% cover one trial of tapping
cfg.audio.tapBuffDur = 40 + 30; % get 30s more than trial duration

%% ----- SCREEN
% Set 'true' if you want to use a screen
cfg.screen.do = false; 

% There may be occassions where you do not care about perfect
% screen sync.
% In these situations you can add the command Screen('Preference','SkipSyncTests', 1);
% at the top of your script, before the first call to Screen('OpenWindow').
% This will shorten the maximum duration of the sync tests to 3 seconds worst case
% and it will force Psychtoolbox to continue with execution of your script, even if the
% sync tests failed completely.
% Psychtoolbox will still print error messages to the Matlab/Octave command window
% and it will nag about the issue by showing the red flashing warning sign for one second.
% You can disable all visual alerts via Screen('Preference','VisualDebugLevel', 0);
% You can disable all output to the command window via Screen('Preference', 'SuppressAllWarnings', 1);
cfg.skipSyncTests = 1; % 0, 1 or 2

%% ----- KEYBOARD
% Make sure keyboard mapping is the same on all supported operating systems
% Apple MacOS/X, MS-Windows and GNU/Linux:
KbName('UnifyKeyNames');

cfg.keyboard.deviceID = -1;

cfg.keyboard.keyEnter        = KbName({'RETURN'}); % press enter to start bloc
cfg.keyboard.keyStop         = KbName({'DELETE'}); 
cfg.keyboard.keySpace        = KbName('SPACE');
cfg.keyboard.keyVolUp        = KbName('UpArrow');
cfg.keyboard.keyVolDown      = KbName('DownArrow');
cfg.keyboard.keyRepeatTrial  = KbName('r');
cfg.keyboard.keyExit         = KbName('e'); 
cfg.keyboard.keySetVolume    = KbName('l');
cfg.keyboard.keyYes          = KbName('y');
cfg.keyboard.keyNo           = KbName('n');

%% ----- CREATE CONFIG FILE
% Indicate task name
cfg.task.name =  'meterlearning-motor';

% Indicate data collection device
cfg.testingDevice = 'eeg'; 

% Set verbose to 1 if you want shitloads of warnings...
cfg.verbose = 0; 

% Ask you about group, condition and/or session
cfg.subject.askGrpSess = [1 1 0];
    
% set and load all the subject input to run the experiment
if cfg.debug.do
    cfg.subject.subjectGrp = ''; 
    cfg.subject.subjectCond = ''; 
    cfg.subject.subjectNb = 999; 
    cfg.subject.sessionNb = 1; 
    cfg.subject.runNb = 1; 
    PTB_printNewLine('thick')
    fprintf('debug mode...logging as sub-%03d\n\n\n', ...
             cfg.subject.subjectNb); 
else
    cfg = userInputs(cfg);
end

% Add default parameters that haven't been set yet
cfg = checkCFG(cfg); 

% Generate filename strings
cfg = createFilename_smt(cfg);

%% ----- BIDS
% Allocate
logFile = []; 

% Unit logfile
logFile = saveEventsFile('init', cfg, logFile); 