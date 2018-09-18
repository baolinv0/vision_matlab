function features = extractLBPFeatures(I,varargin)
%extractLBPFeatures Extract LBP features.
%  features = extractLBPFeatures(I) extracts uniform local binary patterns
%  (LBP) from a grayscale image I and returns the features in
%  a 1-by-N vector. LBP features encode local texture information and can
%  be used for many tasks including classification, detection, and
%  recognition.
%
%  The LBP feature length, N, is based on the image size and the parameter
%  values listed below. See the <a href="matlab:helpview(fullfile(docroot,'toolbox','vision','vision.map'),'lbpFeatureLength')" >documentation</a> for more information.
%
%  [...] = extractLBPFeatures(..., Name, Value) specifies additional
%  name-value pairs described below. LBP algorithm parameters control how
%  local binary patterns are computed for each pixel in I. LBP histogram
%  parameters determine how the distribution of binary patterns is
%  aggregated over I to produce the output features.
%
%  LBP algorithm parameters
%  ------------------------
%
%  'NumNeighbors'  The number of neighbors used to compute the local binary
%                  pattern for each pixel in I. The set of neighbors is
%                  selected from a circularly symmetric pattern around each
%                  pixel. Increase the number of neighbors to encode
%                  greater detail around each pixel. Typical values are
%                  between 4 and 24.
%
%                  Default: 8
%
%  'Radius'        The radius, in pixels, of the circular pattern used to
%                  select neighbors for each pixel in I. Increase the
%                  radius to capture detail over a larger spatial scale.
%                  Typical values range from 1 to 5.
%
%                  Default: 1
%
%  'Upright'       A logical scalar. When set to true, the LBP features do
%                  not encode rotation information. Set 'Upright' to false
%                  when rotationally invariant features are required.
%
%                  Default: true
%
%  'Interpolation' Specify the interpolation method used to compute pixel
%                  neighbors as 'Nearest' or 'Linear'. Use 'Nearest' for
%                  faster computation at the cost of accuracy.
%
%                  Default: 'Linear'
%
%  LBP histogram parameters
%  ------------------------
%
%  'CellSize'      A 2-element vector that partitions I into
%                  floor(size(I)./CellSize) non-overlapping cells.
%                  Select larger cell sizes to collect information over
%                  larger regions at the cost of loosing local detail.
%
%                  Default: size(I)
%
%  'Normalization' Specify the type of normalization applied to the LBP
%                  histograms as 'L2' or 'None'. Select 'None' to apply a
%                  custom normalization method as a post-processing step.
%
%                  Default: 'L2'
%
% Class Support
% -------------
% The input image I can be uint8, uint16, int16, double, single, or
% logical, and it must be real and non-sparse.
%
% Notes
% -----
% This function extracts uniform local binary patterns. Uniform patterns
% have at most two 1-to-0 or 0-to-1 bit transitions.
%
% Example - Differentiate images by texture using LBP features.
% ---------------------------------------------------------------
% % Read images that contain different textures.
% brickWall = imread('bricks.jpg');
% rotatedBrickWall = imread('bricksRotated.jpg');
% carpet  = imread('carpet.jpg');
%
% figure
% imshow(brickWall)
% title('Bricks')
%
% figure
% imshow(rotatedBrickWall)
% title('Rotated bricks')
%
% figure
% imshow(carpet)
% title('Carpet')
%
% % Extract LBP features to encode image texture information.
% lbpBricks1 = extractLBPFeatures(brickWall,'Upright',false);
% lbpBricks2 = extractLBPFeatures(rotatedBrickWall,'Upright',false);
% lbpCarpet = extractLBPFeatures(carpet,'Upright',false);
%
% % Compute the squared error between the LBP features. This helps gauge
% % the similarity between the LBP features.
% brickVsBrick = (lbpBricks1 - lbpBricks2).^2;
% brickVsCarpet = (lbpBricks1 - lbpCarpet).^2;
%
% % Visualize the squared error to compare bricks vs. bricks and bricks vs.
% % carpet. The squared error is smaller when images have similar texture.
% figure
% bar([brickVsBrick; brickVsCarpet]', 'grouped')
% title('Squared error of LBP Histograms')
% xlabel('LBP Histogram Bins')
% legend('Bricks vs Rotated Bricks', 'Bricks vs Carpet')
%
% See also extractHOGFeatures, extractFeatures, detectHarrisFeatures,
% detectFASTFeatures, detectMinEigenFeatures, detectSURFFeatures,
% detectMSERFeatures, detectBRISKFeatures

% Copyright 2015 The MathWorks, Inc.
%
% References
% ----------
% Ojala, Timo, Matti Pietikainen, and Topi Maenpaa. "Multiresolution
% gray-scale and rotation invariant texture classification with local
% binary patterns." Pattern Analysis and Machine Intelligence, IEEE
% Transactions on 24.7 (2002): 971-987.

%#codegen

if isempty(coder.target)
    
    params = parseInputs(I,varargin{:});
    
    lbpImpl  = vision.internal.LBPImpl.getImpl(params);
    
    features = lbpImpl.extractLBPFeatures(I);
    
else
    
    [numNeighbors, radius, interpolation, uniform, upright, cellSize,...
        normalization] = codegenParseInputs(I,varargin{:});
    
    features = vision.internal.LBPImpl.codegenExtractLBPFeatures(... 
        I, numNeighbors, radius, interpolation, ...
        uniform, upright, cellSize, normalization);
end

% -------------------------------------------------------------------------
function params = parseInputs(I, varargin)

vision.internal.inputValidation.validateImage(I, 'I', 'grayscale');

szI = size(I);

parser = getInputParser();
parser.parse(varargin{:});

userInput = parser.Results;

usingDefaultCellSize = ismember('CellSize', parser.UsingDefaults);
    
if usingDefaultCellSize
    userInput.CellSize = szI;  % cell size default is size(I)
end

[validInterpolation, validNormalization] = validate(...
    userInput.NumNeighbors, userInput.Radius, userInput.CellSize, ...
    userInput.Upright, userInput.Interpolation, userInput.Normalization);

params = setParams(userInput, validInterpolation, validNormalization);

crossCheckParams(szI, params.CellSize, params.Radius)

% -------------------------------------------------------------------------
function [numNeighbors, radius, interpolation, uniform, upright, ...
    cellSize, normalization] = codegenParseInputs(I, varargin)

vision.internal.inputValidation.validateImage(I, 'I', 'grayscale');
eml_invariant(eml_is_const(ismatrix(I)), eml_message('vision:dims:imageNot2D'));

szI = size(I);

pvPairs = struct( ...
    'NumNeighbors',  uint32(0), ...
    'Radius',        uint32(0), ...    
    'CellSize',      uint32(0), ...   
    'Upright',       uint32(0),...
    'Interpolation', uint32(0),...
    'Normalization', uint32(0));

popt = struct( ...
    'CaseSensitivity', false, ...
    'StructExpand'   , true, ...
    'PartialMatching', true);

defaults = getParamDefaults();

optarg = eml_parse_parameter_inputs(pvPairs, popt, varargin{:});

usingDefaultCellSize = ~optarg.CellSize;

numNeighbors = eml_get_parameter_value(optarg.NumNeighbors, ...
    defaults.NumNeighbors, varargin{:});

radius = eml_get_parameter_value(optarg.Radius, ...
    defaults.Radius, varargin{:});

cellSize = eml_get_parameter_value(optarg.CellSize, ...
    defaults.CellSize, varargin{:});

upright = eml_get_parameter_value(optarg.Upright, ...
    defaults.Upright, varargin{:});

userInterpolation = eml_get_parameter_value(optarg.Interpolation, ...
    defaults.Interpolation, varargin{:});

userNormalization = eml_get_parameter_value(optarg.Normalization, ...
    defaults.Normalization, varargin{:});

% check const-ness before assigning to struct
vision.internal.errorIfNotConst(numNeighbors,      'NumNeighbors');
vision.internal.errorIfNotConst(radius,            'Radius');
vision.internal.errorIfNotConst(userInterpolation, 'Interpolation');
vision.internal.errorIfNotConst(userNormalization, 'Normalization');
vision.internal.errorIfNotConst(upright,           'Upright');

% check const-ness of size
vision.internal.errorIfNotFixedSize(numNeighbors, 'NumNeighbors');
vision.internal.errorIfNotFixedSize(radius,       'Radius');
vision.internal.errorIfNotFixedSize(cellSize,     'CellSize');
  
if usingDefaultCellSize
    cellSize = szI;  % cell size default is size(I)
end

[interpolation, normalization] = validate(numNeighbors, radius, cellSize, ...
    upright, userInterpolation, userNormalization);

numNeighbors  = single(numNeighbors);
radius        = single(radius);
cellSize      = single(cellSize);
upright       = logical(upright);
uniform       = true;

crossCheckParams(szI, cellSize, radius)

% -------------------------------------------------------------------------
function params = setParams(userInput, interpMethod, normMethod)
params.NumNeighbors  = single(userInput.NumNeighbors);
params.Radius        = single(userInput.Radius);
params.CellSize      = single(userInput.CellSize);
params.Upright       = logical(userInput.Upright);
params.Interpolation = interpMethod;
params.Normalization = normMethod;
params.Uniform       = true;
params.UseLUT        = false; % reset later based on other params

% -------------------------------------------------------------------------
function crossCheckParams(szI, cellSize, radius)
crossCheckImageSizeAndCellSize(szI, cellSize);
    
crossCheckImageSizeAndRadius(szI, radius);
    
crossCheckCellSizeAndRadius(cellSize, radius);

% -------------------------------------------------------------------------
function [validInterpolation, validNormalization] = validate(numNeighbors, ...
    radius, cellSize, upright, interpolation, normalization)

checkNumNeighbors(numNeighbors);

checkRadius(radius);

vision.internal.inputValidation.validateLogical(upright, 'Upright');
     
checkCellSize(cellSize);

validInterpolation = checkInterpolation(interpolation);

validNormalization = checkNormalization(normalization);

% -------------------------------------------------------------------------
function checkNumNeighbors(n)

vision.internal.errorIfNotFixedSize(n, 'NumNeighbors');

validateattributes(n, {'numeric'}, ...
    {'integer', 'real', 'nonsparse', 'scalar', '>=', 2' '<=' 32'},...
    mfilename, 'NumNeighbors'); %#ok<*EMCA>

% -------------------------------------------------------------------------
function checkRadius(r)

validateattributes(r, {'numeric'}, ...
    {'integer', 'real', 'nonsparse', 'scalar', '>=', 1},...
    mfilename, 'Radius');

% -------------------------------------------------------------------------
function str = checkInterpolation(method)

str = validatestring(method, {'Nearest', 'Linear'},...
    mfilename, 'Interpolation');

% -------------------------------------------------------------------------
function str = checkNormalization(method)

str = validatestring(method, {'L2', 'None'},...
    mfilename, 'Normalization');

% -------------------------------------------------------------------------
function checkCellSize(sz)

validateattributes(sz, {'numeric'}, ...
    {'vector', 'numel', 2, 'positive', 'real', 'integer', 'nonsparse'},...
    mfilename, 'CellSize');

% -------------------------------------------------------------------------
function crossCheckCellSizeAndRadius(sz, r)
coder.internal.errorIf(any(sz < (2*r + 1)),...
    'vision:extractLBPFeatures:cellSizeLTRadius');

% -------------------------------------------------------------------------
function crossCheckImageSizeAndCellSize(imgSize, cellSize)

coder.internal.errorIf(any(cellSize(:) > imgSize(:)), ...
    'vision:extractLBPFeatures:imgSizeLTCellSize');

% -------------------------------------------------------------------------
function crossCheckImageSizeAndRadius(sz, r)
coder.internal.errorIf(any(sz < (2*r + 1)),...
    'vision:extractLBPFeatures:imgSizeLTRadius');

% -------------------------------------------------------------------------
function parser = getInputParser()
persistent p; % cache parser for speed

if isempty(p)
    
    defaults = getParamDefaults();
    
    p = inputParser();
    addParameter(p, 'NumNeighbors',  defaults.NumNeighbors);
    addParameter(p, 'Radius',        defaults.Radius);
    addParameter(p, 'Upright',       defaults.Upright);
    addParameter(p, 'CellSize',      defaults.CellSize);
    addParameter(p, 'Normalization', defaults.Normalization);
    addParameter(p, 'Interpolation', defaults.Interpolation);
end
parser = p;

% -------------------------------------------------------------------------
function defaults = getParamDefaults()

defaults.NumNeighbors  = single(8);
defaults.Radius        = single(1);
defaults.Upright       = true;
defaults.CellSize      = [3 3];  % default is size(I), but give values here to define dims/type
defaults.Normalization = 'L2';
defaults.Interpolation = 'Linear';
