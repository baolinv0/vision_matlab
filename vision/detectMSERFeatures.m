function [regions, cc] = detectMSERFeatures(I, varargin)
%detectMSERFeatures Finds MSER features.
%   regions = detectMSERFeatures(I) returns an MSERRegions object, regions,
%   containing region pixel lists and other information about MSER features
%   detected in a 2-D grayscale image I. detectMSERFeatures uses Maximally
%   Stable Extremal Regions (MSER) algorithm to find regions.
%
%   [..., cc] = detectMSERFeatures(I) optionally returns MSER regions in a
%   connected component structure. This output is useful for measuring
%   region properties using the <a href="matlab:help regionprops">regionprops</a> function. The connected 
%   component structure, cc, contains four fields:
%    
%       Connectivity   Connectivity of the MSER regions (default is 8)
% 
%       ImageSize      Size of I.
% 
%       NumObjects     Number of MSER regions in I.
% 
%       PixelIdxList   1-by-NumObjects cell array where the kth element
%                      in the cell array is a vector containing the linear
%                      indices of the pixels in the kth MSER region.
%
%   regions = detectMSERFeatures(I,Name,Value) specifies additional
%   name-value pair arguments described below:
%
%   'ThresholdDelta'   Scalar value, 0 < ThresholdDelta <= 100, expressed 
%                      as a percentage of the input data type range. This 
%                      value specifies the step size between intensity 
%                      threshold levels used in selecting extremal regions 
%                      while testing for their stability. Decrease this 
%                      value to return more regions. Typical values range 
%                      from 0.8 to 4.
%
%                      Default: 2
%
%   'RegionAreaRange'  Two-element vector, [minArea maxArea], which
%                      specifies the size of the regions in pixels. This  
%                      value allows the selection of regions containing 
%                      pixels between minArea and maxArea, inclusive.
%
%                      Default: [30 14000]
%
%   'MaxAreaVariation' Positive scalar. Increase this value to return a  
%                      greater number of regions at the cost of their
%                      stability. Stable regions are very similar in
%                      size over varying intensity thresholds. Typical 
%                      values range from 0.1 to 1.0.
%
%                      Default: 0.25
%
%   'ROI'              A vector of the format [X Y WIDTH HEIGHT],
%                      specifying a rectangular region in which corners
%                      will be detected. [X Y] is the upper left corner of
%                      the region.                                     
%                 
%                      Default: [1 1 size(I,2) size(I,1)]
%
%   Class Support
%   -------------
%   The input image I can be uint8, int16, uint16, single or double, 
%   and it must be real and nonsparse.
%
%   Example 1 - Detect and plot MSER regions
%   ----------------------------------------
%   % Find MSER regions
%   I = imread('cameraman.tif');
%   regions = detectMSERFeatures(I);
%
%   % Visualize MSER regions which are described by pixel lists stored 
%   % inside the returned 'regions' object
%   figure
%   imshow(I)
%   hold on
%   plot(regions, 'showPixelList', true, 'showEllipses', false)
%
%   % Display ellipses and centroids fit into the regions
%   figure
%   imshow(I)
%   hold on
%   plot(regions) % by default, plot displays ellipses and centroids
%
%   Example 2 - Find circular MSER regions
%   --------------------------------------
%   % Detect MSER regions
%   I = imread('coins.png');
%   [regions, mserCC] = detectMSERFeatures(I);
% 
%   % Show all detected MSER REgions
%   figure
%   imshow(I)
%   hold on
%   plot(regions, 'showPixelList', true, 'showEllipses', false)
% 
%   % Measure MSER region eccentricity to gauge region circularity.
%   stats = regionprops('table', mserCC, 'Eccentricity');
% 
%   % Circular regions have low eccentricity. Threshold eccentricity values to
%   % only keep the circular regions.
%   eccentricityIdx = stats.Eccentricity < 0.55;
%   circularRegions = regions(eccentricityIdx);
% 
%   % Show circular regions
%   figure
%   imshow(I)
%   hold on
%   plot(circularRegions, 'showPixelList', true, 'showEllipses', false)
%   
%   See also MSERRegions, extractFeatures, matchFeatures,
%            detectBRISKFeatures, detectFASTFeatures, detectHarrisFeatures,
%            detectMinEigenFeatures, detectSURFFeatures, SURFPoints

%   Copyright 2011-2017 The MathWorks, Inc.

%   References:
%      Jiri Matas, Ondrej Chum, Martin Urban, Tomas Pajdla. "Robust
%      wide-baseline stereo from maximally stable extremal regions",
%      Proc. of British Machine Vision Conference, pages 384-396, 2002.
%
%      David Nister and Henrik Stewenius, "Linear Time Maximally Stable 
%      Extremal Regions", European Conference on Computer Vision, 
%      pages 183-196, 2008. 

%#codegen
%#ok<*EMCA>

[Iu8, params] = parseInputs(I,varargin{:});

if isSimMode()
    % regionsCell is pixelLists in a cell array {a x 2; b x 2; c x 2; ...} and
    % can only be handled in simulation mode since cell arrays are not supported
    % in code generation
    regionsCell = ocvExtractMSER(Iu8, params);
    
    if params.usingROI && ~isempty(params.ROI)        
        regionsCell = offsetPixelList(regionsCell, params.ROI);
    end
    
    regions = MSERRegions(regionsCell);
    
else
    [pixelList, lengths] = ...
        vision.internal.buildable.detectMserBuildable.detectMser_uint8(Iu8, params);
    
    if params.usingROI && ~isempty(params.ROI) % offset location values
        pixelList = offsetPixelListCodegen(pixelList, params.ROI);
    end
    
    regions = MSERRegions(pixelList, lengths);
    
end

if nargout == 2      
    cc = region2cc(regions, size(I));   
end

%==========================================================================
% Convert MSER regions to connected component struct
%==========================================================================
function cc = region2cc(regions, imageSize)

if isempty(coder.target)
    % Convert PixelList to PixelIdxList and pack into connected component struct.
    
    pixelIdxList = cell(1, regions.Count);
    for i = 1:regions.Count
        locations = regions.PixelList{i};
        pixelIdxList{i} = sub2ind(imageSize, locations(:,2), locations(:,1));
    end
    
    cc.Connectivity = 8;
    cc.ImageSize    = imageSize;
    cc.NumObjects   = regions.Count;
    cc.PixelIdxList = pixelIdxList;
    
else
    % Code generation path    
    idxCount = coder.internal.indexInt([0;cumsum(regions.Lengths)]);
    regionIndices = coder.nullcopy(zeros(sum(regions.Lengths),1));
    
    % MSER regions are stored as x,y locations. convert them to
    % linear indices for return in the CC struct.
    for k = 1:regions.Count
        
        range = idxCount(k)+1:idxCount(k+1);
        
        locations = regions.PixelList(range, :);
        
        idx = sub2ind(imageSize, locations(:,2), locations(:,1));
        
        regionIndices(range,1) = idx;
    end
    
    cc.Connectivity  = 8;
    cc.ImageSize     = imageSize;
    cc.NumObjects    = regions.Count;
    cc.RegionIndices = regionIndices;
    cc.RegionLengths = cast(regions.Lengths, 'like', idxCount);
    
end

%==========================================================================
% Parse and check inputs
%==========================================================================
function [img, params] = parseInputs(I, varargin)

vision.internal.inputValidation.validateImage(I, 'I', 'grayscale');

Iu8 = im2uint8(I);

imageSize = size(I);

% To avoid crash in MSER::detectRegions.
isAnyDimUnsuitable = any(imageSize < 3);
coder.internal.errorIf(isAnyDimUnsuitable, ...
    'vision:detectMSERFeatures:imageSizeSmallerThanMinimum');

if isSimMode()
    params = parseInputs_sim(imageSize, varargin{:});
else
    params = parseInputs_cg(imageSize, varargin{:});
end

%--------------------------------------------------------------------------
% Other OpenCV parameters which are not exposed in the main interface
%--------------------------------------------------------------------------
params.minDiversity  = single(0.2);
params.maxEvolution  = int32(200);
params.areaThreshold = 1;
params.minMargin     = 0.003;
params.edgeBlurSize  = int32(5);

img = vision.internal.detector.cropImageIfRequested(Iu8, params.ROI, params.usingROI);

%==========================================================================
function params = parseInputs_sim(imageSize, varargin)
% Parse the PV pairs
parser = inputParser;

defaults = getDefaultParameters(imageSize);

parser.addParameter('ThresholdDelta',   defaults.ThresholdDelta);
parser.addParameter('RegionAreaRange',  defaults.RegionAreaRange);
parser.addParameter('MaxAreaVariation', defaults.MaxAreaVariation);
parser.addParameter('ROI',              defaults.ROI)

% Parse input
parser.parse(varargin{:});

checkThresholdDelta(parser.Results.ThresholdDelta);

params.usingROI  = ~ismember('ROI', parser.UsingDefaults);

roi = parser.Results.ROI;
if params.usingROI
    vision.internal.detector.checkROI(roi, imageSize);
end

isAreaRangeUserSpecified = ~ismember('RegionAreaRange', parser.UsingDefaults);

if isAreaRangeUserSpecified 
    checkRegionAreaRange(parser.Results.RegionAreaRange, imageSize, ...
        params.usingROI, roi);
end

checkMaxAreaVariation(parser.Results.MaxAreaVariation);

% Populate the parameters to pass into OpenCV's ocvExtractMSER()
params.delta        = parser.Results.ThresholdDelta*255/100;
% To avoid 'delta' being 0. 'delta' needs to be strictly between 1 and 255.
if params.delta < 1
    params.delta = 1;
end
params.minArea      = parser.Results.RegionAreaRange(1);
params.maxArea      = parser.Results.RegionAreaRange(2);
params.maxVariation = parser.Results.MaxAreaVariation;
params.ROI          = parser.Results.ROI;

%==========================================================================
function params = parseInputs_cg(imageSize, varargin)

% Optional Name-Value pair: 3 pairs (see help section)
defaults = getDefaultParameters(imageSize);
defaultsNoVal = getDefaultParametersNoVal();
properties    = getEmlParserProperties();

optarg = eml_parse_parameter_inputs(defaultsNoVal, properties, varargin{:});
parser_Results.ThresholdDelta = (eml_get_parameter_value( ...
        optarg.ThresholdDelta, defaults.ThresholdDelta, varargin{:}));
parser_Results.RegionAreaRange = (eml_get_parameter_value( ...
    optarg.RegionAreaRange, defaults.RegionAreaRange, varargin{:}));
parser_Results.MaxAreaVariation = (eml_get_parameter_value( ...
    optarg.MaxAreaVariation, defaults.MaxAreaVariation, varargin{:}));
parser_ROI  = eml_get_parameter_value(optarg.ROI, defaults.ROI, varargin{:});

checkThresholdDelta(parser_Results.ThresholdDelta);

% check whether ROI parameter is specified
usingROI = optarg.ROI ~= uint32(0);

if usingROI
    vision.internal.detector.checkROI(parser_ROI, imageSize);    
end

% check whether area range parameter is specified
isAreaRangeUserSpecified = optarg.RegionAreaRange ~= uint32(0);

if isAreaRangeUserSpecified 
    checkRegionAreaRange(parser_Results.RegionAreaRange, imageSize,...
        usingROI, parser_ROI);
end

checkMaxAreaVariation(parser_Results.MaxAreaVariation);
% To avoid 'delta' being 0. 'delta' needs to be strictly between 1 and 255.
if (parser_Results.ThresholdDelta*255/100) < 1
    params.delta    = cCast('int32_T', 1);
else
    params.delta    = cCast('int32_T', parser_Results.ThresholdDelta*255/100);
end

params.minArea      = cCast('int32_T', parser_Results.RegionAreaRange(1));
params.maxArea      = cCast('int32_T', parser_Results.RegionAreaRange(2));
params.maxVariation = cCast('real32_T', parser_Results.MaxAreaVariation);
params.ROI          = parser_ROI;
params.usingROI     = usingROI;

%==========================================================================
% Offset pixel list locations based on ROI
%==========================================================================
function pixListOut = offsetPixelList(pixListIn, roi)
n = size(pixListIn,1);
pixListOut = cell(n,1);
for i = 1:n   
    pixListOut{i} = vision.internal.detector.addOffsetForROI(pixListIn{i}, roi, true);
end

%==========================================================================
% Offset pixel list locations based on ROI
%==========================================================================
function pixListOut = offsetPixelListCodegen(pixListIn, roi)

pixListOut = vision.internal.detector.addOffsetForROI(pixListIn, roi, true);

%==========================================================================
function defaults = getDefaultParameters(imgSize)
       
defaults = struct(...
    'ThresholdDelta', 5*100/255, ...
    'RegionAreaRange', [30 14000], ...
    'MaxAreaVariation', 0.25,...
    'ROI', [1 1 imgSize(2) imgSize(1)]);

%==========================================================================
function defaultsNoVal = getDefaultParametersNoVal()

defaultsNoVal = struct(...
    'ThresholdDelta', uint32(0), ... 
    'RegionAreaRange', uint32(0), ... 
    'MaxAreaVariation', uint32(0), ...
    'ROI', uint32(0));

%==========================================================================
function properties = getEmlParserProperties()

properties = struct( ...
    'CaseSensitivity', false, ...
    'StructExpand',    true, ...
    'PartialMatching', false);

%==========================================================================
function tf = checkThresholdDelta(thresholdDelta)
validateattributes(thresholdDelta, {'numeric'}, {'scalar',...
    'nonsparse', 'real', 'positive', '<=', 100}, mfilename);
tf = true;

%==========================================================================
function checkRegionAreaRange(regionAreaRange, imageSize, usingROI, roi)

if usingROI
    % When an ROI is specified, the region area range validation should
    % be done with respect to the ROI size.
    sz = int32([roi(4) roi(3)]);
else
    sz = int32(imageSize);
end

imgArea = sz(1)*sz(2);
validateattributes(regionAreaRange, {'numeric'}, {'integer',... 
    'nonsparse', 'real', 'positive', 'size', [1,2]}, mfilename);

coder.internal.errorIf(regionAreaRange(2) < regionAreaRange(1), ...
    'vision:detectMSERFeatures:invalidRegionSizeRange');

% When the imageSize is less than area range, throw a warning.
if imgArea < int32(regionAreaRange(1))
    coder.internal.warning('vision:detectMSERFeatures:imageAreaLessThanAreaRange')
end


%==========================================================================
function tf = checkMaxAreaVariation(maxAreaVariation)
validateattributes(maxAreaVariation, {'numeric'}, {'nonsparse', ...
    'real', 'scalar', '>=', 0}, mfilename);
tf = true;

%==========================================================================
function flag = isSimMode()

flag = isempty(coder.target);

%==========================================================================
function outVal = cCast(outClass, inVal)
outVal = coder.nullcopy(zeros(1,1,outClass));
outVal = coder.ceval(['('   outClass  ')'], inVal);


