% checkStereoFolders Perform error checking on a pair of stereo folders
%
% errorMsg = checkStereoFolders(folder1, folder2) verifies that folder1 and
% folder2 both exist and are not the same. errorMsg is a message object
% containing the appropriate error message. If the two folders are valid,
% errorMsg is set to [].

% Copyright 2014 The MathWorks, Inc.

function errorMsg = checkStereoFolders(folder1, folder2)
if isequal(folder1, folder2)
    % check that dir1 and dir2 are different
    errorMsg = message('vision:caltool:stereoFoldersMustBeDifferent');
    
elseif ~exist(folder1, 'dir')
    % check that Dir1 exists
    errorMsg = message('vision:caltool:stereoFolderDoesNotExist', folder1);
    
elseif ~exist(folder2, 'dir')
    % check that Dir2 exists
    errorMsg = message('vision:caltool:stereoFolderDoesNotExist', folder2);
else
    errorMsg = [];
end