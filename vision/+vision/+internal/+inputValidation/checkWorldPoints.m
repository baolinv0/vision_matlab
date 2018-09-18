%checkWorldPoints Check validity of world points from calibration
%checkerboard
%
%  See also estimateFisheyeParameters, estimateCameraParameters

% Copyright 2017 Mathworks, Inc.
function checkWorldPoints(worldPoints, mfilename)
validateattributes(worldPoints, {'double'}, ...
    {'finite', 'nonsparse', '2d', 'ncols', 2}, ...
    mfilename, 'worldPoints');

minNumPoints = 4;
if size(worldPoints, 1) < minNumPoints
    error(message('vision:calibrate:minNumWorldPoints', minNumPoints-1));
end