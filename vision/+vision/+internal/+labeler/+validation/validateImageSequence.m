function validateImageSequence(images, hasTimeStamps)
%validateImageSequence Validates image files. 
%imgSequence can be a cell array of character vectors specifying image file
%names (image files must be in the same directory) or imageDatastore.

% Copyright 2016 The MathWorks, Inc.

assert(iscellstr(images) || isa(images,'matlab.io.datastore.ImageDatastore'),...
    'Unexpected input');

if isa(images,'matlab.io.datastore.ImageDatastore')
    images = images.Files;
end

% Check files are in same directory only for images w/ time stamps
if nargin == 2 && hasTimeStamps
    pathName = fileparts(images{1});
    
    % All image files must belong to the same path.
    for n = 2:numel(images)
        if ~strcmp(pathName,fileparts(images{n}))
            error(message('vision:groundTruthDataSource:expectedSameDir'))
        end
    end
end
end
