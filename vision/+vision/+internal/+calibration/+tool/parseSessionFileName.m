function [sessionPath, sessionFileName] = parseSessionFileName(sessionFileName)
% parseSessionFileName parses the file name of a calibration session
%   [sessionPath, sessionFileNameOut] = parseSessionFileName(sessionFileNameIn)
%   returns the path and the name of the session file.

%   Copyright 2014 The MathWorks, Inc.
[~, ~, ext] = fileparts(sessionFileName);

if isempty(ext)
    sessionFileName = [sessionFileName, '.mat'];
elseif ~strcmpi(ext,'.mat')
   error(message('vision:trainingtool:InvalidInput',sessionFileName));
end

sessionFileName = vision.internal.getFullPath(sessionFileName);
[sessionPath, sessionFileName, ext] = fileparts(sessionFileName);
sessionFileName = [sessionFileName, ext];
sessionPath = [sessionPath, filesep()];