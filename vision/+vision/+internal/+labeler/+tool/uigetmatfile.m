function [fileName, pathName, userCanceled] = uigetmatfile(initialPath, title)
%uigetmatfile open file dialog for importing MAT files.

% Copyright 2016 The MathWorks, Inc.
persistent cached_path;

% Create file chooser if necessary;
need_to_initialize_path = isempty(cached_path);
if need_to_initialize_path
    cached_path = '';
end

filterSpec = {'*.mat', 'MAT-files (*.mat)'};

if(isempty(initialPath))
    [fileName, pathName, filterIndex] = uigetfile(filterSpec,...
                                title,...
                                cached_path);
else
    [fileName, pathName, filterIndex] = uigetfile(filterSpec,...
                                title,...
                                initialPath);
end

userCanceled = (filterIndex == 0);

if ~userCanceled
    cached_path = pathName;
else
    fileName = '';
end