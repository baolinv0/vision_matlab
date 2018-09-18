function [list, lib] = showvipblockdatatypetable(Action)
%SHOWVIPBLOCKDATATYPETABLE Launch Computer Vision System Toolbox Data-type Support Table
%   Launch html page in help browser to show data type support and  
%   production intent information for Computer Vision System Toolbox.

% Copyright 2008 The MathWorks, Inc.

if nargin == 0
    Action = 'LaunchHTML';
end

switch Action
    case 'LaunchHTML'
        % main product library must be loaded in memory
        if isempty(find_system('SearchDepth', 0, 'CaseSensitive', ...
                'off', 'Name', 'visionlib'))
            disp(DAStudio.message('vision:bcst:LoadingVIPLib'));
            load_system('visionlib');
        end
        generateHTMLTable;
    
    case 'GetListandLib'
        list = 'vision.internal.librarylist';
        lib = 'visionlib';        
    otherwise
        warning(message('vision:bcst:unrecognizedAction'));
end

%--------------------------------------------------------------------------
%
%--------------------------------------------------------------------------
function generateHTMLTable

topModel = 'visionlib';
libData = [];

% Get the actual libraries from the blockset function.
allCaps = Capabilities; allCaps(1) = [];

libData.current = cell(0,0);
libData.open = [];
libData.hasLong = false;
dataIdx = 0;

libInfo  = vision.internal.librarylist;
doLongName = isfield(libInfo, 'formalNames');
if isfield(libInfo, 'formalName')
    libData.longs.(topModel) = libInfo.formalName;
end
for libIdx = 1:length(libInfo.current)
    dataIdx = dataIdx + 1;
    libName = libInfo.current{libIdx};
    libData.current{dataIdx} =libName ;
    libData.open(dataIdx) = isempty(find_system( ...
        'SearchDepth', 0, 'CaseSensitive', 'off', ...
        'Name', libName));
    % Get the translated library name, if any.
    if doLongName
        libData.longs.(libName) = libInfo.formalNames{libIdx};
        libData.hasLong = true;
    end
end

% Collect all the capabilities.
for libIdx = 1:length(libData.current)
    if libData.open(libIdx)
        load_system(libData.current{libIdx});
    end
    
    % make a call to simulink private function
    someCaps = sl('bcstExtractBlockCaps',libData.current{libIdx});
    if ~isempty(someCaps)
        allCaps(end+1:end+length(someCaps)) = someCaps;
    end
end

if isempty(allCaps)
    disp(DAStudio.message('Simulink:bcst:NoDataFound', ...
        regexprep(topModel, '\s', ' ')));
    return;
end

% make a call to simulink private function
h = sl('bcstMakeHtmlTable',topModel, allCaps, false, libData);

for libIdx = 1:length(libData.current)
    if libData.open(libIdx)
        close_system(libData.current{libIdx}, 0);
    end
end

status = web(['text://' h]);

switch status
    case 1
        errordlg(DAStudio.message('Simulink:bcst:ErrNoBrowser'));
    case 2
        errordlg(DAStudio.message('Simulink:bcst:ErrNoBrowserLaunch'));
    otherwise
        % No action, web browser launched successfully.
end
