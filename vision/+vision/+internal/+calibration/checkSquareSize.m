% checkSquareSize validate the checkerboard square size

% Copyright 2014 MathWorks, Inc.

%#codegen

function checkSquareSize(squareSize, mfileName)
validateattributes(squareSize, {'numeric'}, ...
    {'scalar', 'positive', 'finite', 'nonsparse'}, mfileName, 'squareSize'); %#ok<EMCA>