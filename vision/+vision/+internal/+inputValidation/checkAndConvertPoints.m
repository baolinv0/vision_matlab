function pointsOut = checkAndConvertPoints(pointsIn, fileName, varName, allowGPUArrays)
%checkAndConvertPoints Checks if points are valid, then converts to x-y coordinates.
%  pointsOut = checkAndConvertPoints(pointsIn, fileName, varName, allowGPUArrays)
%  checks that pointsIn is a valid points object and converts it into an
%  M-by-2 matrix of [x,y] coordinates.
%
%  Inputs:
%  -------
%  pointsIn - Points object to be validated. Valid points objects are
%             cornerPoints, SURFPoints, MSERRegions, BRISKPoints, and 
%             M-by-2 numeric matrix. If pointsIn is not a valid points
%             object, the function will throw an error.
%
%  fileName - String containing the file name of the calling function.
%
%  varName  - String containing the variable name being validated.
%
%  allowGPUArrays - Logical scalar. A value of true means that pointsIn can
%                   be stored on the GPU.
%
%  See also vision.internal.inputValidation.checkAndConvertMatchedPoints

%  Copyright 2014 Mathworks, Inc.
%#codegen
%#ok<*EMCA>

if nargin ~= 4
    allowGPUArrays = false;
end

% check points
vision.internal.inputValidation.checkPoints(pointsIn, fileName, varName, allowGPUArrays);

% then convert
if isnumeric(pointsIn)
    pointsOut = pointsIn;    
else
    pointsOut = pointsIn.Location;
end
