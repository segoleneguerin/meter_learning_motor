function [mean_freq] = get_mean_freq(mX, freq, frex)
% Calculate the mean FFT amplitude over given frequencies.
% 
% Parameters
% ----------
% mX : array_like, shape = [nb_channel, nb_frequency]
%     Raw magnitude spectra with frequency as the last dimension. 
% freq : array_like
%     Frequencies for the FFT. 
% frex : array_like
%     Frequencies to take the snippets around. 
% 
% Returns 
% -------
% mean_freq : array_like, shape = [nb_channel, 1]
%     Mean FFT amplitude values for each channel.
%
% Author
% -------
% Ségolène M. R. Guérin, RnB Lab (IoNS, UCLouvain)
% Last update: September 15, 2023


%% COMPUTE MEAN FFT AMPLITUDE
% Find indices for the frequencies of interest
frex_idx = dsearchn(freq', frex'); 

% Extract data only for the frequencies of interest
mX_foi = mX(:,frex_idx);

% Change format if needed
if istable(mX_foi)
    mX_foi = table2array(mX_foi);
end

% Compute the mean over each row
mean_freq = mean(mX_foi, 2); 