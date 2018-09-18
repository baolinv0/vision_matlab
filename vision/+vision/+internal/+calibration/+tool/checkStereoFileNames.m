% checkStereoFileNames Perform error checking on stereo file names
%
% errorMsg = checkStereoFileNames(fileNames1, fileNames2, folder1, folder2)
% verifies that fileNames1 and fileNames2 are not empty and have the same
% length. errorMsg is a message object containing the appropriate error 
% message. If fileNames1 and fileNames2 are valid, errorMsg is set to [].

% Copyright 2014 The MathWorks, Inc.

function errorMsg = checkStereoFileNames(fileNames1, fileNames2, folder1, folder2)
if isempty(fileNames1)
    errorMsg = message('vision:caltool:noImagesFound', folder1);
elseif isempty(fileNames2)
    errorMsg = message('vision:caltool:noImagesFound', folder2);
    
elseif numel(fileNames1) ~= numel(fileNames2)
    % check that fileNames1 and fileNames2 have the same length
    errorMsg = message('vision:caltool:numberOfImagesMustBeTheSame');
else
    % no errors
    errorMsg = [];
end