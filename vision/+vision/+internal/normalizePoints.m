% normalizePoints Normalize points for estimating a transformation
%   [normPoints, T] = normalizePoints(points, outputClass)
%   Normalize the points so that the center of mass is at [0,0] and the mean
%   distance from the center is sqrt(2). 

% Copyright 2013 Mathworks, Inc.

% References: 
%   [1]  Hartley and Zisserman, Multiple View Geometry, Second Edition, p. 107.

%#codegen

function [normPoints, T] = normalizePoints(p, numDims, outputClass)

% strip off the homogeneous coordinate
points = p(1:numDims, :);

% compute centroid
cent = cast(mean(points, 2), outputClass);

% translate points so that the centroid is at [0,0]
translatedPoints = bsxfun(@minus, points, cent);

% compute the scale to make mean distance from centroid sqrt(2)
meanDistanceFromCenter = cast(mean(sqrt(sum(translatedPoints.^2))), ...
    outputClass);
if meanDistanceFromCenter > 0 % protect against division by 0
    scale = cast(sqrt(numDims), outputClass) / meanDistanceFromCenter;
else
    scale = cast(1, outputClass);
end

% compute the matrix to scale and translate the points
% the matrix is of the size numDims+1-by-numDims+1 of the form
% [scale   0     ... -scale*center(1)]
% [  0   scale   ... -scale*center(2)]
%           ...
% [  0     0     ...       1         ]    
T = diag(ones(1, numDims + 1) * scale);
T(1:end-1, end) = -scale * cent;
T(end) = 1;

if size(p, 1) > numDims
    normPoints = T * p;
else
    normPoints = translatedPoints * scale;
end
% the following must be true: mean(sqrt(sum(normPoints(1:2,:).^2, 1))) == sqrt(2)