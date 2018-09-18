function points = bbox2points(bbox)
% BBOX2POINTS Convert a rectangle into a list of points
% 
%   points = BBOX2POINTS(rectangle) converts a bounding box
%   into a list of points. rectangle is either a single
%   bounding box specified as a 4-element vector [x y w h],
%   or a set of bounding boxes specified as an M-by-4 matrix.
%   For a single bounding box, the function returns a list of 4 points 
%   specified as a 4-by-2 matrix of [x,y] coordinates. For multiple
%   bounding boxes the function returns a 4-by-2-by-M array of
%   [x,y] coordinates, where M is the number of bounding boxes.
%
%   Class Support
%   -------------
%   bbox can be int16, uint16, int32, uint32, single, or double. 
%   points is the same class as rectangle.
%
%   Example
%   -------
%   % Define a bounding box
%   bbox = [10 20 50 60];
%   
%   % Convert the bounding box to a list of 4 points
%   points = bbox2points(bbox);
%
%   % Define a rotation transformation
%   theta = 10;
%   tform = affine2d([cosd(theta) -sind(theta) 0; sind(theta) cosd(theta) 0; 0 0 1]);
%
%   % Apply the rotation
%   points2 = transformPointsForward(tform, points);
%
%   % Close the polygon for display
%   points2(end+1, :) = points2(1, :);
%
%   % Plot the rotated box
%   plot(points2(:, 1), points2(:, 2), '*-');
%
%   See also affine2d, projective2d

%#codegen

checkInput(bbox);

numBboxes = size(bbox, 1);
points = zeros(4, 2, numBboxes, 'like', bbox);

% upper-left
points(1, 1, :) = bbox(:, 1);
points(1, 2, :) = bbox(:, 2);

% upper-right
points(2, 1, :) = bbox(:, 1) + bbox(:, 3);
points(2, 2, :) = bbox(:, 2);

% lower-right
points(3, 1, :) = bbox(:, 1) + bbox(:, 3);
points(3, 2, :) = bbox(:, 2) + bbox(:, 4);

% lower-left
points(4, 1, :) = bbox(:, 1);
points(4, 2, :) = bbox(:, 2) + bbox(:, 4);

function checkInput(bbox)
validateattributes(bbox, ...
    {'int16', 'uint16', 'int32', 'uint32', 'single', 'double'}, ...
    {'real', 'nonsparse', 'nonempty', 'finite', 'size', [NaN, 4]}, ...
    'bbox2points', 'bbox'); %#ok<EMCA>

validateattributes(bbox(:, [3,4]), {'numeric'}, ...
    {'>=', 0}, 'bbox2points', 'bbox(:,[3,4])'); %#ok<EMCA>


