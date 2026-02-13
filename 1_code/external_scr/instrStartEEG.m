%% SCRIPT FROM TOMAS (TempoRhythm Project) %%
% Downloaded on December 2, 2022
% https://github.com/TomasLenc/TempoRhythm_PTB

function instrStartEEG(cfg)

PTB_printNewLine('thick')

fprintf(['\n', ...
		'\t\t... START EEG RECORDING ...\n\n\n', ...
		'Please setup a new EEG recording and start acquisition in ActiView. \n\n', ...
		'   !! DO NOT PAUSE THE RECORDING FROM THIS POINT IF AVOIDABLE !!\n', ...
		'(pausing will make it impossible to interpret onset timing logs in event file)\n', ...
		'(this would not be a disaster, but could make life a bit difficult)\n\n\n']); 


PTB_printNewLine('thin')
fprintf(['Make sure you are using the following montage: \n']); 
fprintf(['\t-> 64 channels (10/20 standard, A+B inputs) \n', ...
         '\t-> +2 electrodes on mastoids (plug left into EXT1 and right into EXT2) \n, ...' ...
         '\t-> accelerometer (Ergo input) \n\n\n'])
  

fileName = strrep(cfg.fileName.events, '_events', ['_eeg']); 
fileName = strrep(fileName, '.tsv', '.bdf');
PTB_printNewLine('thin')
fprintf('Filename: \n%s\n', fileName)

PTB_printNewLine('thin')
fprintf('...press SPACE when ready...\n\n')