function ptCloudOut = pcmerge(ptCloudA, ptCloudB, gridStep)
%PCMERGE Merge two 3-D point clouds.
%   ptCloudOut = PCMERGE(ptCloudA, ptCloudB, gridStep) returns a
%   merged point cloud using box grid filter. ptCloudA, ptCloudB and
%   ptCloudOut are pointCloud objects. 'gridStep' specifies the size of a
%   3-D box. Points within the same box in the overlapped region are merged
%   to a single point in the output. Their color and normal properties are
%   averaged accordingly.
%
%   Notes 
%   ----- 
%   - Points with NaN or Inf coordinates will be filtered out. 
%
%   - If the two point clouds do not have the same set of properties
%     filled, such as Color or Normal, these properties will be cleared in
%     the returned point cloud. For example, if ptCloudA has color but
%     ptCloudB does not, then ptCloudOut will not contain color.
%
%   Class Support 
%   ------------- 
%   ptCloudA, ptCloudB and ptCloutOut must be pointCloud object. gridStep
%   must be single or double.
% 
%   Example: Merge two identical point clouds with box grid filter 
%   -------------------------------------------------------------- 
%   ptCloudA = pointCloud(100*rand(1000,3));
%   ptCloudB = copy(ptCloudA);
%
%   ptCloud = pcmerge(ptCloudA, ptCloudB, 1);
%   pcshow(ptCloud);
%
% See also pointCloud, pcshow, pctransform, pcdownsample
 
%  Copyright 2014 The MathWorks, Inc.

% Validate input arguments
if ~isa(ptCloudA, 'pointCloud')
    error(message('vision:pointcloud:notPointCloudObject', 'ptCloudA'));
end
if ~isa(ptCloudB, 'pointCloud')
    error(message('vision:pointcloud:notPointCloudObject', 'ptCloudB'));
end
validateattributes(gridStep, {'single','double'}, {'scalar', 'real', 'positive'}, mfilename, 'gridStep');

% Remove invalid points to determine a bounded volume
pcA = removeInvalidPoints(ptCloudA);
pcB = removeInvalidPoints(ptCloudB);

if (isempty(pcA.Location) && isempty(pcB.Location))
    ptCloudOut = pcA;
elseif (isempty(pcA.Location) && ~isempty(pcB.Location))
    ptCloudOut = pcB;
elseif (isempty(pcB.Location) && ~isempty(pcA.Location))
    ptCloudOut = pcA;    
else
    % Combine two inputs
    points = vertcat(pcA.Location, pcB.Location);
    color = vertcat(pcA.Color, pcB.Color);
    if numel(color) ~= numel(points)
        color = uint8.empty;
    end
    normal = vertcat(pcA.Normal, pcB.Normal);
    if numel(normal) ~= numel(points)
        normal = cast([], 'like', points);
    end

    % Only averaging the points in overlapped region
    rangeLimits = overlapRange(pcA, pcB);
    
    if ~isempty(rangeLimits)
        % Apply grid filter to each property
        [points, color, normal] = visionVoxelGridFilter(points, color, normal, gridStep, rangeLimits);
    end
    
    ptCloudOut = pointCloud(points, 'Color', color, 'Normal', normal);
end

end

%==========================================================================
% Compute the bounding box of overlapped region
%==========================================================================
function rangeLimits = overlapRange(pcA, pcB)
xlimA = pcA.XLimits;
ylimA = pcA.YLimits;
zlimA = pcA.ZLimits;

xlimB = pcB.XLimits;
ylimB = pcB.YLimits;
zlimB = pcB.ZLimits;

if (xlimA(1) > xlimB(2) || xlimA(2) < xlimB(1) || ...
    ylimA(1) > ylimB(2) || ylimA(2) < ylimB(1) || ...    
    zlimA(1) > zlimB(2) || zlimA(2) < zlimB(1))
    % No overlap
    rangeLimits = [];
else
    rangeLimits = [ max(xlimA(1),xlimB(1)), min(xlimA(2),xlimB(2)) ...
                    max(ylimA(1),ylimB(1)), min(ylimA(2),ylimB(2)) ...
                    max(zlimA(1),zlimB(1)), min(zlimA(2),zlimB(2))];
end
end