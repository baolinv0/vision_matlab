%==========================================================================
% Initialize RANSAC status code and extract valid points from point cloud
%==========================================================================
function [statusCode, status, pc, validPtCloudIndices] = ...
                initializeRansacModel(ptCloud, sampleIndices, sampleSize)

% List of status code
statusCode = struct(...
    'NoError',           int32(0),...
    'NotEnoughPts',      int32(1),...
    'NotEnoughInliers',  int32(2));

% Extract valid points from point cloud
if ~isempty(sampleIndices)
    pc = select(ptCloud, sampleIndices);
    [pc, indices] = removeInvalidPoints(pc);
    validPtCloudIndices = sampleIndices(indices);
else
    [pc, validPtCloudIndices] = removeInvalidPoints(ptCloud);
end

if pc.Count < sampleSize
    status = statusCode.NotEnoughPts;
else
    status = statusCode.NoError;
end

