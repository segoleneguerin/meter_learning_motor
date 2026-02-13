%% FUNCTION FROM TOMAS (TempoRhythm Project) %%
% Downloaded on December 2, 2022
% https://github.com/TomasLenc/TempoRhythm_PTB

function soundOnsetTimes = getSoundOnsetTimes(pat, nCycles, gridIOI, varargin)
                                        

if any(strcmp(varargin,'deviantCycles'))
    deviantCycles = varargin{find(strcmp(varargin,'deviantCycles'))+1}; 
end

if any(strcmp(varargin,'changeDirection'))
    changeDirection = varargin{find(strcmp(varargin,'changeDirection'))+1}; 
end

if any(strcmp(varargin,'changeMagn'))
    changeMagn = varargin{find(strcmp(varargin,'changeMagn'))+1}; 
end

nEvents = length(pat); 

gridIOIs = repmat(gridIOI, 1, nCycles*nEvents); 

if ~isempty(varargin)
        
    for cycle=deviantCycles
        
        if strcmpi(changeDirection,'faster')
            gridIOIs( (cycle-1)*nEvents+1 : cycle*nEvents ) = gridIOI - gridIOI*changeMagn; 
        elseif strcmpi(changeDirection,'slower')
            gridIOIs( (cycle-1)*nEvents+1 : cycle*nEvents ) = gridIOI + gridIOI*changeMagn; 
        end
        
    end
    
end

gridTimes = cumsum(gridIOIs)-gridIOIs(1); 

patWholeSeq = repmat(pat, 1, nCycles); 

soundOnsetTimes = gridTimes(logical(patWholeSeq));


