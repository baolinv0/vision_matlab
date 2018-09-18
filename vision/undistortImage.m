function [J, newOrigin] = undistortImage(I, intrinsics, varargin)
%undistortImage Correct image for lens distortion.
%   [J, newOrigin] = undistortImage(I, intrinsics) removes lens distortion
%   from image I, and returns the result as image J. I can be a grayscale
%   or a truecolor image. intrinsics is either cameraParameters or
%   cameraIntrinsics object.
%
%   newOrigin is a 2-element vector containing the [x,y] location of the 
%   origin of the output image J in the intrinsic coordinates of the input 
%   image I. Before using extrinsics, pointsToWorld, or triangulate 
%   functions you must add newOrigin to the coordinates of points detected 
%   in undistorted image J in order to transform them into the intrinsic 
%   coordinates of the original image I.
%   If 'OutputView' is set to 'same', then newOrigin is [0, 0]. 
%
%   [J, newOrigin] = undistortImage(..., interp) specifies interpolation
%   method to use. interp can be one of the strings 'nearest', 'linear', or
%   'cubic'. The default value for interp is 'linear'.
%
%   [J, newOrigin] = undistortImage(..., Name, Value) specifies additional 
%   name-value pairs described below:
%  
%   'OutputView'     Determines the size of the output image J. Possible 
%                    values are:
%                      'same'  - J is the same size as I
%                      'full'  - J includes all pixels from I
%                      'valid' - J is cropped to the size of the largest
%                                rectangle contained in I
%  
%                    Default: 'same'
%  
%   'FillValues'     An array containing one or several fill values.
%                    Fill values are used for output pixels when the
%                    corresponding inverse transformed location in the
%                    input image is completely outside the input image
%                    boundaries.
%  
%                    If I is a 2-D grayscale image then 'FillValues' 
%                    must be a scalar. If I is a truecolor image, then 
%                    'FillValues' can be a scalar or a 3-element vector
%                    of RGB values.
%
%                    Default: 0
%  
%   Class Support
%   -------------
%   The class of input I can be uint8, uint16, int16, double,
%   single. J is the same class as I.
%
%   Example - Correct an image for lens distortion
%   ----------------------------------------------
%   % Create a set of calibration images.
%   images = imageDatastore(fullfile(toolboxdir('vision'), 'visiondata', ...
%       'calibration', 'mono'));
%
%   % Detect calibration pattern.
%   [imagePoints, boardSize] = detectCheckerboardPoints(images.Files);
%
%   % Generate world coordinates of the corners of the squares.
%   squareSize = 29; % square size in millimeters
%   worldPoints = generateCheckerboardPoints(boardSize, squareSize);
%
%   % Calibrate the camera.
%   I = readimage(images,1); 
%   imageSize = [size(I, 1), size(I, 2)];
%   cameraParams = estimateCameraParameters(imagePoints, worldPoints, ...
%                                     'ImageSize', imageSize);
%
%   % Remove lens distortion and display results.
%   I = images.readimage(1);
%   J1 = undistortImage(I, cameraParams);
%
%   figure; imshowpair(I, J1, 'montage');
%   title('Original Image (left) vs. Corrected Image (right)');
%
%   J2 = undistortImage(I, cameraParams, 'OutputView', 'full');
%   figure; imshow(J2);
%   title('Full Output View');
%
%   See also undistortPoints, triangulate, extrinsics, cameraCalibrator,
%       estimateCameraParameters, cameraParameters, cameraIntrinsics 

%   Copyright 2014 The MathWorks, Inc.

%#codegen
%#ok<*EMCLS>
%#ok<*EMCA>

if ~isa(intrinsics, 'cameraParameters')
    checkCameraParameters(intrinsics);
end

[interp, outputView, fillValues] = parseInputs(I, varargin{:});

originalClass = class(I);
if ~(isa(I,'double') || isa(I,'single') || isa(I,'uint8'))
    I = single(I);
    fillValues = cast(fillValues, 'like', I);
end    

if isa(intrinsics, 'cameraParameters')
    intrinsicParams = intrinsics;
else
    intrinsicParams = intrinsics.CameraParameters;
end

[J, newOrigin] = undistortImageImpl(intrinsicParams, I, interp, outputView, fillValues);
J = cast(J, originalClass);

%--------------------------------------------------------------------------
function [interp, outputView, fillValues] = parseInputs(I, varargin)
vision.internal.inputValidation.validateImage(I);
if isempty(coder.target)
    [interp, outputView, fillValues] = parseInputsMatlab(I, varargin{:});
else 
    [interp, outputView, fillValues] = ...
        vision.internal.inputValidation.parseUndistortRectifyInputsCodegen(...
        I, 'undistortImage', 'same', varargin{:});
end

fillValues = vision.internal.inputValidation.scalarExpandFillValues(...
    fillValues, I);

%--------------------------------------------------------------------------
function [interp, outputView, fillValues] = parseInputsMatlab(I, varargin)
defaultOutputView = 'same';
defaultInterp = 'bilinear';

persistent parser;

if isempty(parser)
    parser = inputParser();
    parser.addOptional('interp', defaultInterp, @validateInterpMethod);
    parser.addParameter('OutputView', defaultOutputView, @validateOutputView);
    parser.addParameter('FillValues', 0);
end

parser.parse(varargin{:});
interp = parser.Results.interp;
if ~strcmp(interp, defaultInterp)
    interp = vision.internal.inputValidation.validateInterp(interp);
end

outputView = parser.Results.OutputView;
if ~strcmp(outputView, defaultOutputView)
    outputView = validateOutputViewPartial(outputView);
end

fillValues = parser.Results.FillValues;
if ~(isscalar(fillValues) && fillValues == 0)
    vision.internal.inputValidation.validateFillValues(fillValues, I);
end

%--------------------------------------------------------------------------
function TF = validateOutputView(outputView)
validateattributes(outputView, {'char'}, {'vector'}, mfilename, 'OutputView');
TF = true;
        
%--------------------------------------------------------------------------
function tf = validateInterpMethod(method)
vision.internal.inputValidation.validateInterp(method);
tf = true;

%--------------------------------------------------------------------------
function checkCameraParameters(camParams)
validateattributes(camParams, {'cameraParameters', 'cameraIntrinsics'}, ...
    {}, mfilename, 'intrinsics');

%--------------------------------------------------------------------------
function outputView = validateOutputViewPartial(outputView)
outputView = ...
   validatestring(outputView, {'full', 'valid', 'same'}, mfilename, 'OutputView');


