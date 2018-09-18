function checkImageSequenceAndTimestampsAgreement(imgSequence,timestamps)
%checkImageSequenceAndTimestampsAgreement Checks consistency between the
%image sequence and timestamps. imgSequence can be a cell array of
%character vectors specifying image file names (image files must be in the
%same directory) or imageDatastore and timestamps must be a duration or
%double vector

% Copyright 2016 The MathWorks, Inc.

assert((iscellstr(imgSequence) || isa(imgSequence,'matlab.io.datastore.ImageDatastore')) && ...
    (isduration(timestamps) || isa(timestamps,'double')), 'Unexpected inputs');
    
if isa(imgSequence,'matlab.io.datastore.ImageDatastore')
    imgSequence = imgSequence.Files;
end

if numel(timestamps) ~= numel(imgSequence)
    error(message('vision:groundTruthDataSource:inconsistentTimestamps'));
end

end
