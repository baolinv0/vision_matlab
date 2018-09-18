function [mapName, relativePathToMapFile, found] = getBlockHelpMapNameAndPath(block_type)
%  Returns the mapName and the relative path to the maps file for this block_type

% Internal note: 
%   First column is the "System object name", corresponding to the block, 
%   Second column is the anchor ID, the doc uses for the block.
%   For core blocks, the first column is the 'BlockType'.

% Copyright 2007-2014 The MathWorks, Inc.
    
    blks = {'vision.internal.blocks.Warp'    'cvstwarp'};

relativePathToMapFile = '/vision/vision.map';
found = false;
% See whether or not the block is a DSP System Toolbox core or built-in
i = strmatch(block_type, blks(:,1), 'exact');

if isempty(i)
    mapName = 'User Defined';
else
    found = true;
    mapName = blks(i,2);
end