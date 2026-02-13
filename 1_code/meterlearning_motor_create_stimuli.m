%% SCRIPT ADAPTED FROM TOMAS (TempoRhythm Project) %%
% Downloaded on December 2, 2022
% https://github.com/TomasLenc/TempoRhythm_PTB


%% ----- PREAMBLE
% Clear workspace and commmand window
clear
clc

% Load lib path
addpath(genpath('scr'))

% Create an empty object
stim = []; 

% Create an output folder if not existing
savePath = fullfile('..','1_code/stimuli');
if ~isfolder(savePath)
    mkdir(savePath)
end

% Clean the output directory
delete(fullfile(savePath, '*'));

%% ----- PARAMETERS
% Indicate track name
trackName = {'bembe'};
    
% Indicate rhythmic pattern
pattern = {[1 0 1 0 1 1 0 1 0 1 0 1]};
pattern_training_duple = {[1 0 0 0 1 0 0 0 1 0 0 0]};
pattern_training_triple = {[1 0 0 1 0 0 1 0 0 1 0 0]};

% Indicate sampling rate
stim.fs = 44100; % i.e., 44.1 kHz, commun sampling frequency

% Indicate time interval between successive events (either sound or silence)
gridIOI = 0.200;

% Indicate duration of sound event
eventDur = 0.200 * gridIOI/0.200; % 4 ms for click, N ms for tone

% Indicate event type
eventType = 'tone'; % tone, noise, click

% Indicate duration of linear onset ramp for the sound event
rampon = 0.010  * gridIOI/0.200; % set for 0.2 s IOI and scale with tempo

% Indicate duration of linear offset ramp for the sound event
rampoff = 0.050  * gridIOI/0.200; % set for 0.2 s IOI and scale with tempo

% Indicate how many times the rhythmic pattern repeats in each trial
nCycles = 17; % 40.8 s is 17 cycles (for a 2.4-s cycle)
nCycles_conti = 3; % 7.2 s

% Indicate carrier f0
f0 = 200;

% Indicate which cycles will have different tempo in deviant trials 
deviantCycles = 10;

% Indicate whether the tempo change in deviant trials be faster or slower
deviantChangeDirection = 'slower'; 

% Indicate how much will tempo change in deviant trials 
deviantChangeMagn = 0.075; % corresponds to mean thresholds in XPAttention

% Save factors and their levels for easy access 
stim.factors.trackName.levels = trackName; 
stim.factors.trackName.code = 1:length(trackName); 

stim.factors.gridIOI.levels = num2cell(gridIOI); 
stim.factors.gridIOI.code = 1:length(gridIOI); 

% Indicate track index
cTrack = 1; 

% if constant eventDur for all tempi is set,
% just replicate the value to have a vector 
if length(eventDur) == 1
    eventDur = repmat(eventDur, 1, length(gridIOI)); 
end
% if constant rampon for all tempi is set,
% just replicate the value to have a vector 
if length(rampon) == 1
    rampon = repmat(rampon, 1, length(gridIOI)); 
end
% if constant rampoff for all tempi is set,
% just replicate the value to have a vector 
if length(rampoff) == 1
    rampoff = repmat(rampoff, 1, length(gridIOI)); 
end

%% ----- CREATE STIMULI
for iTrackName = 1:length(trackName)

    for iGridIOI = 1:length(gridIOI)
    
        % Compute trial duration oin seconds
        trialDur = nCycles * length(pattern{iTrackName}) *...
            gridIOI(iGridIOI);
        trialDur_conti = nCycles_conti * ...
            length(pattern{iTrackName}) * ...
            gridIOI(iGridIOI);

        carrier = getCarrier(eventType, trialDur, stim.fs, f0); 
        carrier_conti = getCarrier(eventType, ...
            trialDur_conti, stim.fs, f0);
        
        %% ----- Create a sound event
        
        if strcmp(eventType,'tone') || strcmp(eventType,'noise')
            
            % mMke envelope of one sound event
            envEvent = ones(1, round(eventDur(iGridIOI) * stim.fs));

            % Apply onset and offset ramp
            envEvent(1:round(rampon(iGridIOI)*stim.fs)) = ...
                envEvent(1:round(rampon(iGridIOI)*stim.fs)) .* ...
                                linspace(0,1,round(rampon(iGridIOI)*...
                                stim.fs));

            envEvent(end-round(rampoff(iGridIOI)*stim.fs)+1:end) = ...
                envEvent(end-round(rampoff(iGridIOI)*stim.fs)+1:end) .* ...
                linspace(1,0,round(rampoff(iGridIOI)*stim.fs));
            
        elseif strcmp(eventType,'click')
            
            % Make envelope of one sound event
            envEvent = [ones(1,round(eventDur(iGridIOI)/2*stim.fs)), ...
                        -ones(1,round(eventDur(iGridIOI)/2*stim.fs))];
            
        end
        
        %% ----- Create standard stimulus
        % Make ncycles copies of the rhythmic pattern
        soundOnsetTimes = getSoundOnsetTimes(pattern{iTrackName},...
            nCycles, gridIOI(iGridIOI)); 
                                                 
        % Allocate envelope vector for the whole trial (as zeros)
        envTrial = zeros(size(carrier));

        % Go over each event in the trial
        for i = 1:length(soundOnsetTimes)
            
            % Convert to index
            eventIdx = round(soundOnsetTimes(i) * stim.fs);

            % Paste the sound event envelope
            envTrial(eventIdx+1:eventIdx+length(envEvent)) = envEvent;
        end

        if strcmp(eventType,'tone') || strcmp(eventType,'noise')
            % Multiply carrier and envelope for the whole trial
            s = carrier .* envTrial;
        elseif strcmp(eventType,'click')
            s = envTrial; 
        end
        
        
       %% ----- Create deviant stimulus
       % Make ncycles copies of the rhythmic pattern
       soundOnsetTimesDeviant = getSoundOnsetTimes(pattern{iTrackName},...
                                   nCycles, ...
                                   gridIOI(iGridIOI), ...
                                   'deviantCycles', deviantCycles, ...
                                   'changeDirection',...
                                        deviantChangeDirection, ...
                                   'changeMagn', deviantChangeMagn); 

        % Allocate envelope vector for the whole trial (as zeros)
        envTrialDeviant = zeros(size(carrier));

        % go over each event in the trial
        for i = 1:length(soundOnsetTimesDeviant)

            % Convert to index
            eventIdx = round(soundOnsetTimesDeviant(i) * stim.fs);
            
            % Paste the sound event envelope
            envTrialDeviant(eventIdx+1: ...
                            eventIdx+length(envEvent)) = envEvent;

        end

        if strcmp(eventType,'tone') || strcmp(eventType,'noise')

            % Multiply carrier and envelope for the whole trial
            trialDurDeviant = length(envTrialDeviant)/stim.fs;
            carrierDeviant = getCarrier(eventType, trialDurDeviant,...
                                        stim.fs, f0); 
            sDeviant = carrierDeviant .* envTrialDeviant;

        elseif strcmp(eventType,'click')
            sDeviant = envTrialDeviant; 
        end        
        

        %% ----- Create motor training stimulus
        % ----- Tracker (accented)
        % Load high-pitched clave sound
        [tracker_low.y, tracker_low.fs] = audioread("sounds/kick.wav");
        tracker_high.y = tracker_low.y .* 2.5;
        
        soundOnsetTimes_tracker_duple = ...
            getSoundOnsetTimes(pattern_training_duple{iTrackName}, ...
            nCycles, gridIOI(iGridIOI));

        soundOnsetTimes_tracker_triple = ...
            getSoundOnsetTimes(pattern_training_triple{iTrackName}, ...
            nCycles, gridIOI(iGridIOI));

        % Make ncycles copies of the rhythmic pattern
        sTracker_duple = zeros(size(1:(stim.fs * trialDur)));
        sTracker_triple = zeros(size(1:(stim.fs * trialDur)));

        % Go over each event in the trial
        for i = 1:length(soundOnsetTimes_tracker_duple) % duple

            position_event = round(soundOnsetTimes_tracker_duple(i) * stim.fs);

            if any(i == 1:length(find(pattern_training_duple{1})):...
                    length(soundOnsetTimes_tracker_duple))
            
                % Paste the sound
                sTracker_duple(position_event+1: ... 
                            position_event+length(tracker_high.y)) = tracker_high.y;

            else

                 % Paste the sound
                sTracker_duple(position_event+1: ... 
                            position_event+length(tracker_low.y)) = tracker_low.y;

            end

        end

        for i = 1:length(soundOnsetTimes_tracker_triple) % triple

            position_event = round(soundOnsetTimes_tracker_triple(i) * stim.fs);

            if any(i == 1:length(find(pattern_training_triple{1})):...
                    length(soundOnsetTimes_tracker_triple)) % triple: 1:4:80
            
                % Paste the sound
                sTracker_triple(position_event+1: ... 
                            position_event+length(tracker_high.y)) = tracker_high.y;

            else

                 % Paste the sound
                sTracker_triple(position_event+1: ... 
                            position_event+length(tracker_low.y)) = tracker_low.y;

            end

        end
        

        % ----- Rythmic pattern
        % Make ncycles copies of the rhythmic pattern
        soundOnsetTimes_training_duple = getSoundOnsetTimes(pattern{iTrackName}, ...
            nCycles, gridIOI(iGridIOI));
        soundOnsetTimes_conti = getSoundOnsetTimes(pattern{iTrackName}, ...
            nCycles_conti, gridIOI(iGridIOI));

        soundOnsetTimes_training_triple = getSoundOnsetTimes(pattern{iTrackName}, ...
            nCycles, gridIOI(iGridIOI));
        
                                                 
        % Allocate envelope vector for the whole trial (as zeros)
        envTrial_training_duple = zeros(size(carrier));
        envTrial_training_triple = zeros(size(carrier));
        envTrial_conti_duple = zeros(size(carrier_conti));
        envTrial_conti_triple = zeros(size(carrier_conti));

        % Synchronisation
        for i = 1:length(soundOnsetTimes_training_duple)
            
            % Convert to index
            eventIdx_training = round(soundOnsetTimes_training_duple(i) * stim.fs);

            % Paste the sound event envelope
            envTrial_training_duple(eventIdx_training + 1 : ...
                eventIdx_training + length(envEvent)) = envEvent;
        
        end

        for i = 1:length(soundOnsetTimes_training_triple)
            
            % Convert to index
            eventIdx_training = round(soundOnsetTimes_training_triple(i) * stim.fs);

            % Paste the sound event envelope
            envTrial_training_triple(eventIdx_training + 1 : ...
                eventIdx_training + length(envEvent)) = envEvent;
        
        end

        % Continuation
        for i = 1:length(soundOnsetTimes_conti)
            
            % Convert to index
            eventIdx_conti = round(soundOnsetTimes_conti(i) * stim.fs);

            % Paste the sound event envelope
            envTrial_conti_duple(eventIdx_conti + 1 : ...
                eventIdx_conti + length(envEvent)) = envEvent;

            envTrial_conti_triple(eventIdx_conti + 1 : ...
                eventIdx_conti + length(envEvent)) = envEvent;
        
        end


        if strcmp(eventType,'tone') || strcmp(eventType,'noise')

            % Multiply carrier and envelope for the whole trial
            sMotor_training_duple = carrier .* envTrial_training_duple;
            sConti_duple = carrier_conti .* envTrial_conti_duple;

            sMotor_training_triple = carrier .* envTrial_training_triple;
            sConti_triple = carrier_conti .* envTrial_conti_triple;

        elseif strcmp(eventType,'click')

            sMotor_training_duple = envTrial_training_duple;
            sConti_duple = envTrial_conti_duple;

            sMotor_training_triple = envTrial_training_triple;
            sConti_triple = envTrial_conti_triple;

        end

        % ----- Build the final motor-training stimulus
        % Combine the rythmic pattern and clave tracker
        sTracker_duple = sTracker_duple(1:length(sMotor_training_duple));
        sTracker_duple = sTracker_duple / 5; % relative protuberance of the tracker
        sSynchro_duple = sMotor_training_duple + sTracker_duple;

        sTracker_triple = sTracker_triple(1:length(sMotor_training_triple));
        sTracker_triple = sTracker_triple / 5; % relative protuberance of the tracker
        sSynchro_triple = sMotor_training_triple + sTracker_triple;

        % Merge the synchronisation and continuation parts
        sMotor_duple = [sSynchro_duple, sConti_duple];
        sMotor_duple = rescale(sMotor_duple, -1, +1);

        sMotor_triple = [sSynchro_triple, sConti_triple];
        sMotor_triple = rescale(sMotor_triple, -1, +1);

        
        %% ----- STORE INFORMATION
        
        % Save into structure
        stim.track(cTrack).trackName   = trackName{iTrackName}; 
        stim.track(cTrack).pattern     = pattern{iTrackName}; 
        stim.track(cTrack).gridIOI     = gridIOI(iGridIOI); 
        stim.track(cTrack).eventDur    = eventDur(iGridIOI); 
        stim.track(cTrack).rampon      = rampon(iGridIOI); 
        stim.track(cTrack).rampoff     = rampoff(iGridIOI); 
        stim.track(cTrack).nCycles     = nCycles; 
        stim.track(cTrack).eventType   = eventType; 
        stim.track(cTrack).trialDur    = trialDur; 
        stim.track(cTrack).env         = envTrial;
        stim.track(cTrack).s           = s;
        
        stim.track(cTrack).deviantCycles            = deviantCycles;
        stim.track(cTrack).deviantChangeDirection   = deviantChangeDirection;
        stim.track(cTrack).deviantChangeMagn        = deviantChangeMagn;
        stim.track(cTrack).sDeviant                 = sDeviant;

        stim.track(cTrack).pattern_training_duple   = ...
            pattern_training_duple{iTrackName}; 
        stim.track(cTrack).pattern_training_triple   = ...
            pattern_training_triple{iTrackName}; 
        stim.track(cTrack).nCycles_conti            = nCycles_conti;
        stim.track(cTrack).sMotor_duple             = sMotor_duple;
        stim.track(cTrack).sMotor_triple            = sMotor_triple;

        %% ----- WRITE .WAV FILES
        % Indicate name
        fileName = sprintf('track-%s_gridIOI-%.3fs_eventType-%s', ...
            stim.track(cTrack).trackName, ...
            stim.track(cTrack).gridIOI, ...
            stim.track(cTrack).eventType);

        % Write
        audiowrite(fullfile(savePath,[fileName,'.wav']), ...
            s, ...
            stim.fs);
        audiowrite(fullfile(savePath,...
            sprintf('%s_deviant-%s.wav', ...
            fileName, deviantChangeDirection)), ...
            sDeviant, ...
            stim.fs);
        audiowrite(fullfile(savePath,[fileName,'_learning-duple.wav']), ...
            sMotor_duple, ...
            stim.fs);
        audiowrite(fullfile(savePath,[fileName,'_learning-triple.wav']), ...
            sMotor_triple, ...
            stim.fs);
                
        % Update counter
        cTrack = cTrack+1; 

        %% ----- PLOT
        f = plotSummary(envTrial, envEvent, stim.fs); 
        saveas(f, fullfile(savePath,[fileName,'.fig'])); 
        close(f);
        
        env_sSynchro = abs(hilbert(sSynchro_duple)); 
        f = plotSummary(env_sSynchro, envEvent, stim.fs); 
        saveas(f, fullfile(savePath,[fileName,'_learning-duple.fig'])); 
        close(f);  

        env_sSynchro = abs(hilbert(sSynchro_triple)); 
        f = plotSummary(env_sSynchro, envEvent, stim.fs); 
        saveas(f, fullfile(savePath,[fileName,'_learning-triple.fig'])); 
        close(f);  

        env_tracker = abs(hilbert(tracker_low.y));
        f = plotSummary(envTrial, env_tracker, stim.fs); 
        saveas(f, fullfile(savePath,[fileName,'_tracker.fig'])); 
        close(f);
        
    end

    %% ----- SOUND CALIBRATION
    % Write one carrier for sound intensity calibration
    audiowrite(fullfile(savePath,[strcat('carrier_for_calibration_', ...
                        string(trackName), '.wav')]), ...
                carrier, ...
                stim.fs); % path changed by SG
    
    
end

%% ----- ADD INFORMATION
stim.nTracks = length(stim.track); 

stim.dateFormat = 'yyyymmddHHMM'; 
stim.dateCreated = datestr(now, stim.dateFormat); 

%% ----- SAVE
save(fullfile(savePath,[strcat('stimuli_', string(trackName),...
              '.mat')]), 'stim'); % path changed by SG



%% ----- FUNCTIONS
function f = plotSummary(envTrial,envEvent,fs)

    f = figure('color','white'); 
    
    subplot 211
    t = (0:length(envEvent)-1)/fs; 
    plot(t, envEvent,'linew',2)
    hold on
    xlim([-max(t),max(t)*2])
    ylim([-2,2])
    xlabel('time (s)')
    box off
    ax = gca; 
    ax.XAxisLocation = 'origin'; 
    ax.YAxisLocation = 'origin'; 
    
    subplot 212
    N = length(envTrial); 
    mX = abs(fft(envTrial))/N; 
    maxfreqidx = round(6/fs*N)+1; 
    freq = (0:maxfreqidx-1)/N*fs; 
    mX(1) = 0; 
    mX = mX(1:maxfreqidx); 
    stem(freq,mX,'Marker','none','linew',1.5)
    box off

end


function carrier = getCarrier(eventType,trialDur,fs,f0)

    % make time vector for one trial
    t = (0 : 1/fs : trialDur-1/fs);

    % make carrier for one trial
    if strcmp(eventType,'noise')
        carrier = rand(size(t));

    elseif strcmp(eventType,'tone')
        carrier = sin(2*pi*t*f0);

    elseif strcmp(eventType,'click')
        carrier = zeros(size(t));

    end

    % make sure there is no clipping
    carrier = carrier .* max(abs(carrier));
end
