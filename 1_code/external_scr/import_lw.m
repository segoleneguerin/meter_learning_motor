%
% Load the required version of LetsWave.
% 
% Parameters
% ----------
% integral number:
%   6 = import LetsWave 6
%   7 = import LetsWave 7
%   -1 = remove everything from path
%
% Author 
% -------
% Tomas Lenc
% Modified by Ségolène M. R. Guérin (April 16, 2024)
% RnB-Lab (Institute of Neuroscience, UCLouvain)
%

function import_lw(varargin)

par = meterlearning_motor_get_params();

if nargin == 1 && varargin{1} == -1
    warning('off')
    rmpath(genpath(par.letswave6_path)); 
    rmpath(genpath(par.letswave7_path)); 
    fprintf('\nremoving everything from path...\n\n'); 
    warning('on')
    return
end

if nargin == 1 && varargin{1} == 7
    warning('off')
    rmpath(genpath(par.letswave6_path)); 
    addpath(genpath(par.letswave7_path)); 
    fprintf('\nadding LW7 to path...\n\n'); 
    warning('on')
    return
end

if nargin == 1 && varargin{1} == 6
    warning('off')
    addpath(genpath(par.letswave6_path)); 
    rmpath(genpath(par.letswave7_path)); 
    fprintf('\nadding LW6 to path...\n\n'); 
    warning('on')
    return
end