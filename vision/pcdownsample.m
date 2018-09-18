function ptCloudOut = pcdownsample(ptCloudIn, varargin)
%PCDOWNSAMPLE Downsample a 3-D point cloud.
%   ptCloudOut = PCDOWNSAMPLE(ptCloudIn, 'random', percentage)
%   returns a downsampled point cloud with random sampling without
%   replacement. ptCloudIn and ptCloudOut are pointCloud objects.
%   percentage specifies the portion of the input to be returned.
%
%   ptCloudOut = PCDOWNSAMPLE(ptCloudIn, 'gridAverage', gridStep)
%   returns a downsampled point cloud using box grid filter. gridStep
%   specifies the size of a 3-D box. Points within the same box are merged
%   to a single point in the output. Their color and normal properties are
%   averaged accordingly. This method better preserves the shape of the
%   point cloud.
%
%   ptCloudOut = PCDOWNSAMPLE(ptCloudIn, 'nonuniformGridSample',
%   maxNumPoints) returns a downsampled point cloud using a nonuniform box
%   grid filter. maxNumPoints must be at least 6, and specifies the maximum
%   number of points in a grid box. The method randomly selects a single
%   point from each box. This method will automatically fill in the normal
%   property of ptCloudOut object if the normal is not already provided.
%
%   Notes
%   -----
%   - The best use of nonuniformGridSample method is to apply it as a 
%     preprocessing step to pcregrigid when the 'pointToPlane' metric is
%     used.
%   - An important property of nonuniformGridSample algorithm is that the
%     normals are computed on the original data prior to downsampling. The
%     downsampled output preserves the more accurate normals.
%
%   Class Support 
%   ------------- 
%   ptCloudIn and ptCloudOut must be pointCloud object. 
% 
%   Example 1: Downsample a point cloud with box grid filter 
%   --------------------------------------------------------
%   ptCloud = pcread('teapot.ply');
%
%   % Set the 3D resolution to be 0.1-by-0.1-by-0.1 
%   gridStep = 0.1;
%   ptCloudA = pcdownsample(ptCloud, 'gridAverage', gridStep);
%
%   % Visualize the downsampled data
%   figure
%   pcshow(ptCloudA);
%
%   % Compare to downsampling with fixed step size
%   stepSize = floor(ptCloud.Count/ptCloudA.Count);
%   indices = 1:stepSize:ptCloud.Count;
%   ptCloudB = select(ptCloud, indices);
%
%   figure
%   pcshow(ptCloudB);
%
%   Example 2: Remove redundant points
%   ----------------------------------
%   % Create a point cloud with all points sharing the same coordinates
%   ptCloud = pointCloud(ones(100,3));
%
%   % Set the 3-D resolution to be a small value
%   gridStep = 0.01;
%   % The output now only has one unique point
%   ptCloudOut = pcdownsample(ptCloud, 'gridAverage', gridStep);
%
% See also pointCloud, pcshow, pcregrigid, pctransform
 
%  Copyright 2014 The MathWorks, Inc.
%
% References
% ----------
% François Pomerleau, Francis Colas, Roland Siegwart, Stéphane Magnenat, 
% Comparing ICP variants on real-world data sets, Autonomous Robots, 
% April 2013, Volume 34, Issue 3, pp 133-148

narginchk(3, 3);

% Validate the first argument
if ~isa(ptCloudIn, 'pointCloud')
    error(message('vision:pointcloud:notPointCloudObject', 'ptCloudIn'));
end

% Validate the method argument
strMethod = validatestring(varargin{1}, {'random','gridAverage','nonuniformGridSample'}, mfilename);   

if strncmpi(strMethod, 'random', 1)
    % Validate the third argument
    percentage = varargin{2};
    validateattributes(percentage, {'single','double'}, {'scalar', 'real', '>=', 0, '<=', 1}, mfilename, 'percentage');
    
    K = round(ptCloudIn.Count*percentage);
    indices = vision.internal.samplingWithoutReplacement(ptCloudIn.Count, K);
    [points, color, normal] = subsetImpl(ptCloudIn, indices);
elseif strncmpi(strMethod, 'gridAverage', 1)
    % Validate the third argument
    gridStep = varargin{2};
    validateattributes(gridStep, {'single','double'}, {'scalar', 'real', 'positive'}, mfilename, 'gridStep');
    
    % Remove invalid points to determine a bounded volume
    pc = removeInvalidPoints(ptCloudIn);
    rangeLimits = [pc.XLimits, pc.YLimits, pc.ZLimits];
    
    % Apply grid filter to each property
    [points, color, normal] = visionVoxelGridFilter(pc.Location, ...
                                                    pc.Color, ...
                                                    pc.Normal, ...
                                                    gridStep, rangeLimits);
else
    % Validate the third argument
    maxNumPoints = varargin{2};
    % The maximum number of points needs to be at least 6 because we need
    % to compute normals using PCA.
    validateattributes(maxNumPoints, {'single','double'}, {'scalar', 'real', 'integer', '>=', 6}, mfilename, 'maxNumPoints');
    
    % Remove invalid points to determine a bounded volume
    pc = removeInvalidPoints(ptCloudIn);
    
    % Apply nonuniformGridSample filter to location property and generate
    % normal if it does not exist
    if ~isempty(pc.Normal)
        indices = visionNonUniformVoxelGridFilter(pc.Location, maxNumPoints);
        [points, color, normal] = subsetImpl(pc, indices);
    else
        [indices, normal] = visionNonUniformVoxelGridFilter(pc.Location, maxNumPoints);
        [points, color] = subsetImpl(pc, indices);
    end
end
ptCloudOut = pointCloud(points, 'Color', color, 'Normal', normal);

