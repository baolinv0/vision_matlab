% triangulateMultiview triangulate 3-D locations of 2-D points matched across multiple views
%   xyzPoints = triangulateMultiview(pointTracks, cameraPoses, cameraParams) 
%   returns 3-D world points corresponding to points matched across 
%   multiple images taken with a calibrated camera.
%
%   Inputs:
%   -------
%   pointTracks   an N-element array of pointTrack objects, where each element
%                 contains two or more matching points across multiple images
%
%   cameraPoses   a table containing three columns: 'ViewId', 'Orientation'
%                 and 'Location'. Orientations are specified as 3-by-3 
%                 rotation matrices, and locations are specified as 
%                 3-element vectors. The view ids in point tracks refer to 
%                 the view ids in camPoses.
%
%   cameraParams  a cameraParameters or cameraIntrinsics object.  
%
%   Output:
%   -------
%   xyzPoints     an N-by-3 array of [x y z] coordinates of the 3-D world 
%                 points corresponding to the pointTracks.
%
%   [..., reprojectionErrors] = triangulateMultiview(...) additionally returns
%   reprojectionErrors, an N-element vector containing the mean reprojection error for
%   each 3-D world point.
%
%   Example 1: Scene recontruction from multiple views
%   --------------------------------------------------
%   % Load images
%   imageDir = fullfile(toolboxdir('vision'), 'visiondata', ...
%     'structureFromMotion');
%   images = imageDatastore(imageDir);
% 
%   % Load precomputed camera parameters.
%   load(fullfile(imageDir, 'cameraParams.mat'));
% 
%   % Compute features for the first image
%   I = rgb2gray(readimage(images, 1));
%   I = undistortImage(I, cameraParams);
%   pointsPrev = detectSURFFeatures(I);
%   [featuresPrev, pointsPrev] = extractFeatures(I, pointsPrev);
% 
%   % Load camera locations and orientations.
%   load(fullfile(imageDir, 'cameraPoses.mat'));
%
%   % Create a viewSet object
%   vSet = viewSet;
%   vSet = addView(vSet, 1, 'Points', pointsPrev, 'Orientation', ...
%       orientations(:,:,1), 'Location', locations(1,:));
% 
%   % Compute features and matches for the rest of the images
%   for i = 2:numel(images.Files)
%     I = rgb2gray(readimage(images, i));
%     I = undistortImage(I, cameraParams);
%     points = detectSURFFeatures(I);
%     [features, points] = extractFeatures(I, points);
%     vSet = addView(vSet, i, 'Points', points, 'Orientation', ...
%         orientations(:,:,i), 'Location', locations(i, :));
%     pairsIdx = matchFeatures(featuresPrev, features, 'MatchThreshold', 5);
%     vSet = addConnection(vSet, i-1, i, 'Matches', pairsIdx);
%     featuresPrev = features;
%   end
% 
%   % Find point tracks
%   tracks = findTracks(vSet);
%
%   % Get camera poses
%   cameraPoses = poses(vSet);
%
%   % Find 3-D world points
%   [xyzPoints, errors] = triangulateMultiview(tracks, cameraPoses, cameraParams);
%   z = xyzPoints(:,3);
%   idx = errors < 5 & z > 0 & z < 20;
%   pcshow(xyzPoints(idx, :), 'VerticalAxis', 'y', 'VerticalAxisDir', 'down', ...
%     'MarkerSize', 30);
%   hold on
%   plotCamera(cameraPoses, 'Size', 0.2);
%   hold off
% 
%   Example 2: Structure from motion from multiple views
%   ----------------------------------------------------
%   % This example shows you how to estimate the poses of a calibrated 
%   % camera from a sequence of views, and reconstruct the 3-D structure of
%   % the scene up to an unknown scale factor.
%   % <a href="matlab:web(fullfile(matlabroot,'toolbox','vision','visiondemos','html','StructureFromMotionFromMultipleViewsExample.html'))">View example</a>
%
%   See also triangulate, viewSet, pointTrack, matchFeatures, bundleAdjustment

% Copyright 2015 Mathworks, Inc.

% References:
%
% Hartley, Richard, and Andrew Zisserman. Multiple View Geometry in
% Computer Vision. Second Edition. Cambridge, 2000. p. 312

function [points3d, errors] = triangulateMultiview(pointTracks, ...
    camPoses, cameraParams)

outputType = validateInputs(pointTracks, camPoses, cameraParams);

numTracks = numel(pointTracks);
points3d = zeros(numTracks, 3);

numCameras = size(camPoses, 1);
cameraMatrices = containers.Map('KeyType', 'uint32', 'ValueType', 'any');

for i = 1:numCameras
    id = camPoses{i, 'ViewId'};
    R  = camPoses{i, 'Orientation'}{1};
    t  = camPoses{i, 'Location'}{1};
    cameraMatrices(id) = cameraMatrix(cameraParams, R', -t*R');
end
    
for i = 1:numTracks
    track = pointTracks(i);
    points3d(i, :) = triangulateOnePoint(track, cameraMatrices);    
end
points3d = cast(points3d, outputType);

if nargout > 1
    [~, errors] = reprojectionErrors(points3d, cameraMatrices, pointTracks);
    errors = cast(errors, outputType);
end

%--------------------------------------------------------------------------
function outputType = validateInputs(pointTracks, camPoses, cameraParams)

validateattributes(pointTracks, {'pointTrack'}, {'nonempty'}, mfilename);

outputType = validateAbsolutePoses(camPoses);

validateattributes(cameraParams, {'cameraParameters','cameraIntrinsics'}, ...
    {'scalar'}, mfilename);

%--------------------------------------------------------------------------
function outputType = validateAbsolutePoses(camPoses)
outputType = vision.internal.inputValidation.checkAbsolutePoses(...
    camPoses, mfilename, 'camPoses');

%--------------------------------------------------------------------------
function point3d = triangulateOnePoint(track, cameraMatrices)

viewIds = track.ViewIds;
points  = track.Points';
numViews = numel(viewIds);
A = zeros(numViews * 2, 4);

for i = 1:numViews
    % Check if the viewId exists
    if ~isKey(cameraMatrices, viewIds(i))
        error(message('vision:absolutePoses:missingViewId', viewIds(i)));
    end
    P = cameraMatrices(viewIds(i))';
    idx = 2 * i;
    A(idx-1:idx,:) = points(:, i) * P(3,:) - P(1:2,:);
end

[~,~,V] = svd(A);
X = V(:, end);
X = X/X(end);

point3d = X(1:3)';   

%--------------------------------------------------------------------------
function [errors, meanErrorsPerTrack] = reprojectionErrors(points3d, ...
    cameraMatrices, tracks)


numPoints = size(points3d, 1);
points3dh = [points3d, ones(numPoints, 1)];
meanErrorsPerTrack = zeros(numPoints, 1);
errors = [];
for i = 1:numPoints
    p3d = points3dh(i, :);
    reprojPoints2d = reprojectPoint(p3d, tracks(i).ViewIds, cameraMatrices);
    e = sqrt(sum((tracks(i).Points - reprojPoints2d).^2, 2));
    meanErrorsPerTrack(i) = mean(e);
    errors = [errors; e]; %#ok<AGROW>
end

%--------------------------------------------------------------------------
function points2d = reprojectPoint(p3dh, viewIds, cameraMatrices)
numPoints = numel(viewIds);
points2d = zeros(numPoints, 2);
for i = 1:numPoints
    p2dh = p3dh * cameraMatrices(viewIds(i));
    points2d(i, :) = p2dh(1:2) ./ p2dh(3);
end

