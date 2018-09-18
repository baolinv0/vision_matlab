function lines = epipolarLine(f,pts)
% Compute epipolar lines for stereo images.
%   Assuming that the fundamental matrix, F, maps points in image I1 to
%   epipolar lines in image I2,
% 
%   LINES = epipolarLine(F,PTS) computes the epipolar lines in I2
%   corresponding to the points, PTS, in I1. 
% 
%   LINES = epipolarLine(F',PTS) computes the epipolar lines in I1
%   corresponding to the points, PTS, in I2. 
% 
%     PTS is a M-by-2 matrix, where each row contains the x and y
%     coordinates of a point. M is the number of points.
% 
%     F is a 3-by-3 fundamental matrix. If P1, a point in I1, corresponds
%     to P2, a point in I2, then [P2,1] * F * [P1,1]' = 0. 
% 
%     LINES is a M-by-3 matrix where each row has the format [A,B,C]
%     which defines a line as A * x + B * y + C = 0.
% 
%   Class Support
%   -------------
%   F must be double or single. PTS must be double, single, or integer.
%
%   Example
%   -------
%   % Use the Least Median of Squares method to find inliers and to
%   % compute the fundamental matrix. The points, matchedPoints1 and
%   % matchedPoints2, have been putatively matched.
%   load stereoPointPairs
%   [fLMedS, inliers] = estimateFundamentalMatrix(matchedPoints1, ...
%     matchedPoints2, 'NumTrials', 4000);
% 
%   % Show the inliers in the first image.
%   I1 = imread('viprectification_deskLeft.png');
%   figure; 
%   subplot(121); imshow(I1); 
%   title('Inliers and Epipolar Lines in First Image'); hold on;
%   plot(matchedPoints1(inliers,1), matchedPoints1(inliers,2), 'go')
% 
%   % Compute the epipolar lines in the first image.
%   epiLines = epipolarLine(fLMedS', matchedPoints2(inliers, :));
% 
%   % Compute the intersection points of the lines and the image border.
%   pts = lineToBorderPoints(epiLines, size(I1));
% 
%   % Show the epipolar lines in the first image
%   line(pts(:, [1,3])', pts(:, [2,4])');
%
%   % Show the inliers in the second image.
%   I2 = imread('viprectification_deskRight.png');
%   subplot(122); imshow(I2);
%   title('Inliers and Epipolar Lines in Second Image'); hold on;
%   plot(matchedPoints2(inliers,1), matchedPoints2(inliers,2), 'go')
% 
%   % Compute and show the epipolar lines in the second image.
%   epiLines = epipolarLine(fLMedS, matchedPoints1(inliers, :));
%   pts = lineToBorderPoints(epiLines, size(I2));
%   line(pts(:, [1,3])', pts(:, [2,4])');
%
%   truesize;
%
% See also estimateFundamentalMatrix, lineToBorderPoints, line, insertShape
%
% References:
%   R. Hartley, A. Zisserman, "Multiple View Geometry in Computer Vision,"
%   Cambridge University Press, 2003.

% Copyright 2010 The MathWorks, Inc.

outputClass = class(f);
checkInputs(f, pts);
nPts = size(pts, 1);
lines = [cast(pts, outputClass), ones(nPts, 1, outputClass)] * f';
end

%========================================================================== 
function checkInputs(f, pts)

% Check F
validateattributes(f, {'double', 'single'}, ...
  {'2d', 'nonsparse', 'real', 'size', [3, 3]},...
  mfilename, 'F');

% Check PTS
ptsSize = [NaN, 2];

validateattributes(pts, {'single', 'double', 'int8', 'int16', ...
  'int32', 'int64', 'uint8', 'uint16', 'uint32', 'uint64'}, ...
  {'2d', 'nonsparse', 'nonempty', 'real', 'size', ptsSize},...
  mfilename, 'Pts');
end
