function [J, camIntrinsics] = undistortFisheyeImage(I, intrinsics, varargin)
%undistortFisheyeImage Correct fisheye image for lens distortion.
%   J = undistortFisheyeImage(I, intrinsics) removes lens distortion
%   from image I, and returns the result as image J. I can be a grayscale
%   or a truecolor image. intrinsics is a fisheyeIntrinsics object.
%
%   [J, camIntrinsics] = undistortFisheyeImage(I, intrinsics) additionally 
%   returns a cameraIntrinsics object, camIntrinsics, which corresponds to a
%   virtual perspective camera that produces image J.
%
%   [...] = undistortFisheyeImage(..., interp) specifies interpolation
%   method to use. interp can be one of the strings 'nearest', 'bilinear',
%   or 'cubic'. The default value for interp is 'bilinear'.
%
%   [...] = undistortFisheyeImage(..., Name, Value) specifies additional 
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
%   'ScaleFactor'    A scalar or 2-element vector [sx, sy], specifying the
%                    scale factors of the focal length of a virtual
%                    perspective camera in pixels. Increase this value to
%                    zoom in the camera view.
%                    
%                    Default: 1
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
%   The class of input I can be uint8, uint16, int16, double, single. J is
%   the same class as I.
%
%   Example - Correct an image for lens distortion
%   ----------------------------------------------
%   % Gather a set of calibration images.
%   images = imageDatastore(fullfile(toolboxdir('vision'), 'visiondata', ...
%       'calibration', 'gopro'));
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
%   params = estimateFisheyeParameters(imagePoints, worldPoints, imageSize);
%
%   % Remove lens distortion and display results.
%   J1 = undistortFisheyeImage(I, params.Intrinsics);
%
%   figure
%   imshowpair(I, J1, 'montage')
%   title('Original Image (left) vs. Corrected Image (right)')
%
%   J2 = undistortFisheyeImage(I, params.Intrinsics, 'OutputView', 'full');
%   figure
%   imshow(J2)
%   title('Full Output View')
%
%   See also undistortFisheyePoints, estimateFisheyeParameters, 
%       fisheyeIntrinsics, cameraIntrinsics 

%   Copyright 2017 The MathWorks, Inc.

validateattributes(intrinsics, {'fisheyeIntrinsics'}, {'scalar'}, ...
    mfilename, 'intrinsics');

[interp, outputView, scaleFactor, fillValues, method] = parseInputs(I, varargin{:});

imageSize = intrinsics.ImageSize;
if isempty(imageSize)
    error(message('vision:calibrate:emptyImageSize'));
end

if ~isequal([size(I,1),size(I,2)], imageSize)
    error(message('vision:calibrate:inconsistentImageSize'));
end

originalClass = class(I);
if ~(isa(I,'double') || isa(I,'single') || isa(I,'uint8'))
    I = single(I);
    fillValues = cast(fillValues, 'like', I);
end

f = min(imageSize) / 2;
focalLength = f .* scaleFactor(:)';

[J, camIntrinsics] = undistortImageImpl(intrinsics, I, interp, ...
    outputView, focalLength, fillValues, method);

J = cast(J, originalClass);


%--------------------------------------------------------------------------
function [interp, outputView, scaleFactor, fillValues, method] = parseInputs(I, varargin)
vision.internal.inputValidation.validateImage(I);

[interp, outputView, scaleFactor, fillValues, method] = parseInputsMatlab(I, varargin{:});

fillValues = vision.internal.inputValidation.scalarExpandFillValues(...
    fillValues, I);

%--------------------------------------------------------------------------
function [interp, outputView, scaleFactor, fillValues, method] = ...
                                            parseInputsMatlab(I, varargin)
defaultOutputView = 'same';
defaultInterp = 'bilinear';
defaultMethod = 'approximate';

persistent parser;

if isempty(parser)
    parser = inputParser();
    parser.addOptional('interp', defaultInterp, @validateInterpMethod);
    parser.addParameter('OutputView', defaultOutputView, @validateOutputView);
    parser.addParameter('ScaleFactor', 1, @validateScaleFactor);
    parser.addParameter('FillValues', 0);
    parser.addParameter('Method', defaultMethod);
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

scaleFactor = parser.Results.ScaleFactor;
if isscalar(scaleFactor)
    scaleFactor = [scaleFactor, scaleFactor];
end

fillValues = parser.Results.FillValues;
if ~(isscalar(fillValues) && fillValues == 0)
    vision.internal.inputValidation.validateFillValues(fillValues, I);
end

method = validateMethod(parser.Results.Method);

%--------------------------------------------------------------------------
function tf = validateOutputView(outputView)
validateattributes(outputView, {'char'}, {'vector'}, mfilename, 'OutputView');
tf = true;
        
%--------------------------------------------------------------------------
function tf = validateInterpMethod(method)
vision.internal.inputValidation.validateInterp(method);
tf = true;

%--------------------------------------------------------------------------
function outputView = validateOutputViewPartial(outputView)
outputView = ...
   validatestring(outputView, {'full', 'valid', 'same'}, mfilename, 'OutputView');

%--------------------------------------------------------------------------
function tf = validateScaleFactor(scaleFactor)
if ~isscalar(scaleFactor)
    validateattributes(scaleFactor, {'single','double'}, ...
        {'vector', 'nonsparse', 'real', 'numel', 2, 'positive'}, mfilename, 'ScaleFactor');
else
    validateattributes(scaleFactor, {'single','double'}, ...
        {'nonsparse', 'real', 'scalar', 'positive'}, mfilename, 'ScaleFactor');
end
tf = true;

%--------------------------------------------------------------------------
function method = validateMethod(value)
method = validatestring(value, {'exact','approximate'}, mfilename, 'Method');
