function points = lineToBorderPoints(lines,imageSize)
% lineToBorderPoints Compute the intersection points of lines and image border.

% Copyright 2010 The MathWorks, Inc.
%#codegen

% Code below is only used by Simulink when the function is
% placed in the MATLAB Function block. Simulink first propagates
% the sizes followed by the types. The block of code below sets
% the sizes during the Simulink size propagation stage.
if eml_ambiguous_types
    points = -ones(size(lines, 1), 4);
    return;
end

% Declare that the inputs are most likely constant in order to generate 
% more optimized code.
eml_prefer_const(lines, imageSize);

checkInputs(lines, imageSize);
points = cvalgLineToBorderPoints(lines, imageSize);

%========================================================================== 
function checkInputs(lines, imageSize)

% Check IMAGESIZE
eml_lib_assert(isfloat(imageSize) || isinteger(imageSize), ...
  'vision:lineToBorderPoints:invalidImageSize', ...
  'Expected IMAGESIZE to be double, single, or integer.');

eml_lib_assert(isreal(imageSize) && ~issparse(imageSize), ...
  'vision:lineToBorderPoints:invalidImageSize', ...
  'Expected IMAGESIZE to be real and nonsparse.');

eml_lib_assert(isvector(imageSize) && numel(imageSize)>=2, ...
  'vision:lineToBorderPoints:invalidImageSize', ...
  'Expected IMAGESIZE to be a vector of two or more elements.');

eml_lib_assert((all(imageSize(:) == floor(imageSize(:)))) ...
  && all(imageSize(:) > 0), ...
  'vision:lineToBorderPoints:invalidImageSize', ...
  'Expected IMAGESIZE to have positive integer values.');

% Check LINES
eml_lib_assert(isfloat(lines) && isreal(lines) && ~issparse(lines), ...
               'vision:lineToBorderPoints:invalidLines', ...
               'Expected LINES to be floating point, real, and nonsparse.');

eml_lib_assert(ndims(lines) == 2 ...
               && size(lines, 2) == 3  && size(lines, 1) > 0, ...
               'vision:lineToBorderPoints:invalidLines', ...
               'Expected LINES to be a M-by-3 matrix.');
