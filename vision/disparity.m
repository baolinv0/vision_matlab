function disparityMap = disparity(I1,I2,varargin)
% DISPARITY Compute disparity map.
%   disparityMap = DISPARITY(I1,I2) returns the disparity map for a pair of 
%   stereo images, I1 and I2. I1 and I2 must have the same size and must be
%   rectified such that the corresponding points are located on the same
%   rows. This rectification can be performed using the rectifyStereoImages
%   function. The returned disparity map has the same size as I1 and
%   I2.
%
%   The disparity function implements two different algorithms: Block
%   Matching and Semi-Global Block Matching. These algorithms consist of
%   the following steps:
%
%    (1) Compute a measure of contrast of the image by using the Sobel filter.
%
%    (2) Compute the disparity for each pixel in I1.
%
%    (3) Mark the elements of d for which disparity was not computed
%        reliably with -REALMAX('single').
%
%   disparityMap = DISPARITY(...,Name,Value) specifies additional name-value pairs
%   described below:
%
%   'Method'  'BlockMatching' for basic Block Matching or 'SemiGlobal' for
%             Semi-Global Block Matching. In the Block Matching method the
%             function computes disparity by comparing the sum of absolute
%             differences (SAD) of each block of pixels in the image. In
%             the Semi-Global Block Matching method the function
%             additionally forces similar disparity on neighboring blocks.
%             This additional constraint results in a more complete
%             disparity estimate than in Block Matching.
%
%             Default: 'SemiGlobal'
%
%   'DisparityRange'       A two-element vector, [MinDisparity
%                          MaxDisparity], defining the range of disparity.
%                          MinDisparity and MaxDisparity must be integers
%                          and their difference must be divisible by 16.
%
%                          Default: [0 64]
%
%   'BlockSize'            An odd integer, 5 <= BlockSize <= 255. The width
%                          of each square block of pixels used for
%                          comparison between I1 and I2.
%
%                          Default: 15
%
%   'ContrastThreshold'    A scalar value, 0 < ContrastThreshold <= 1,
%                          defining the acceptable range of contrast
%                          values. Increasing this parameter results in
%                          fewer pixels being marked as unreliable.
%
%                          Default: 0.5
%
%   'UniquenessThreshold'  A non-negative integer defining the minimum
%                          value of uniqueness. If a pixel is less unique,
%                          the disparity computed for it is less reliable.
%                          Increasing this parameter will result in marking
%                          more pixels unreliable. You can set this
%                          parameter to 0 to disable it.
%
%                          Default: 15
%
%   'DistanceThreshold'    A non-negative integer defining the maximum
%                          distance for left-right checking.Increasing this
%                          parameter results in fewer pixels being marked
%                          as unreliable. You can also set this parameter
%                          to an empty matrix [] to disable it.
%
%                          Default: [] (disabled)
%
%   'TextureThreshold'     A scalar value, 0 <= TextureThreshold <= 1,
%                          defining the minimum texture. If a block of
%                          pixels is less textured, the computed disparity
%                          is less reliable. Increasing this parameter
%                          results in more pixels being marked as
%                          unreliable. Set this parameter to 0 to disable it.
%
%                          This parameter is used only with the
%                          'BlockMatching' method.
%
%                          Default: 0.0002
%
% Class Support
% -------------
%   All inputs must be real, finite, and nonsparse. I1 and I2 must have the
%   same class and must be uint8, uint16, int16, single, or double.
%
%   Example
%   -------
%     % Load the images.
%     I1 = imread('scene_left.png');
%     I2 = imread('scene_right.png');
%
%     % Show the stereo anaglyph. You can view the image in 3-D using
%     % red-cyan stereo glasses.
%     figure
%     imshow(stereoAnaglyph(I1,I2));
%     title('Red-cyan composite view of the stereo images');
%
%     % Compute the disparity map.
%     disparityRange = [-6 10];
%     disparityMap = disparity(rgb2gray(I1), rgb2gray(I2), 'BlockSize', 15, ...
%       'DisparityRange', disparityRange);
%
%     % Show the disparity map. For better visualization use the disparity
%     % range as the display range for imshow.
%     figure 
%     imshow(disparityMap, disparityRange);
%     title('Disparity Map');
%     colormap jet 
%     colorbar
%
% See also rectifyStereoImages, reconstructScene,
% estimateCameraParameters, estimateUncalibratedRectification

% References:
% -----------
% [1] K. Konolige, "Small Vision Systems: Hardware and Implementation,"
%     Proceedings of the 8th International Symposium in Robotic Research,
%     pages 203-212, 1997.
%
% [2] G. Bradski and A. Kaehler, "Learning OpenCV : Computer Vision with
%     the OpenCV Library," O'Reilly, Sebastopol, CA, 2008.
%
% [3] Hirschmuller, Heiko. "Accurate and Efficient Stereo Processing by
%     Semi-Global Matching and Mutual Information." International Conference
%     on Computer Vision and Pattern Recognition, 2005.
%
% Copyright 2011-2016 The MathWorks, Inc.

%#codegen
%#ok<*EMCA>

%--------------------------------------------------------------------------
% Parse the inputs
%--------------------------------------------------------------------------
r = parseInputs(I1, I2, varargin{:});

% Two structures with overlapping fields are required for code generation

% BlockMatching method parameters
% -------------------------------
optBM.preFilterCap        = int32(floor(63 * r.ContrastThreshold));
optBM.preFilterCap        = int32(floor(63 * r.ContrastThreshold));
optBM.SADWindowSize       = int32(r.BlockSize);
optBM.minDisparity        = int32(r.DisparityRange(1));
optBM.numberOfDisparities = int32(r.DisparityRange(2) - r.DisparityRange(1));
optBM.uniquenessRatio     = int32(r.UniquenessThreshold);

% parameters unique to block matching
optBM.textureThreshold    = int32(255 * r.TextureThreshold * r.BlockSize^2);

% OpenCV parameters that are not exposed as optional parameters
optBM.preFilterType       = int32(0);    % Fixed to CV_STEREO_BM_NORMALIZED_RESPONSE
optBM.preFilterSize       = int32(15);
optBM.trySmallerWindows   = int32(0);

% SemiGlobal method parameters
% ----------------------------
optSGBM.preFilterCap        = int32(floor(63 * r.ContrastThreshold));
optSGBM.preFilterCap        = int32(floor(63 * r.ContrastThreshold));
optSGBM.SADWindowSize       = int32(r.BlockSize);
optSGBM.minDisparity        = int32(r.DisparityRange(1));
optSGBM.numberOfDisparities = int32(r.DisparityRange(2) - r.DisparityRange(1));
optSGBM.uniquenessRatio     = int32(r.UniquenessThreshold);

% OpenCV parameters that are not exposed as optional parameters
optSGBM.P1                  = int32(8 * r.BlockSize^2);
optSGBM.P2                  = int32(32 * r.BlockSize^2);
optSGBM.fullDP              = 0; % false


if isempty(r.DistanceThreshold)
    optBM.disp12MaxDiff       = int32(-1);
    optSGBM.disp12MaxDiff     = int32(-1);
else
    % in codegen, r.DistanceThreshold is never empty
    optBM.disp12MaxDiff       = int32(r.DistanceThreshold);
    optSGBM.disp12MaxDiff     = int32(r.DistanceThreshold);
end



%--------------------------------------------------------------------------
% Other OpenCV parameters which are not exposed in the main interface
%--------------------------------------------------------------------------

optBM.speckleWindowSize   = int32(0);
optBM.speckleRange        = int32(0);

optSGBM.speckleWindowSize   = int32(0);
optSGBM.speckleRange        = int32(0);

%--------------------------------------------------------------------------
% Compute disparity
%--------------------------------------------------------------------------
I1_u8 = im2uint8(I1);
I2_u8 = im2uint8(I2);


if isSimMode()
    if strcmpi(r.Method,'SemiGlobal')
        disparityMap = ocvDisparitySGBM(I1_u8, I2_u8, optSGBM);
    else
        disparityMap = ocvDisparityBM(I1_u8, I2_u8, optBM);
    end
else
    if strcmpi(r.Method,'SemiGlobal')
        disparityMap = vision.internal.buildable.disparitySGBMBuildable.disparitySGBM_compute(...
            I1_u8, I2_u8, optSGBM);
    else
        disparityMap = vision.internal.buildable.disparityBMBuildable.disparityBM_compute(...
            I1_u8, I2_u8, optBM);
    end
end

%==========================================================================
% Parse and check inputs
%==========================================================================
function r = parseInputs(I1, I2, varargin)

vision.internal.inputValidation.validateImagePair(I1, I2, 'I1', 'I2', 'grayscale');
imageSize = size(I1);
r = parseOptionalInputs(imageSize, varargin{:});
checkBlockSize(r.BlockSize, imageSize);

%==========================================================================
function r = parseOptionalInputs(imageSize, varargin)
if isSimMode()
    % inline the following function
    r = vision.internal.disparityParser(imageSize, getDefaultParameters(),...
        varargin{:});
else
    r = parseOptionalInputs_cg(imageSize, varargin{:});
end

%==========================================================================
function r = parseOptionalInputs_cg(imageSize, varargin)

% Optional Name-Value pair: 6 pairs (see help section)
defaults = getDefaultParameters();
defaultsNoVal = getDefaultParametersNoVal();
properties    = getEmlParserProperties();

if nargin==1 % only imageSize
    r = defaults;
    return;
end

pvPairStartIdx = 1;

%varargin{pvPairStartIdx:end} = varargin{pvPairStartIdx:end};
optarg = eml_parse_parameter_inputs(defaultsNoVal, properties, varargin{pvPairStartIdx:end});

Method = eml_get_parameter_value(optarg.Method, ...
    defaults.Method, varargin{pvPairStartIdx:end});
ContrastThreshold = (eml_get_parameter_value( ...
    optarg.ContrastThreshold, defaults.ContrastThreshold, varargin{pvPairStartIdx:end}));
BlockSize = (eml_get_parameter_value( ...
    optarg.BlockSize, defaults.BlockSize, varargin{pvPairStartIdx:end}));
DisparityRange = (eml_get_parameter_value( ...
    optarg.DisparityRange, defaults.DisparityRange, varargin{pvPairStartIdx:end}));
TextureThreshold = (eml_get_parameter_value( ...
    optarg.TextureThreshold, defaults.TextureThreshold, varargin{pvPairStartIdx:end}));
UniquenessThreshold = (eml_get_parameter_value( ...
    optarg.UniquenessThreshold, defaults.UniquenessThreshold, varargin{pvPairStartIdx:end}));
DistanceThreshold = (eml_get_parameter_value( ...
    optarg.DistanceThreshold, defaults.DistanceThreshold, varargin{pvPairStartIdx:end}));

checkMethod(Method);

checkContrastThreshold(ContrastThreshold);
checkBlockSize(BlockSize, imageSize);
checkDisparityRange(DisparityRange, imageSize);
checkTextureThreshold(TextureThreshold);
checkUniquenessThreshold(UniquenessThreshold);
skipCheck = isscalar(DistanceThreshold) && ...
    (DistanceThreshold == defaults.DistanceThreshold);
if ~skipCheck
    checkDistanceThreshold(DistanceThreshold, imageSize);
end

r.Method = Method;
r.ContrastThreshold = ContrastThreshold;
r.BlockSize = BlockSize;
r.DisparityRange = DisparityRange;
r.TextureThreshold = TextureThreshold;
r.UniquenessThreshold = UniquenessThreshold;
r.DistanceThreshold = DistanceThreshold;

%==========================================================================
function defaults = getDefaultParameters()

defaults = struct(...
    'Method', 'SemiGlobal',...
    'ContrastThreshold', 0.5, ...
    'BlockSize',   15, ...
    'DisparityRange',   [0 64], ...
    'TextureThreshold',   0.0002, ...
    'UniquenessThreshold',   15, ...
    'DistanceThreshold',  -107); % unusual value

%==========================================================================
function defaultsNoVal = getDefaultParametersNoVal()

defaultsNoVal = struct(...
    'Method',uint32(0),...
    'ContrastThreshold', uint32(0), ...
    'BlockSize',   uint32(0), ...
    'DisparityRange',   uint32(0), ...
    'TextureThreshold',   uint32(0), ...
    'UniquenessThreshold',   uint32(0), ...
    'DistanceThreshold',  uint32(0));

%==========================================================================
function properties = getEmlParserProperties()

properties = struct( ...
    'CaseSensitivity', false, ...
    'StructExpand',    true, ...
    'PartialMatching', false);

%==========================================================================
function r = checkMethod(value)
list = {'BlockMatching', 'SemiGlobal'};
validateattributes(value, {'char'}, {'nonempty'}, 'disparity', ...
    'Method');
matchedValue = validatestring(value, list,  mfilename, 'Method');
coder.internal.errorIf(~strcmpi(value, matchedValue), ...
    'vision:validateString:unrecognizedStringChoice', value);
r = 1;

%==========================================================================
function r = checkContrastThreshold(value)
validateattributes(value, {'numeric'}, ...
    {'real', 'scalar', '>', 0, '<=', 1},...
    mfilename, 'ContrastThreshold');
r = 1;

%==========================================================================
function r = checkBlockSize(value, imageSize)
maxBlockSize = min([imageSize, 255]);
validateattributes(value, {'numeric'}, ...
    {'real', 'scalar', 'integer', 'odd', '>=', 5, '<=', maxBlockSize},...
    mfilename, 'BlockSize');
r = 1;

%==========================================================================
function r = checkDisparityRange(value,imageSize)
maxValue = min(imageSize);
validateattributes(value, {'numeric'}, ...
    {'real', 'nonsparse', 'integer', 'finite', 'size', [1,2], ...
    '>', -maxValue, '<', maxValue},...
    mfilename, 'DisparityRange');

errIf(value(2) <= value(1) || mod(value(2) - value(1), 16) ~= 0, ...
    'vision:disparity:invalidDisparityRange');

r = 1;

%==========================================================================
function r = checkTextureThreshold(value)
validateattributes(value, {'numeric'}, ...
    {'real', 'scalar', 'finite', 'nonnegative', '<', 1},...
    mfilename, 'TextureThreshold');
r = 1;

%==========================================================================
function r = checkUniquenessThreshold(value)
validateattributes(value, {'numeric'}, ...
    {'real', 'scalar', 'integer', 'finite', 'nonnegative'},...
    mfilename, 'UniquenessThreshold');
r = 1;

%==========================================================================
function r = checkDistanceThreshold(value, imageSize)
maxValue = min(imageSize);
if ~isempty(value)
    validateattributes(value, {'numeric'}, ...
        {'real', 'scalar', 'integer', 'finite', 'nonnegative','<',maxValue},...
        mfilename, 'DistanceThreshold');
end
r = 1;

%==========================================================================
function flag = isSimMode()

flag = isempty(coder.target);

%==========================================================================
function errIf(condition, msgID)

coder.internal.errorIf(condition, msgID);
