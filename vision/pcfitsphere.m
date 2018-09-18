function [model, inlierIndices, outlierIndices, meanError] = pcfitsphere(varargin)
%PCFITSPHERE Fit sphere to a 3-D point cloud.
%   model = PCFITSPHERE(ptCloud, maxDistance) fits a sphere to the point
%   cloud, ptCloud. The sphere is described by a sphereModel object.
%   maxDistance is a maximum allowed distance from an inlier point to the
%   sphere. This function uses the M-estimator SAmple Consensus (MSAC)
%   algorithm to find the sphere.
%
%   [..., inlierIndices, outlierIndices] = PCFITSPHERE(...) additionally
%   returns linear indices to the inlier and outlier points in ptCloud.
%
%   [..., meanError] = PCFITSPHERE(...) additionally returns mean error of
%   the distance of inlier points to the model.
%
%   [...] = PCFITSPHERE(..., Name,Value) specifies additional name-value
%   pair arguments described below:
%
%   'SampleIndices'       A vector specifying the linear indices of points
%                         to be sampled in the input point cloud. The
%                         indices, for example, can be generated by
%                         findPointsInROI method of pointCloud object.
%                         By default, the entire point cloud is processed.
%
%                         Default: []
%
%   'MaxNumTrials'        A positive integer scalar specifying the maximum
%                         number of random trials for finding the inliers.
%                         Increasing this value will improve the robustness
%                         of the output at the expense of additional
%                         computation.
% 
%                         Default: 1000
%  
%   'Confidence'          A numeric scalar, C, 0 < C < 100, specifying the
%                         desired confidence (in percentage) for finding
%                         the maximum number of inliers. Increasing this
%                         value will improve the robustness of the output
%                         at the expense of additional computation.
%
%                         Default: 99
%
%   Class Support 
%   ------------- 
%   ptCloud must be pointCloud object. 
% 
%   Example: Detect sphere from point cloud
%   ---------------------------------------
%   load('object3d.mat');
%  
%   figure
%   pcshow(ptCloud)
%   xlabel('X(m)')
%   ylabel('Y(m)')
%   zlabel('Z(m)')
%   title('Original Point Cloud')
% 
%   % Set the maximum point-to-sphere distance (1cm) for sphere fitting
%   maxDistance = 0.01;
% 
%   % Set the roi to constrain the search
%   roi = [-inf, 0.5, 0.2, 0.4, 0.1, inf];
%   sampleIndices = findPointsInROI(ptCloud, roi);
% 
%   % Detect the globe and extract it from the point cloud
%   [model, inlierIndices] = pcfitsphere(ptCloud, maxDistance,...
%                         'SampleIndices', sampleIndices);
%   globe = select(ptCloud, inlierIndices);
% 
%   % Plot the globe
%   hold on
%   plot(model)
%
%   figure
%   pcshow(globe)
%   title('Globe Point Cloud')
%
% See also pointCloud, pointCloud>findPointsInROI, sphereModel, pcfitplane, 
%          pcfitcylinder, pcshow

%  Copyright 2015 The MathWorks, Inc.
%
% References:
% ----------
%   P. H. S. Torr and A. Zisserman, "MLESAC: A New Robust Estimator with
%   Application to Estimating Image Geometry," Computer Vision and Image
%   Understanding, 2000.

% Parse input arguments
[ptCloud, ransacParams, sampleIndices] = ...
    vision.internal.ransac.validateAndParseRansacInputs(mfilename, false,...
    varargin{:});

% Use four points to fit a sphere
sampleSize = 4;

% Initialization
[statusCode, status, pc, validPtCloudIndices] = ...
    vision.internal.ransac.initializeRansacModel(ptCloud, sampleIndices, ...
    sampleSize);

ransacParams.sampleSize = sampleSize;

% Compute the geometric model parameter with MSAC
if status == statusCode.NoError
    ransacFuncs.fitFunc = @fitSphere;
    ransacFuncs.evalFunc = @evalSphere;
    ransacFuncs.checkFunc = @checkSphere;

    [isFound, modelParams] = vision.internal.ransac.msac(pc.Location, ...
        ransacParams, ransacFuncs);
    
    if ~isFound
        status = statusCode.NotEnoughInliers;
    end
end

if status == statusCode.NoError
    % Construct the sphere object
    model = sphereModel(modelParams);
else
    model = sphereModel();
end

% Report runtime error
vision.internal.ransac.checkRansacRuntimeStatus(statusCode, status);

% Extract inliers
needInlierIndices = (nargout > 1);
needOutlierIndices = (nargout > 2);
needMeanError = (nargout > 3);
if needInlierIndices
    if status == statusCode.NoError
        % Re-evaluate the best model
        if ~isempty(sampleIndices)
            [pc, validPtCloudIndices] = removeInvalidPoints(ptCloud);
        end
        distances = evalSphere(modelParams, pc.Location);
        inlierIndices = ...
            validPtCloudIndices(distances < ransacParams.maxDistance);
    else
        inlierIndices = [];
    end
end
% Extract outliers
if needOutlierIndices
    if status == statusCode.NoError
        flag = true(ptCloud.Count, 1);
        flag(inlierIndices) = false;
        outlierIndices = find(flag);
    else
        outlierIndices = [];
    end
end
% Report MeanError
if needMeanError
    if status == statusCode.NoError
        meanError = mean(distances(distances < ransacParams.maxDistance));
    else
        meanError = [];
    end
end

%==========================================================================
% Sphere equation: (x-a)^2 + (y-b)^2 + (z-c)^2 = d^2;
%==========================================================================
function model = fitSphere(points)
X = [points, ones(size(points,1),1)];
m11 = det(X);
if abs(m11)<=eps(class(points))
    model = [];
    return;
end

X(:,1) = points(:,1).^2+points(:,2).^2+points(:,3).^2;
m12 = det(X);

X(:,2) = X(:,1);
X(:,1) = points(:,1);
m13 = det(X);

X(:,3) = X(:,2);
X(:,2) = points(:,2);
m14 = det(X);

X(:,1) = X(:,3);
X(:,2:4) = points;
m15 = det(X);

a =  0.5*m12/m11;
b =  0.5*m13/m11;
c =  0.5*m14/m11;
d = sqrt(a^2+b^2+c^2-m15/m11);
model = [a, b, c, d];

%==========================================================================
% Calculate the distance from the point to the sphere.
% D = abs(sqrt((a-x)^2 + (b-y)^2 + (c-z)^2)-d)
%==========================================================================
function dis = evalSphere(model, points)
dis = abs(sqrt((points(:,1)-model(1)).^2 + (points(:,2)-model(2)).^2 + ...
    (points(:,3)-model(3)).^2) - model(4));

%==========================================================================
% Validate the sphere coefficients
%==========================================================================
function isValid = checkSphere(model)
isValid = (numel(model) == 4 & all(isfinite(model)));
