%
% This function allows you to manually add or remove taps that would not
% have been correctly detected

% Inputs
% ----------
% timeVec           = time vector (in s and horizontal format)
% fs                = sampling frequency (in Hz)
% clapping_signal   = time serie of the clapping
% claps             = previous detection of the claps by the findpeak function (in s and vertical format)
% peak_amp          = previous detection of the clap amplitudes by the findpeak function (in μV and vertical format)
% participant       = participant number
% group             = group number 
% condition         = condition number

% Output
% ----------
% claps = updated version of the detected claps (in s)

% Author
% -------
% Emmanuel Coulon & Ségolène M. R. Guérin
% June 10, 2024
% RnB-Lab (Institute of Neuroscience, UCLouvain)
%

function [claps, peak_amp] = tap_corrector_smt(timeVec, fs, clapping_signal, claps, peak_amp, participant, group, condition)

% Plot figure
figure('Position',[1 1 1200 800], 'Color', [1 1 1], 'Name','Check taps to add/remove')
plot(timeVec, clapping_signal,'k', 'LineWidth', 1); hold on
h1 = scatter(claps, peak_amp, 'b', 'filled');
set(gca, 'LineWidth', 1.5, 'FontSize', 15, 'TickDir', 'out')
box off
title(['Participant ',num2str(participant),' - group ', num2str(group),' - condition ', num2str(condition)])

qst = questdlg('Would you like to add/remove claps?','','Yes','No','No');

while strcmp(qst,'Yes')

    % Manually select the region where you would like to add/remove a tap
    selectedRange    = ginput(2);
    selectedRangeIdx = [round(selectedRange(1,1)*fs) : round(selectedRange(2,1)*fs)];

    % Find if a tap is comprised in the selected region
    pos = dsearchn(timeVec(selectedRangeIdx)',claps);
    pos (pos == 1) = [];
    pos (pos == length(selectedRangeIdx)) = [];


    if ~isempty(pos) % if a tap was present in the selectedRange => remove tap

        % find the Idx to remove
        tapIdx2remove           = dsearchn(claps, timeVec(selectedRangeIdx(pos))');
        claps(tapIdx2remove)    = [];
        peak_amp(tapIdx2remove) = [];

    else % if a tap was absent in the selectedRange => add tap

        % find the max of the signal
        [tapAmp2add,tapIdx2add] = max(clapping_signal(selectedRangeIdx));
        claps(end+1)            = timeVec(selectedRangeIdx(tapIdx2add));
        [claps, clap_order]     = sort(claps);
        peak_amp(end+1)         = tapAmp2add;
        peak_amp                = peak_amp(clap_order, :);

    end

    delete(h1)
    h1 = scatter(claps, peak_amp,'b', 'filled');

    qst = questdlg('Would you like to add/remove claps?','','Yes','No','No');
end

close all

end

