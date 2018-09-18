function worldPoints = generateCheckerboardPoints(boardSize, squareSize)
% generateCheckerboardPoints Generate checkerboard point locations
%   worldPoints = generateCheckerboardPoints(boardSize, squareSize) returns
%   an M x 2 matrix containing the x-y coordinates of the corners of squares
%   of a checkerboard. Point (0,0) corresponds to the lower-right corner of 
%   the top-left square of the board. boardSize is a 2-element vector 
%   specifying the dimensions of the checkerboard in terms of the number of
%   squares. The number of points returned is 
%   M = (boardSize(1)-1) * (boardSize(2)-1). squareSize is a scalar 
%   specifying the length of the side of each square in world units, for 
%   example in millimeters.
%
% Example
% ------- 
% % Generate and plot corners of an 8x8 checkerboard
% I = checkerboard;
% squareSize = 10;
% worldPoints = generateCheckerboardPoints([8 8], squareSize);
%
% % offset the points to place the first point at lower-right corner of the
% % first square.
% imshow(insertMarker(I, worldPoints + squareSize));
%
% See also estimateCameraParameters, cameraParameters, stereoParameters 
%   detectCheckerboardPoints

% Copyright 2013-2014 MathWorks, Inc.

%#codegen

checkInputs(boardSize, squareSize);
boardSize = double(boardSize) - 1;
worldPoints = zeros(boardSize(1) * boardSize(2), 2);
k = 1;
for j = 0:boardSize(2)-1
    for i = 0:boardSize(1)-1
        worldPoints(k,1) = j * squareSize;
        worldPoints(k,2) = i * squareSize;
        k = k + 1;
    end
end

%--------------------------------------------------------------------------
function checkInputs(boardSize, squareSize)

validateattributes(boardSize, {'numeric'},...
    {'nonempty', 'vector', 'numel', 2, 'integer', 'positive', '>=', 3},....
    mfilename, 'boardSize'); %#ok<EMCA>

vision.internal.calibration.checkSquareSize(squareSize, mfilename);

if (~isempty(coder.target))    
    vision.internal.inputValidation.validateFixedSize(boardSize, 'boardSize');
    vision.internal.inputValidation.validateFixedSize(squareSize, 'squareSize');
end
