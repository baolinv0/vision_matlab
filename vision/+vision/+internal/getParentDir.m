% getParentDir Parent directory
%   parentDir = getParentDir(inputDir) returns the parent directory of the
%   inputDir, which must be a full path. The function works for windows and
%   unix paths.

% Copyright 2014 The MathWorks, Inc.

function parentDir = getParentDir(inputDir)

if isRoot(inputDir)
    parentDir = inputDir;
    return;
end

inputDirOrig = inputDir;

% Strip off the trailing file separator
if inputDir(end) == '\' || inputDir(end) == '/'
    inputDir = inputDir(1:end-1);
end

% Find the first file separator from the end
idx = regexp(inputDir, '(\/|\\)(\w|\s)+$');
if isempty(idx)
    % if no separator is found, return the input
    parentDir = inputDirOrig;
else
    parentDir = inputDir(1:idx);
end

%--------------------------------------------------------------------------
function tf = isRoot(inputDir)
tf = strcmp(inputDir, '/') || strcmp(inputDir, '\\') || inputDir(end-1) == ':';
