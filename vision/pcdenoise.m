function [ptCloudOut, inlierIndices, outlierIndices] = pcdenoise(ptCloudIn, varargin)
%PCDENOISE Remove noise from a 3-D point cloud.
%   ptCloudOut = PCDENOISE(ptCloudIn) returns a filtered point cloud that
%   removes outliers. ptCloudIn and ptCloudOut are point cloud objects. A
%   point is considered to be an outlier if the average distance to its K
%   nearest neighbors is above a threshold. By default, the threshold is
%   chosen to be one standard deviation from the mean of average distance
%   to neighbors of all points.
%
%   [..., inlierIndices, outlierIndices] = PCDENOISE(...) additionally
%   returns the linear indices to the points that are identified as inliers
%   and outliers.
%
%   [...] = PCDENOISE(..., Name, Value) specifies additional name-value
%   pairs described below:
%
%   'NumNeighbors'     A positive integer specifying the number of nearest
%                      neighbors used to estimate the mean distance. A
%                      small value tend to be sensitive to the noise, while
%                      a large value is more computationally expensive.
%
%                      Default: 4
%                       
%   'Threshold'        A scalar specifying the number of standard deviation
%                      away from the mean distance. Decrease this value to
%                      remove more points.
%
%                      Default: 1.0
%
%   Class Support 
%   ------------- 
%   ptCloudIn and ptCloutOut must be pointCloud object. inlierIndices and
%   outlierIndices are uint32.
% 
%   Example: Remove outliers from a noisy point cloud
%   -------------------------------------------------
%   % Create a plane point cloud
%   gv = 0:0.01:1;
%   [X,Y] = meshgrid(gv,gv);
%   ptCloud = pointCloud([X(:),Y(:),0.5*ones(numel(X),1)]);
%
%   figure
%   pcshow(ptCloud);
%   title('Original Data');
%
%   % Add uniformly distributed random noise
%   noise = rand(500, 3);
%   ptCloudA = pointCloud([ptCloud.Location; noise]);
%
%   figure
%   pcshow(ptCloudA);
%   title('Noisy Data');
%
%   ptCloudB = pcdenoise(ptCloudA);
%
%   figure;
%   pcshow(ptCloudB);
%   title('Denoised Data');
%
% See also pointCloud, pcshow, pctransform, pcdownsample, pcmerge
 
%  Copyright 2014 The MathWorks, Inc.
%
% References
% ----------
% R. B. Rusu, Z. C. Marton, N. Blodow, M. Dolha, and M. Beetz. Towards 3D
% Point Cloud Based Object Maps for Household Environments Robotics and
% Autonomous Systems Journal (Special Issue on Semantic Knowledge), 2008

narginchk(1, 5);

% Parse the inputs
[numNeighbors, threshold] = validateAndParseInputs(ptCloudIn, varargin{:});

if ~ismatrix(ptCloudIn.Location)
    points = reshape(ptCloudIn.Location, [], 3);
else
    points = ptCloudIn.Location;
end

% Compute the mean distance to neighbors for every point, and exclude the
% query point itself
[~, dists, valids] = multiQueryKNNSearchImpl(ptCloudIn, points, numNeighbors+1);
% This multi-query KNN search uses exact search so every query should
% return the same number of neighbors if the query is a valid point
actualNums = double(max(valids(:))-1);
meanDist = sum(dists(2:actualNums, :),1)/actualNums;

isValidPoints = isfinite(points);
isValidPoints = sum(isValidPoints,2)==3;
meanDist(~isValidPoints) = NaN;

% Compute the threshold
finiteMeanDist = meanDist(isfinite(meanDist));

meanD = mean(finiteMeanDist);
stdD = std(finiteMeanDist);
distThreshold = meanD+threshold*stdD;

% Select the inliers
tf = meanDist <= distThreshold;
inlierIndices = uint32(find(tf));
[loc, color, nv] = subsetImpl(ptCloudIn, inlierIndices);
ptCloudOut = pointCloud(loc, 'Color', color, 'Normal', nv);

if nargout == 3
    outlierIndices = uint32(find(~tf));
end

end

function [numNeighbors, threshold] = validateAndParseInputs(ptCloudIn, varargin)
% Validate the first argument
if ~isa(ptCloudIn, 'pointCloud')
    error(message('vision:pointcloud:notPointCloudObject', 'ptCloudIn'));
end

% Validate and parse optional inputs
parser = inputParser;
parser.CaseSensitive = false;
parser.FunctionName  = mfilename;

parser.addParameter('NumNeighbors', 4, @(x)validateattributes(x,{'single', 'double'}, {'scalar','integer','positive'}));
parser.addParameter('Threshold', 1.0, @(x)validateattributes(x,{'single', 'double'}, {'scalar','real','finite'}));

parser.parse(varargin{:});

numNeighbors = parser.Results.NumNeighbors;
threshold = parser.Results.Threshold;

end          