function points = lineToBorderPoints(lines,imageSize)
%lineToBorderPoints Compute the intersection points of lines and image border.
%   POINTS = lineToBorderPoints(LINES,IMAGESIZE) computes the intersection
%   points between one or more lines with the image border.
% 
%     LINES is a M-by-3 matrix where each row has the format of [A,B,C]
%     which defines a line as A * x + B * y + C = 0. M is the number of
%     lines.
%
%     IMAGESIZE is the size of the image, and is in the format returned by
%     the function SIZE.
%
%     POINTS is an M-by-4 matrix where each row has the format of
%     [x1,y1,x2,y2], where [x1,y1] and [x2,y2] are the two intersection
%     points. When a line and the image border do not intersect, the
%     function returns [-1,-1,-1,-1].
%
%   Class Support
%   -------------
%   LINES must be double or single. IMAGESIZE must be double, single, or
%   integer.
%
%   Example
%   -------
%   % Load and display an image.
%   I = imread('rice.png');
%   figure; imshow(I); hold on;
%   % Define a line: 2 * x + y - 300 = 0
%   aLine = [2,1,-300];
%   % Compute the intersection points of the line and the image border.
%   points = lineToBorderPoints(aLine, size(I));
%   line(points([1,3]), points([2,4]));
%
% See also epipolarLine, line, size, insertShape.

% Copyright 2010 The MathWorks, Inc.

checkInputs(lines, imageSize);
points = cvalgLineToBorderPoints(lines, imageSize);

%========================================================================== 
function checkInputs(lines, imageSize)
%--------------------------------------------------------------------------
% Check LINES
%--------------------------------------------------------------------------
lineSize = [NaN, 3];

validateattributes(lines, {'double', 'single'}, ...
  {'2d', 'nonsparse', 'nonempty', 'real', 'size', lineSize},...
  mfilename, 'LINES');

%--------------------------------------------------------------------------
% Check IMAGESIZE
%--------------------------------------------------------------------------
validateattributes(imageSize, {'single', 'double', 'int8', 'int16', ...
  'int32', 'int64', 'uint8', 'uint16', 'uint32', 'uint64'}, ...
  {'vector', 'nonsparse', 'nonempty', 'real', 'positive', 'integer'},...
  mfilename, 'IMAGESIZE');

if length(imageSize) < 2
  error(message('vision:lineToBorderPoints:invalidIMAGESIZE'));
end
