 %% SCRIPT FROM TOMAS (TempoRhythm Project) %%
% Downloaded on December 2, 2022
% https://github.com/TomasLenc/TempoRhythm_PTB

%% ----- PREAMBLE

% Add libraries
addpath(genpath(fullfile('.', 'lib')));

% Add code
addpath(genpath(fullfile('.', 'scr')));

% Clear workspace and commmand window
clc


try  
    
% Look if the iTrial variable exists in the workspace. If not, set it to
% one, which means the experiment will go from the begining. 
if exist('iTrial') ~= 1
    iTrial = 1; 
end

% counts events to write the log (this should always start at 1 with every
% new recording file)
iEvent = 1; 

% get parameters and BIDS logFile 
[cfg,logFile] = meterlearning_motor_get_cfg(iTrial);

fileName = fullfile(cfg.dir.outputSubject,...
              [cfg.fileName.base, ...
              cfg.fileName.suffix.run, ...
              '_cfg_date-', cfg.fileName.date, ...
              '.mat']); 
save(fileName, 'cfg');

% initialize PTB
cfg = PTB_init(cfg);

%% INTRO
PTB_printNewLine('thick'); 
if iTrial~=1
    warning(sprintf('I will NOT start from trial 1, but trial %d instead!\n\nARE YOU SURE???', iTrial))
end

% display instructions
if cfg.subject.sessionNb == 2 % training session
    type(fullfile(cfg.dir.instr, 'instr_beforeStart_training.txt')) 
else
    type(fullfile(cfg.dir.instr, 'instr_beforeStart.txt')) 
end

PTB_printNewLine;
PTB_waitForKeyKbCheck(cfg.keyboard.keySpace); 

% launch VOLUME GUI to set volume and test triggers
cfg.audio.soundVolume = PTB_volGUI_RME('pahandle', cfg.audio.pahandle, ...
                                       'volume', cfg.audio.soundVolume, ...
                                       'nchan', cfg.audio.nChannelsOut); 

PTB_printNewLine('thick'); 
fprintf('Current volume is %.4f\n', PsychPortAudio('Volume', cfg.audio.pahandle))
fprintf('\npress SPACE to continue...\n')
PTB_waitForKeyKbCheck(cfg.keyboard.keySpace); 

% print 
type(fullfile(cfg.dir.instr, 'instr_introduction_training.txt'))
PTB_printNewLine;
PTB_waitForKeyKbCheck(cfg.keyboard.keySpace); 

% check design matrix 
% added by SG
if cfg.subject.sessionNb ==  2 % training session
    disp(cfg.design.designTable_training)
else % pre or post
    disp(cfg.design.designTable)
end

fprintf('\npress SPACE to continue...\n')
PTB_waitForKeyKbCheck(cfg.keyboard.keySpace); 


%% start EEG recording

instrStartEEG(cfg); 

PTB_waitForKeyKbCheck(cfg.keyboard.keySpace); 

%% 
% flag that marks if the currently playing trial is a repetition of the
% previous one (the researcher can ask for trial repetition after each
% trial)
trialRepeatingPrev = 0;

while 1 % TRIALS 

    % flag that marks if the current trial was terminated by the researcher
    % during playback 
    trialTerminated = 0; 

    % ---- PREPARE SOUND AND TRIGGER ---- 
    % get audio waveform
    if cfg.subject.sessionNb == 2 % training session

        if cfg.subject.subjectCond == 2 % duple-metre condition
            
            % extract relevant sound
            s = cfg.stim.track.sMotor_duple; 
            % apply polarity
            s = s * cfg.design.designTable_training{iTrial, 'polarity'}; 

        elseif cfg.subject.subjectCond == 3 % triple-metre condition

            % extract relevant sound
            s = cfg.stim.track.sMotor_triple; 
            % apply polarity
            s = s * cfg.design.designTable_training{iTrial, 'polarity'}; 

        end

    else % pre or post session

        if cfg.design.designTable{iTrial, 'isDeviant'} == 1
            % deviant trial 
            s = cfg.stim.track.sDeviant; 

        elseif cfg.design.designTable{iTrial, 'isDeviant'} == 0
            % standard trial 
            s = cfg.stim.track.s; 

        end

        % apply polarity
        s = s * cfg.design.designTable{iTrial, 'polarity'}; 

    end

    % display instructions for the current trial
    PTB_printNewLine('thick'); 
    if strcmp(cfg.design.designTable{iTrial, 'task'}, 'tap')
        clc % clear command window to make sure the exerimenter notices this will be a tapping trial...
        type(fullfile(cfg.dir.instr, 'instr_tappingTrial.txt')); 
    else
        type(fullfile(cfg.dir.instr, 'instr_listeningTrial.txt')); 
    end

    % display current trial information
    PTB_printNewLine;  

    if cfg.subject.sessionNb == 2 % training session

        disp(cfg.design.designTable_training(iTrial,:))
        fprintf('event %d \ntrial %d/%d\n', iEvent, iTrial, ...
            cfg.design.nTrialsPerCondMotorTraining);

    else % pre or post session

        disp(cfg.design.designTable(iTrial,:))
        fprintf('event %d \ntrial %d/%d\n', iEvent, iTrial, cfg.design.nTrials);

    end
    
    % wait for experimenter to start the next trial
    PTB_printNewLine('thin'); 
    fprintf('...press ENTER to start sound playback ...\n\n'); 
    PTB_waitForKeyKbCheck(cfg.keyboard.keyEnter); 

    % ---- STORE THE CURRENT DESIGN TABLE ----
    if cfg.subject.sessionNb == 2 % training session

        cfg.design.current_designTable = cfg.design.designTable_training;

    else % pre or post session

        cfg.design.current_designTable = cfg.design.designTable;

    end
    
    % ---- PLAY AUDIO ---- 
    % wait random time delay
    WaitSecs(cfg.timing.trialDelayMin + ...
             (rand*(cfg.timing.trialDelayMax-cfg.timing.trialDelayMin)) ); 

    % play sound
    [tapData, startTime, trialTerminated] = ...
        PTB_playSound(s, ...
        cfg.audio.fs, ...
        cfg.audio.pahandle, ...
        cfg.audio.nChannelsOut, ...
        cfg.audio.nChannelsIn, ...
        cfg.audio.trigChanMapping(cfg.design.current_designTable{iTrial, 'trigVal'}), ...
        cfg.audio.initPushDur, ...
        cfg.audio.pushDur, ...
        cfg.keyboard.keyStop);
                 
    % ---- COLLECT RESPONSE ----
    if strcmp(cfg.design.current_designTable{iTrial, 'task'}, 'listen')
        fprintf('Did the participant detect a deviant in this trial? (yes = ''%s'', no = ''%s'')\n', ...
            KbName(cfg.keyboard.keyYes), ...
            KbName(cfg.keyboard.keyNo));
        response = PTB_waitForKeyKbCheck([cfg.keyboard.keyYes, cfg.keyboard.keyNo]);
        response = KbName(response);
    else
        response = 'n/a';
    end
    
    % ===========================================
    % BIDS
    % ===========================================            
    
    % ---- events file ---- 
    if cfg.subject.sessionNb == 2 % training session
        
        logFile(iEvent,1).onset             = startTime;
        logFile(iEvent,1).duration          = cfg.stim.track.trialDur;
        logFile(iEvent,1).trial_type        = cfg.design.current_designTable{iTrial, 'task'}{1};
        logFile(iEvent,1).iTrial            = iTrial;
        logFile(iEvent,1).iEvent            = iEvent;
        logFile(iEvent,1).trackName         = cfg.design.current_designTable{iTrial, 'trackName'}{1};
        logFile(iEvent,1).gridIOI           = cfg.design.current_designTable{iTrial, 'gridIOI'};
        logFile(iEvent,1).response          = response;
        logFile(iEvent,1).trigger           = cfg.design.current_designTable{iTrial, 'trigVal'};
        logFile(iEvent,1).terminatedTrial   = trialTerminated;
        logFile(iEvent,1).repeatedPrevTrial = trialRepeatingPrev;
        logFile(iEvent,1).polarity          = cfg.design.current_designTable{iTrial,'polarity'};
        logFile(iEvent,1).soundVol          = PsychPortAudio('Volume', cfg.audio.pahandle);
        
    else % pre/post session
        
        logFile(iEvent,1).onset             = startTime;
        logFile(iEvent,1).duration          = cfg.stim.track.trialDur;
        logFile(iEvent,1).trial_type        = cfg.design.current_designTable{iTrial, 'task'}{1};
        logFile(iEvent,1).iTrial            = iTrial;
        logFile(iEvent,1).iEvent            = iEvent;
        logFile(iEvent,1).trackName         = cfg.design.current_designTable{iTrial, 'trackName'}{1};
        logFile(iEvent,1).gridIOI           = cfg.design.current_designTable{iTrial, 'gridIOI'};
        logFile(iEvent,1).isDeviant         = cfg.design.current_designTable{iTrial, 'isDeviant'};
        logFile(iEvent,1).response          = response;
        logFile(iEvent,1).trigger           = cfg.design.current_designTable{iTrial, 'trigVal'};
        logFile(iEvent,1).terminatedTrial   = trialTerminated;
        logFile(iEvent,1).repeatedPrevTrial = trialRepeatingPrev;
        logFile(iEvent,1).polarity          = cfg.design.current_designTable{iTrial,'polarity'};
        logFile(iEvent,1).soundVol          = PsychPortAudio('Volume', cfg.audio.pahandle);

    end
    
    logFile = saveEventsFile('save', cfg, logFile);
                   
    
    % ===========================================
    % MAT FILE
    % ===========================================
    
    if cfg.subject.sessionNb == 2 % training session
        
        cfg.log.event(iEvent).iTrial            = iTrial;
        cfg.log.event(iEvent).iEvent            = iEvent;
        cfg.log.event(iEvent).startTime         = startTime;
        cfg.log.event(iEvent).trackName         = cfg.design.current_designTable{iTrial, 'trackName'};
        cfg.log.event(iEvent).gridIOI           = cfg.design.current_designTable{iTrial, 'gridIOI'};
        cfg.log.event(iEvent).task              = cfg.design.current_designTable{iTrial, 'task'};
        cfg.log.event(iEvent).trigVal           = cfg.design.current_designTable{iTrial, 'trigVal'};
        cfg.log.event(iEvent).response          = response;
        cfg.log.event(iEvent).polarity          = cfg.design.current_designTable{iTrial,'polarity'};
        cfg.log.event(iEvent).soundVol          = PsychPortAudio('Volume', cfg.audio.pahandle);
        cfg.log.event(iEvent).trialTerminated   = trialTerminated;
        cfg.log.event(iEvent).repeatedPrevTrial = trialRepeatingPrev;
        
    else % pre/post session
        
        cfg.log.event(iEvent).iTrial            = iTrial;
        cfg.log.event(iEvent).iEvent            = iEvent;
        cfg.log.event(iEvent).startTime         = startTime;
        cfg.log.event(iEvent).trackName         = cfg.design.current_designTable{iTrial, 'trackName'};
        cfg.log.event(iEvent).gridIOI           = cfg.design.current_designTable{iTrial, 'gridIOI'};
        cfg.log.event(iEvent).task              = cfg.design.current_designTable{iTrial, 'task'};
        cfg.log.event(iEvent).trigVal           = cfg.design.current_designTable{iTrial, 'trigVal'};
        cfg.log.event(iEvent).isDeviant         = cfg.design.current_designTable{iTrial, 'isDeviant'};
        cfg.log.event(iEvent).response          = response;
        cfg.log.event(iEvent).polarity          = cfg.design.current_designTable{iTrial,'polarity'};
        cfg.log.event(iEvent).soundVol          = PsychPortAudio('Volume', cfg.audio.pahandle);
        cfg.log.event(iEvent).trialTerminated   = trialTerminated;
        cfg.log.event(iEvent).repeatedPrevTrial = trialRepeatingPrev;
            
    end

    % ===========================================
    % AUDIO RECORDINGS
    % ===========================================          
    if cfg.subject.sessionNb == 2 % training session

        % Indicate file name
        fileName_clap = fullfile(cfg.dir.outputSubject,...
            [cfg.fileName.base, ...
            cfg.fileName.suffix.run, ...
            sprintf('_trial-%03d', iTrial), ...
            sprintf('_event-%03d', iEvent), ...
            '_date-', cfg.fileName.date, ...
            '_audio_recording.mat']);

        % Save
        save(fileName_clap, 'tapData');

    else % pre or post session

        if iTrial > (cfg.design.nTrialsPerCondListen + ...
                cfg.design.nTrialsPerCondDeviant) % clapping trials

            % Indicate file name
            fileName_clap = fullfile(cfg.dir.outputSubject,...
                [cfg.fileName.base, ...
                cfg.fileName.suffix.run, ...
                sprintf('_trial-%03d', iTrial), ...
                sprintf('_event-%03d', iEvent), ...
                '_date-', cfg.fileName.date, ...
                '_audio_recording.mat']);

            % Save
            save(fileName_clap, 'tapData');

        end

    end
    

    % ---- DISPLAY INSTRUCTIONS ---- 
    while 1
        type(fullfile(cfg.dir.instr,'instr_afterTrial.txt'));
        PTB_printNewLine; 
        idx = PTB_waitForKeyKbCheck([cfg.keyboard.keySpace,...
                                     cfg.keyboard.keyRepeatTrial,...
                                     cfg.keyboard.keyExit,...
                                     cfg.keyboard.keySetVolume]); 
        if ismember(cfg.keyboard.keySetVolume,idx)
            % launch GUI to set volume and test triggers
            cfg.audio.soundVolume = PTB_volGUI_RME('pahandle', cfg.audio.pahandle, ...
                                                   'volume', cfg.audio.soundVolume, ...
                                                   'nchan', cfg.audio.nChannelsOut); 
            PTB_printNewLine('thick')
            fprintf('Current volume is %.4f\n', PsychPortAudio('Volume', cfg.audio.pahandle))
        elseif ismember(cfg.keyboard.keySpace, idx)        
            % go to the next condition
            trialRepeatingPrev = 0; 
            iTrial = iTrial+1; % update the condition index
            break
        elseif ismember(cfg.keyboard.keyRepeatTrial, idx)
            % don't update the condition index and repeat trial
            trialRepeatingPrev = 1; 
            break
        elseif ismember(cfg.keyboard.keyExit, idx)
            % termintate the experiment
            error(sprintf('\nexperiment terminated manually\n... data logged ...\n\n\n'))
        end
    end
    
    % store current number of trials
    if cfg.subject.sessionNb == 2 % training session

            cfg.design.current_nTrials = cfg.design.nTrialsPerCondMotorTraining;

    else % pre or post session

        cfg.design.current_nTrials = cfg.design.nTrials;

    end
    
    % break the while loop once all trials have been done for this track
    if iTrial > (cfg.design.current_nTrials)
        break 
    end

    % always update event index
    iEvent = iEvent + 1; 
    
end % end of trials



%% SAVE AND CLEAN UP
clc
fprintf('\n\n\n\n\nEND OF EXPERIMENT, WELL DONE ;)\n\n\n\n\n\n\n')

saveEventsFile('close', cfg, logFile); 

fileName = fullfile(cfg.dir.outputSubject,...
              [cfg.fileName.base, ...
              cfg.fileName.suffix.run, ...
              '_cfg_date-', cfg.fileName.date, ...
              '.mat']); 
save(fileName, 'cfg');

% copy the script file to the log folder
if ~isempty(mfilename)
    copyfile([mfilename, '.m'], ...
             fullfile(cfg.dir.outputSubject, [mfilename,'.m'])); 
end

% don't forget to save the acquisition file
if cfg.subject.sessionNb < 3
    msgbox('Don''t forget to save and start a new bdf file','Saving Reminder')
end

cleanUp

catch e
    try
        disp('Saving log...')
        
        saveEventsFile('close', cfg, logFile); 
        
        fileName = fullfile(cfg.dir.outputSubject,...
                      [cfg.fileName.base, ...
                      cfg.fileName.suffix.run, ...
                      '_cfg_date-', cfg.fileName.date, ...
                      '.mat']); 
                  
        save(fileName, 'cfg');
        
        disp('Data log saved.')
        
    catch
        disp('/!\ Did not manage to save data log...')
    end
    cleanUp
    rethrow(e)
end
