function [outData] = blobAnalysisBlockTransform(inData)
% blobAnalysisBlockTransform preserves functionality for legacy Blob Analysis block.
%
%   This is an internal function called by Simulink(R) during model load.

% Copyright 2016 The MathWorks, Inc.

newInstanceData = inData.InstanceData;

for index=1:length(newInstanceData)
    if strcmp(newInstanceData(index).Name, 'outDT')
        if strcmp(newInstanceData(index).Value, 'specify via Fixed-point tab')
            newInstanceData(index).Value = 'Specify via Data Types tab';
            break;
        end
    end
end

outData.NewInstanceData = newInstanceData;
outData.NewBlockPath    = inData.ForwardingTableEntry.('__slOldName__');
