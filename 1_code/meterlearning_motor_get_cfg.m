%% SCRIPT FROM TOMAS (TempoRhythm Project) %%
% Downloaded on December 2, 2022
% https://github.com/TomasLenc/TempoRhythm_PTB

function [cfg,logFile] = meterlearning_motor_get_cfg()

%% ----- PREAMBLE
% Init parameter structure
cfg = struct(); 

%% ----- DEBUG MODE SETTING
% Set true if you want to run in debug mode
cfg.debug.do = false;

% Set true if you want to run video stim on a small portion of screen
cfg.debug.smallWin = false;
cfg.debug.transpWin = false;

% use RME Firecace soundcard in the debug mode
% if false, default computer soundcard will be used
cfg.debug.useFirefaceForDebug = false;

% Trim trials for debugging (to debugTrialDur seconds) instead 
% of using original durations (e.g. 50s)
cfg.debug.shortStim = false;
debugTrialDur = 6; % has to be more than 5 seconds

%% ----- PATHS
% Logfile folder
cfg.dir.output = 'output_experiment'; 

% Where to load stimuli from
cfg.dir.stim = 'stimuli';
 
% Where to load instructions from
cfg.dir.instr = 'instr'; 

%% ----- STIMULI
% Load stimuli
dStim = dir(fullfile(cfg.dir.stim, '*.mat')); 
stim = load(fullfile(cfg.dir.stim, dStim.name)); 
stim = stim.stim; 

if cfg.debug.do && cfg.debug.shortStim

    nSamplesKeep = round(stim.fs * debugTrialDur); 
    for i=1:length(stim.track)
        stim.track(i).s = stim.track(i).s(1:nSamplesKeep); 
        stim.track(i).sDeviant = stim.track(i).sDeviant(1:nSamplesKeep); 
        stim.track(i).trialDur = debugTrialDur; 
    end
    
end

cfg.stim = stim; 


%% ----- SCREEN
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

% Text format
cfg.text.font         = 'Arial'; %'Courier New'
cfg.text.size         = 48; %18

% Monitor parameters for PTB
cfg.color.white = [255 255 255];
cfg.color.black = [0 0 0];
cfg.color.red = [255 0 0];
cfg.color.grey = mean([cfg.color.black; cfg.color.white]);
cfg.color.background = cfg.color.black;
cfg.text.color = cfg.color.grey;

%Fixation Cross
% Used Pixels here since it really small and can be adjusted during the experiment
cfg.fixation.type                   = 'Jolien';
cfg.fixation.widthPix               = 5;   % Set the length of the lines (in Pixels) of the fixation cross
cfg.fixation.lineWidthPix           = 3;    % Set the line width (in Pixels) for our fixation cross
cfg.fixation.xDisplacement          = 0;    % Manual displacement of the fixation cross
cfg.fixation.yDisplacement          = 0;    % Manual displacement of the fixation cross
cfg.fixation.color                  = cfg.color.grey;
    
%% ----- AUDIO
% Indicate device used
cfg.audio.deviceName = 'Fireface';

% Display divice information if in debug mode
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

% 1: playback, 2: capture, 3: simulus playback+capture
cfg.audio.playbackMode = 3;

% 3: most drastic setting
cfg.audio.requestedLatencyClass = 3;

% set this volume at the begining for safety
cfg.audio.soundVolume = 0.6; 

% downsampling frequency (to log tap data in mat file)
cfg.audio.fsDs = 1000; 

% mapping of trigger values onto audio output channels
cfg.audio.trigChanMapping = containers.Map({1, 2, 3}, ...
                                           {[3], [4], [3,4]}); 

% each small buffer push small duration only (e.g. 0.100 s)
cfg.audio.pushDur  = 0.200;

% first push will be longer (e.g. 5 s)
cfg.audio.initPushDur = 5;

% if we're doing capture, we need to initialize buffer with enough space to
% cover one trial of tapping
cfg.audio.tapBuffDur = max([cfg.stim.track.trialDur]) + 30; % get 30s more than longest stimulus


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

%% ----- TIMING INFORMATION
% Pause before delay (ubiform distribution)
cfg.timing.trialDelayMin = 0.5; 
cfg.timing.trialDelayMax = 1.5; 

cfg.timing.trainingTrialDur = 48.0; 

%% ----- INSTRUCTION

%% ----- LOGGING (BIDS)
% Indicate task name
cfg.task.name =  'meterlearning-motor';    

% Indicate data collection material
cfg.testingDevice = 'eeg'; 

% Set verbose to 1 if you want shitloads of warnings...
cfg.verbose = 0; 

% it will ask you about group, condition, session
cfg.subject.askGrpSess = [1 1 1];
    
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

% add default parameters that haven't been set yet
cfg = checkCFG(cfg); 

% generate filename strings
cfg = createFilename(cfg);

%% ----- DESIGN
% Define number of trials for LISTEN 
cfg.design.nTrialsPerCondListen = 16;
% Define number of trials for DEVIANT 
cfg.design.nTrialsPerCondDeviant = 2;
% Define number of trials for CLAP 
cfg.design.nTrialsPerCondTap = 5;
% define number of trials for TRAINING %
cfg.design.nTrialsPerCondMotorTraining = 18;

% Type of design ('block' or 'interleaved')
cfg.design.type = 'block'; 

% Indicate when tapping is done ('afterBlock' or 'separateSession')
cfg.design.whenTapping = 'separateSession';

% Randomization type (fullCounterbalanced, latinSquare, random)
cfg.design.randType = 'latinSquare'; 

%  ----- PRE/POST SESSIONS
% Make the design matrix 
factorNames = fieldnames(cfg.stim.factors); 
cfg.design.factorNames = factorNames; 

factorNLevels = structfun(@(x)length(x.levels), cfg.stim.factors); 

% level names for each factor 
% (e.g. for 'track', levels are 'unsyncopated' and 'syncopated')
factorLevelNames = {}; 

% code values for each factor level 
% (e.g. 1 for 'unsyncopated' and 2 for 'syncopated')
factorLevelCodes = {}; 

for i=1:length(factorNames)
    factorLevelNames{i} = cfg.stim.factors.(factorNames{i}).levels; 
    factorLevelCodes{i} = cfg.stim.factors.(factorNames{i}).code; 
end

% get all combinations across all factor levels using level codes 
% (this is a safer way than with names)
factorLevelCodesAllComb = allcomb(factorLevelCodes{:}); 

% after having all the combinations, find level names for each code 
factorLevelNamesAllComb = cell(size(factorLevelCodesAllComb)); 
for iFact = 1:length(factorNames)
    for i = 1:size(factorLevelCodesAllComb,1)
        
        idx = find(cfg.stim.factors.(factorNames{iFact}).code == ...
                   factorLevelCodesAllComb(i,iFact)); 
         
        factorLevelNamesAllComb{i,iFact} = ...
            cfg.stim.factors.(factorNames{iFact}).levels{idx}; 
    end
end

cfg.design.nCond = size(factorLevelNamesAllComb, 1);
cfg.design.nTrials = cfg.design.nCond * ...
                        (cfg.design.nTrialsPerCondListen + ...
                         cfg.design.nTrialsPerCondDeviant + ...
                         cfg.design.nTrialsPerCondTap);

% Do counterbalancing of conditions (all factor-level combinations)
% based on the selected method
if strcmpi(cfg.design.randType,'latinSquare')

    allOrders = balLatSquare(cfg.design.nCond);
    currOrder = allOrders(mod(cfg.subject.subjectNb-1, cfg.design.nCond)+1, :);

elseif strcmpi(cfg.design.randType,'random')

    currOrder = randperm(cfg.design.nCond);

end

% Apply the conterbalanced order to conditions
factorLevelNamesAllComb = factorLevelNamesAllComb(currOrder, :);

% Put the clapping trials after each block
if strcmpi(cfg.design.whenTapping,'afterBlock')

    repeatedRows = repelem([1:cfg.design.nCond], ...
        cfg.design.nTrialsPerCondListen + ...
        cfg.design.nTrialsPerCondTap);

    designMatrix = factorLevelNamesAllComb(repeatedRows, :);

    % add column about task (listening/tapping trial)
    designMatrix(:,end+1) = repmat( [repmat({'listen'}, ...
        cfg.design.nTrialsPerCondListen,1); ...
        repmat({'tap'}, ...
        cfg.design.nTrialsPerCondTap,1)], ...
        cfg.design.nCond, 1);

% Put the clapping trials after the whole listening session
elseif strcmpi(cfg.design.whenTapping,'separateSession')

    repeatedRows = [repelem([1:cfg.design.nCond], cfg.design.nTrialsPerCondListen ...
        + cfg.design.nTrialsPerCondDeviant), ...
        repelem([1:cfg.design.nCond], cfg.design.nTrialsPerCondTap)]  ;

    designMatrix = factorLevelNamesAllComb(repeatedRows, :);

    % add column about task (listening/tapping trial)
    designMatrix(:, end+1) = [repmat({'listen'}, ...
        (cfg.design.nTrialsPerCondListen ...
        + cfg.design.nTrialsPerCondDeviant) ...
        * cfg.design.nCond,1); ...
        repmat({'tap'}, ...
        cfg.design.nTrialsPerCondTap*cfg.design.nCond,1)];

end

% Add column for deviants
isDeviant = repmat(0, cfg.design.nTrials, 1);
designMatrix(:,end+1) = num2cell(isDeviant);

for iCond=1:cfg.design.nCond

    currCondTrials = [(iCond-1)*(cfg.design.nTrialsPerCondListen+cfg.design.nTrialsPerCondDeviant)+1 ...
        : iCond*(cfg.design.nTrialsPerCondListen+cfg.design.nTrialsPerCondDeviant)];


    deviantTrials = randsample(currCondTrials, cfg.design.nTrialsPerCondDeviant);

    designMatrix(deviantTrials, end) = {1};

end

% Add column for sound polarity
if mod(cfg.design.nTrialsPerCondListen,2)
    warning('Cannot counterbalance sound polarity in odd number of trials!');
end

polarity = nan(size(designMatrix,1), 1);
currPolarity = 1;

for iTrial=1:size(designMatrix,1)
    if strcmp(designMatrix{iTrial,3},'listen')
        if designMatrix{iTrial,4}==1
            % deviant
            polarity(iTrial) = 1;
        elseif designMatrix{iTrial,4}==0
            % listening trial
            polarity(iTrial) = currPolarity;
            currPolarity = -currPolarity;
        end
    elseif strcmp(designMatrix{iTrial,3},'tap')
        % tapping trial
        polarity(iTrial) = 1;
    end
end

designMatrix(:,end+1) = num2cell(polarity);

% Make a design table (trial-wise)
cfg.design.designTable = cell2table(designMatrix, ...
    'VariableNames', [factorNames; ...
    {'task';...
    'isDeviant'; ...
    'polarity'}]);

% Add column for triggers
trigVal = repmat(1, cfg.design.nTrials, 1);
trigVal(strcmpi(cfg.design.designTable.task, 'tap')) = 2;
trigVal(cfg.design.designTable.isDeviant==1) = 2;
cfg.design.designTable.trigVal = trigVal;

% Make table of condition order in the experiment (block-wise)
cfg.design.conditionTable = cell2table(factorLevelNamesAllComb, ...
    'VariableNames', [factorNames]);

%  ----- TRAINING SESSION SESSION
% Create a design matrix
repeatedRows_training = repmat(1, 1, 18); 
designMatrix_training = factorLevelNamesAllComb(repeatedRows_training, :);

% Find current task
if cfg.subject.subjectCond == 2
    name_task = 'learning-duple';
elseif cfg.subject.subjectCond == 3
    name_task = 'learning-triple';
elseif cfg.debug.do
    name_task = 'debug-mode';
end

% Add column about task
designMatrix_training(:, end + 1) = [repmat({name_task}, ...
    cfg.design.nTrialsPerCondMotorTraining * ...
    cfg.design.nCond, 1)];

% Add column for sound polarity
if mod(cfg.design.nTrialsPerCondMotorTraining,2)
    warning('Cannot counterbalance sound polarity in odd number of trials!');
end

polarity = nan(size(designMatrix_training,1), 1);
currPolarity = 1;

for iTrial=1:size(designMatrix_training,1)
    polarity(iTrial) = currPolarity;
    currPolarity = -currPolarity;
end

designMatrix_training(:,end+1) = num2cell(polarity);

% Add column names
cfg.design.designTable_training = cell2table(designMatrix_training, ...
    'VariableNames', [factorNames; ...
    {'task'; ...
    'polarity'}]);

% Add column for triggers
trigVal_training = repmat(1, cfg.design.nTrialsPerCondMotorTraining, 1);
cfg.design.designTable_training.trigVal = trigVal_training;

%  ----- Display info
PTB_printNewLine('thick')
fprintf('\nCondition order for this subject is: \n');
disp(factorLevelNamesAllComb);

fprintf('-> using "%s" stimulation protocol\n\n',cfg.design.type);
fprintf('-> using "%s" design for tapping\n\n',cfg.design.whenTapping);
fprintf('-> using "%s" counterbalancing method\n\n',cfg.design.randType);

if strcmpi(cfg.design.randType,'latinSquare')
    fprintf('   (note: counterbalanced after every %d subjects)\n\n',size(allOrders,1));
end

PTB_printNewLine('thick')

%% ----- BIDS EEG
% Indicate recording device
cfg.fileName.modality = 'eeg'; 

% EEG recording parameters (for _eeg.json file)
cfg.bids.eeg.EEGReference = 'CMS'; 
cfg.bids.eeg.EEGGround = 'CMS'; 

cfg.bids.eeg.Instructions = ['Listen to the rhythmic stimuli without movement, ', ...
                             'and after the end of each trial, report to the experimenter ', ...
                             'whether you have perceived a transient tempo increase occurring ', ...
                             'for a couple of seconds at some point during the trial. ', ...
                             'On some trials, clap the regularly-spaced pulse you perceive'...
                             'with your hands.']; 

cfg.bids.eeg.SamplingFrequency = 1024; 

cfg.bids.eeg.Manufacturer = 'Biosemi'; 

cfg.bids.eeg.ManufacturersModelName = 'Active II'; 

cfg.bids.eeg.RecordingType = 'continuous'; % continuous, epoched

cfg.bids.eeg.EEGPlacementScheme = '10-20'; 

cfg.bids.eeg.EEGChannelCount = 66;  % 64 (A+B) + 2 mastoids (EXT1, EXT2)

cfg.bids.eeg.EOGChannelCount = 0; % under the right eye (EXT3)

cfg.bids.eeg.MiscChannelCount = 0; % accelerometer (ERGO)

createJson(cfg,'eeg') % save EEG sidecar json 

% TO DO: _channels.tsv and _electrodes.tsv files!

% TO DO: _coordsystem.json file!

%% ----- BIDS (event file)
% Allocate
logFile = []; 

% We can define what extra columns we want in our tsv file beyond the 
% BIDS holy trinity ('onset', 'duration', 'trial_type')
logFile.extraColumns = {'iTrial','iEvent', ...
                        'trackName', 'gridIOI', ...
                        'isDeviant', 'response', 'trigger', ...
                        'terminatedTrial', 'repeatedPrevTrial', ...
                        'polarity', 'soundVol'};

% Init logfile
logFile = saveEventsFile('init', cfg, logFile); 

% Change info about trial_type
logFile.columns.trial_type.Levels = containers.Map({'listen','clap','learning-duple', ...
    'learning-triple'}, {'listen without movement', ...
    'clap hand with the pulse', ...
    '3-beat meter condition', ...
    '4-beat meter condition'});
    
% add info to the extra columns
logFile.extraColumns.iEvent.bids.Description = 'counter number of event'; 

logFile.extraColumns.trackName.bids.Description = 'name of the rhythmic pattern'; 

logFile.extraColumns.gridIOI.bids.Description = ...
    'grid Inter-Onset-Interval (IOI) of the rhythmic stimulus'; 
logFile.extraColumns.gridIOI.bids.Levels = 0.200;  
logFile.extraColumns.gridIOI.bids.Units = 's';  

logFile.extraColumns.isDeviant.bids.Description = 'is deviant target present in the trial'; 
logFile.extraColumns.isDeviant.bids.Levels = containers.Map({'0','1'},...
    {'deviant target not present',...
    'deviant target present'});
                                                       
logFile.extraColumns.response.bids.Description = 'was deviant target reported in the trial'; 
logFile.extraColumns.response.bids.Levels = containers.Map({KbName(cfg.keyboard.keyNo),...
    KbName(cfg.keyboard.keyYes)},...
    {'NO, deviant target not reported',...
    'YES, deviant target reported'});
                                                       
logFile.extraColumns.trigger.bids.Description = 'EEG trigger value'; 
logFile.extraColumns.trigger.bids.Levels = containers.Map({'1','2'},...
    {'listen','tap'});

logFile.extraColumns.terminatedTrial.bids.Description = 'Flag whether trial was manually terminated during sound playback';
logFile.extraColumns.terminatedTrial.bids.Levels = containers.Map({'0', '1'}, ...
    {'trial ok','trial terminated'});

logFile.extraColumns.repeatedPrevTrial.bids.Description = 'Flag whether this is a repetition of the previous trial (requested by the experimenter)';
logFile.extraColumns.repeatedPrevTrial.bids.Levels = containers.Map({'0', '1'}, ...
    {'new trial','repeating previous trial'});

logFile.extraColumns.polarity.bids.Description = 'Polarity of audio waveform';
logFile.extraColumns.polarity.bids.Levels = containers.Map({'1','-1'}, ...
    {'original polarity','inverted polarity'});
                                                        
logFile.extraColumns.soundVol.bids.Description = 'Psychtoolbox volume setting';

% open tsv and write json for events
logFile = saveEventsFile('open',cfg,logFile); 

