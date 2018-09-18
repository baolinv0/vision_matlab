% getFullPath Full path to a file or directory
%  fullPath = getFullPath(file) returns the full path to file. file is a
%  file or folder name specified as a string.

%   Copyright 2016 The MathWorks, Inc.
function fullPath = getFullPath(file)
[success, attr,MESSAGEID] = fileattrib(file);
if success    
    fullPath = attr.Name;
else
    % Rethrow as error
    error(MESSAGEID,getString(message(MESSAGEID)));
end
    