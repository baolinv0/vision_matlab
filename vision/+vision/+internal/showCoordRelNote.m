% showCoordRelNote Displays R2011b release note.
%   Displays R2011b release note about the coordinate system change.

% Copyright 2011 The MathWorks, Inc.

function showCoordRelNote

mapfile_location = fullfile(docroot,'toolbox','vision','vision.map');

doc_tag = 'visioncoordinatenote';

helpview(mapfile_location, doc_tag);

