%
% Computes the vector strength (circular stats) on the asynchrony 
% between claps and the learning cues.
% 
% Parameters
% ----------
% participant: integral number
%   Participant to process.
% asynchrony: array
%   Asynchrony between claps and the learning cues (in sec)
% locs_sound_sec
%   Onsets of the learning cues tracker (in sec)
%
% Outputs 
% -------
% The function returns a vector strength value.
%
% Author
% -------
% Emmanuel Coulon
% February 13, 2026
% RnB-Lab (Institute of Neuroscience, UCLouvain)

function R = meterlearning_motor_asynch_vector_strength(participant, asynch, locs_sound_sec)


%% ---- PREAMBLE
% Load parameters file
params = meterlearning_motor_get_params(); 

% Load participants allocation file
alloc_file = readtable(fullfile(params.experiment_path, ...
    '0_data/meterlearning-motor_participant_allocation.xlsx')); 

% Extract group and condition
group       = table2array(alloc_file(participant, 2));
condition   = table2array(alloc_file(participant, 3));



%% ---- VECTOR STRENGTH COMPUTATION

% Get the target interval
IOI = locs_sound_sec(2)-locs_sound_sec(1);

% get the asynchronies in degrees
circ_asynch = (asynch/IOI) * 360;

% get the offset in rad
circ_rad_asynch = deg2rad(circ_asynch);

% get the sin and cos
clap_cos = cos(circ_rad_asynch);
clap_sin = sin(circ_rad_asynch);

Rx = mean(clap_cos);
Ry = mean(clap_sin);

% compute vector strength
R = sqrt(Rx^2+Ry^2);

% get the correct angle
if Rx > 0 && Ry > 0 % first quadrant
    theta = abs(atan(Ry/Rx));
elseif Rx < 0 && Ry > 0 % second quadrant
    theta = pi - abs(atan(Ry/Rx));
elseif Rx < 0 && Ry < 0 % third quadrant
    theta = pi + abs(atan(Ry/Rx));        
elseif Rx > 0 && Ry < 0 % fourth quadrant
    theta = - abs(atan(Ry/Rx));    
end

thetaDeg = rad2deg(theta);


end

