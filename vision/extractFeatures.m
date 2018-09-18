function [features, valid_points] = extractFeatures(I, points, varargin)
%extractFeatures Extract interest point descriptors
%   extractFeatures extracts feature vectors, also known as descriptors,
%   from a binary or intensity image. Descriptors are derived from pixels
%   surrounding an interest point. They are needed to describe and match 
%   features specified by a single point location.
%
%   [FEATURES, VALID_POINTS] = extractFeatures(I, POINTS) returns FEATURES,
%   an M-by-N matrix of M feature vectors, also known as descriptors.
%   FEATURES can also be a binaryFeatures object. Each descriptor is of
%   length N. The function also returns M number of VALID_POINTS
%   corresponding to each descriptor. The method used for descriptor
%   extraction depends on class of POINTS:
%
%     Class of POINTS            Descriptor extraction method
%     ---------------            ---------------------------------
%     - SURFPoints object        - Speeded-Up Robust Features (SURF)
%     - MSERRegions object       - Speeded-Up Robust Features (SURF)
%     - cornerPoints object      - Fast Retina Keypoint (FREAK)
%     - BRISKPoints object       - Fast Retina Keypoint (FREAK)
%     - KAZEPoints object        - Non-linear image pyramid based rotation
%                                  and orientation invariant features,
%                                  similar to SURF but favoring non-noise
%                                  points
%     - M-by-2 matrix of [x y]   - Simple square neighborhood around [x y]
%       coordinates                point location
%
%   [FEATURES, VALID_POINTS] = extractFeatures(I, POINTS, Name, Value) 
%   specifies additional name-value pairs described below:
%
%   'Method'       - One of the strings: 
%                    'BRISK', 'FREAK', 'SURF', 'KAZE', 'Block' or 'Auto'. 
%
%         Method     Feature vector (descriptor)
%         -------    -----------------------------------
%         'BRISK'    Binary Robust Invariant Scalable Keypoints (BRISK)
%         'FREAK'    Fast Retina Keypoint (FREAK)
%         'SURF'     Speeded-Up Robust Features (SURF)
%         'KAZE'     Non-linear pyramid based features, similar to SURF
%         'Block'    Simple square neighborhood
%         'Auto'     Selects the extraction method based on the class of
%                    input points. See the table above.
%
%                    Default: 'Auto'
%
%   'BlockSize'    - An odd integer scalar defining the local square 
%                    neighborhood (BlockSize-by-BlockSize) centered at
%                    each interest point. This option is only
%                    applicable to 'Block' method.
%
%                    Default: 11
%
%   'Upright'      - A logical scalar. When set to true, the orientation of
%                    the feature vectors is not estimated. Set 'Upright'to
%                    true when you do not need the image descriptors to
%                    capture rotation information.
%                
%                    Default: false
%
%
%   'FeatureSize'  - Integer scalar set to 64 or 128. Length of the SURF or
%                    KAZE feature vector (descriptor). This property
%                    applies to both SURF and KAZE features.
%
%                    Default: 64
%
%   Notes
%   -----
%   - When 'Block' method is used, the function extracts only the 
%     neighborhoods fully contained within the image boundary, therefore 
%     VALID_POINTS may contain fewer points than input POINTS.
%
%   - When SURF, KAZE, FREAK, or BRISK is used to extract descriptors, the
%     Orientation property of returned VALID_POINTS is set to the
%     orientation of extracted features, in radians. This is useful for
%     visualizing the descriptor orientation. 
%
%   - When Upright is set to true, the feature orientation is set to pi/2
%     radians.
%
%   - When MSERRegions object is used with SURF or KAZE, the Location
%     property of  the object is used to extract SURF descriptors. The Axes
%     property is used to select the scale of the SURF descriptors such
%     that the circle representing the feature has an area proportional to
%     MSER ellipse area. The Orientation property of MSERRegions is not
%     used.
%
%   - You can increase 'FeatureSize' from the default 64 to 128 to increase
%     descriptor matching accuracy at the expense of matching speed.
%
%
%   Class Support
%   -------------
%   The input image I can be logical, uint8, uint16, int16, single, or
%   double, and it must be real and nonsparse. POINTS can be a SURFPoints,
%   MSERRegions, cornerPoints, BRISKPoints object, or KAZEPoints object, or
%   int16, uint16, int32, uint32, single or double.
%
%   Example 1
%   ---------
%   % Extract corner features from an image.
%   I = imread('cameraman.tif');
%   corners = detectHarrisFeatures(I);
%   [features, validCorners] = extractFeatures(I,corners);
%
%   % Plot valid corner points on top of I
%   figure
%   imshow(I)
%   hold on   
%   plot(validCorners)
%
%   Example 2
%   ---------
%   % Extract SURF features
%   I = imread('cameraman.tif');
%   points = detectSURFFeatures(I);
%
%   [features, validPoints] = extractFeatures(I,points);
%
%   % Visualize 10 strongest SURF features, including their scale, and 
%   % orientation which was determined during the descriptor extraction
%   % process.
%   tenStrongestPoints = selectStrongest(validPoints,10);
%   figure
%   imshow(I)
%   hold on
%   plot(tenStrongestPoints,'showOrientation',true)
%
%   Example 3
%   ---------
%   % Extract MSER features
%   I = imread('cameraman.tif');
%   regions = detectMSERFeatures(I);
%
%   % Use MSER with upright SURF feature descriptor
%   [features, validPoints] = extractFeatures(I,regions,'Upright',true);
%
%   % Visualize SURF features corresponding to the MSER ellipse centers 
%   % along with scale and orientation.
%   figure
%   imshow(I)
%   hold on
%   plot(validPoints,'showOrientation',true)
%
% See also extractHOGFeatures, extractLBPFeatures, detectHarrisFeatures, 
%     detectMinEigenFeatures, detectFASTFeatures, detectSURFFeatures, 
%     detectMSERFeatures, detectBRISKFeatures, detectKAZEFeatures,
%     matchFeatures

% Copyright 2010 The MathWorks, Inc.
%
% References
%
%  Herbert Bay, Andreas Ess, Tinne Tuytelaars, Luc Van Gool "SURF: 
%  Speeded Up Robust Features", Computer Vision and Image Understanding
%  (CVIU), Vol. 110, No. 3, pp. 346--359, 2008
%
%  Alahi, Alexandre; Ortiz, Raphael; Vandergheynst, Pierre, "FREAK: Fast 
%  Retina Keypoint", IEEE Conference on Computer Vision and Pattern 
%  Recognition, 2012
%
%  S. Leutenegger, M. Chli and R. Siegwart, BRISK: Binary Robust Invariant
%  Scalable Keypoints, to appear in Proceedings of the IEEE International
%  Conference on Computer Vision (ICCV) 2011.
%
% P. F. Alcantarilla, A. Bartoli, and A. J. Davison, KAZE Features, ECCV 2012,
% Part VI, LNCS 7577, pp. 214-227, 2012.

%#codegen
%#ok<*EMCA>

% Parse and check inputs
[blockSize, FeatureSize, descriptor,upright] ...
    = parseInputs(I, points, varargin{:});

% Extract features from image I
if strcmpi(descriptor, 'SURF')
    
    [features, valid_points] = extractSURFFeatures(I, points, FeatureSize, upright);
    
elseif strcmpi(descriptor, 'FREAK')
    
    [features, valid_points] = extractFreakFeatures(I, points, upright);
    
elseif strcmpi(descriptor, 'BRISK')
    
    [features, valid_points] = extractBRISKFeatures(I, points, upright);
    
elseif strcmpi(descriptor, 'KAZE')
    
    [features, valid_points] = extractKAZEFeatures(I, points, FeatureSize, upright);
    
else % block
    
    [features, valid_points] = extractBlockFeatures(I, points, ...
        blockSize);       
end

%==========================================================================
% Parse and check inputs
%==========================================================================
function [blockSize, FeatureSize, descriptor, upright] = ...
    parseInputs(I, points, varargin)

if isSimMode()
    [params,method] = parseInputsSimulation(varargin{:});
else
    [params,method] = parseInputsCodegen(varargin{:});
end

% Validate user input
checkImage(I);
method = checkMethod(method);
checkBlockSize(params.BlockSize);
checkFeatureSize(params.FeatureSize);
vision.internal.inputValidation.validateLogical(params.Upright,'Upright');

issueWarningIf(params.wasUprightSpecified && strcmpi(method,'block'),...
     'vision:extractFeatures:uprightInvalidForBlock');

% Cast user input to required types.
upright  = logical(params.Upright);
FeatureSize = double(params.FeatureSize);

% clip block size (necessary for codegen to avoid segV for blockSize = inf)
maxBlockSize = double(intmax('uint32'));
blockSizeIn = params.BlockSize;
if blockSizeIn > maxBlockSize
   blockSize = uint32(maxBlockSize);
else
   blockSize = uint32(blockSizeIn);
end

% Map 'Auto' into an actual descriptor choice.
descriptor = methodToDescriptor(method, points);

% Check points
isValidPointObject = vision.internal.inputValidation.isValidPointObj(points);

if ~isValidPointObject
    checkPoints(points);
else
    vision.internal.inputValidation.checkPoints(points,mfilename,'POINTS');
end

%==========================================================================
% Maps 'Auto' to the descriptor choice based on the input POINTS class,
%   i.e. detector used to extract the local features
%==========================================================================
function descriptor = methodToDescriptor(method, points)

if strcmpi(method,'Auto')
    switch class(points)
        case {'SURFPoints', 'vision.internal.SURFPoints_cg',}
            descriptor = 'SURF';
        case {'MSERRegions', 'vision.internal.MSERRegions_cg'}
            descriptor = 'SURF';
        case {'cornerPoints', 'vision.internal.cornerPoints_cg'}
            descriptor = 'FREAK';
        case {'BRISKPoints','vision.internal.BRISKPoints_cg'}
            descriptor = 'FREAK';
        case {'KAZEPoints'}
            descriptor = 'KAZE';
        otherwise % array of X, Y coordinates
            descriptor = 'Block';
    end
else
    descriptor = method;
end

%==========================================================================
% Parameter defaults
%==========================================================================
function defaults = getParameterDefaults()

defaults.Method    = 'Auto';
defaults.BlockSize = 11;
defaults.SURFSize = 64; %<flag> backward compatibility
defaults.FeatureSize = 64;
defaults.Upright   = false;

%==========================================================================
% Parse input for simulation
%==========================================================================
function [params,method] = parseInputsSimulation(varargin)

defaults = getParameterDefaults();

% Setup parser
parser = inputParser;
parser.FunctionName  = 'extractFeatures';

parser.addParameter('Method',     defaults.Method);
parser.addParameter('BlockSize',  defaults.BlockSize);
parser.addParameter('SURFSize',   defaults.FeatureSize); %only for backward compatibility
parser.addParameter('FeatureSize',defaults.FeatureSize);
parser.addParameter('Upright',    defaults.Upright);

% Parse input
parser.parse(varargin{:});

% Assign outputs
r = parser.Results;

method = r.Method;
params.BlockSize = r.BlockSize;
params.Upright   = r.Upright;
params.FeatureSize = r.FeatureSize;

wasUprightSpecified = ~any(strcmpi('Upright',parser.UsingDefaults));
params.wasUprightSpecified = wasUprightSpecified;

%<flag> backward compatibility gating for SURFSize
wasFeatureSizeSpecified = ~any(strcmpi('FeatureSize',parser.UsingDefaults));
wasSURFSizeSpecified = ~any(strcmpi('SURFSize',parser.UsingDefaults));
if wasSURFSizeSpecified
    if ~wasFeatureSizeSpecified
        if ~strcmpi(method, 'KAZE')
            params.FeatureSize = r.SURFSize;
        else
            error(message('vision:extractFeatures:useFeatureSize'));
        end
    else
        error(message('vision:extractFeatures:useEitherSURFOrFeature'));
    end
end

%==========================================================================
% Parse input for codegen
%==========================================================================
function [params,method] = parseInputsCodegen(varargin)
% Setup parser
parms = struct( ...
    'BlockSize',   uint32(0), ...
    'Method',      uint32(0), ...
    'SURFSize',    uint32(0),...
    'FeatureSize', uint32(0),...
    'Upright',     uint32(0));

popt = struct( ...
    'CaseSensitivity', false, ...
    'StructExpand',    true, ...
    'PartialMatching', false);

defaults = getParameterDefaults();

optarg = eml_parse_parameter_inputs(parms, popt, varargin{:});

blockSize = eml_get_parameter_value(optarg.BlockSize, defaults.BlockSize, varargin{:});

method = coder.internal.const(eml_tolower(eml_get_parameter_value(optarg.Method, ...
                     defaults.Method, varargin{:})));                 
                 

SURFSize = eml_get_parameter_value(optarg.SURFSize, defaults.SURFSize, varargin{:});

FeatureSize = eml_get_parameter_value(optarg.FeatureSize, defaults.FeatureSize, varargin{:});

upright = eml_get_parameter_value(optarg.Upright, defaults.Upright, varargin{:});

% method must remain out of param struct to remain const. Otherwise the
% output feature type cannot change from single to binaryFeatures. Pack the
% others into the param struct.

params.BlockSize = blockSize;
params.FeatureSize = FeatureSize;
params.Upright   = upright;

wasUprightSpecified = logical(optarg.Upright);
params.wasUprightSpecified = wasUprightSpecified;

% Backward compatibility gating for SURFSize
wasSURFSizeSpecified = false;
wasFeatureSizeSpecified = false;
for vi = 1:2:numel(varargin)
    varname = varargin{vi};
    if strcmpi(varname, 'SURFSize')
        wasSURFSizeSpecified = true;
    end
    if strcmpi(varname, 'FeatureSize')
        wasFeatureSizeSpecified = true;
    end
end
if wasSURFSizeSpecified
    if ~wasFeatureSizeSpecified
        if ~strcmpi(method, 'KAZE')
            params.FeatureSize = SURFSize;
        end
    end
end

%==========================================================================
% Parse SURF inputs
%==========================================================================
function [Iu8, ptsStruct] = parseSURFInputs(I, points)

Iu8 = im2uint8(I);

switch class(points)
  case {'MSERRegions', 'vision.internal.MSERRegions_cg'}
    location = points.Location;
    scale    = computeMSERScale(points, 1.6);
    ptsObj   = SURFPoints(location,'Scale',scale);
  case {'cornerPoints', 'vision.internal.cornerPoints_cg'}
    ptsObj = SURFPoints(points.Location, 'Metric', points.Metric);
  case {'KAZEPoints'}
    ptsObj = SURFPoints(points.Location, 'Scale', points.Scale, ...
                        'Metric', points.Metric);
  case {'SURFPoints', 'vision.internal.SURFPoints_cg'}
    ptsObj = points;    
  case {'BRISKPoints', 'vision.internal.BRISKPoints_cg'} 
    location = points.Location;        
    scale    = points.Scale ./ 6;  % map BRISK to SURF scale
    scale(scale < 1.6) = 1.6;      % saturate to min SURF scale
    ptsObj   = SURFPoints(location,'Scale',scale);    
  otherwise  % convert raw [X,Y] coordinates to SURFPoints
    ptsObj = SURFPoints(points);
end

% convert SURFPoints object back to structure required by
% the ocvExtractSurf built-in function
if isSimMode()
    ptsStruct.Location         = ptsObj.Location;
    ptsStruct.Scale            = ptsObj.Scale;
    ptsStruct.Metric           = ptsObj.Metric;
    ptsStruct.SignOfLaplacian  = ptsObj.SignOfLaplacian;    
else
    coder.varsize('valLocation',        [inf, 2]);
    coder.varsize('valScale',           [inf, 1]);
    coder.varsize('valMetric',          [inf, 1]);
    coder.varsize('valSignOfLaplacian', [inf, 1]);

    out_numel = size(ptsObj.Location,1);
    dtClass =  class(ptsObj.Location);
    valLocation        = coder.nullcopy(zeros(out_numel,2,dtClass));
    valScale           = coder.nullcopy(zeros(out_numel,1,dtClass));
    valMetric          = coder.nullcopy(zeros(out_numel,1,dtClass));
    valSignOfLaplacian = coder.nullcopy(zeros(out_numel,1,'int8'));

    valLocation(1:out_numel,:)        = ptsObj.Location;
    valScale(1:out_numel,:)           = ptsObj.Scale;
    valMetric(1:out_numel,:)          = ptsObj.Metric;
    valSignOfLaplacian(1:out_numel,:) = ptsObj.SignOfLaplacian;

    ptsStruct.Location         = valLocation;
    ptsStruct.Scale            = valScale;
    ptsStruct.Metric           = valMetric;
    ptsStruct.SignOfLaplacian  = valSignOfLaplacian;
end

%==========================================================================
% Parse KAZE inputs
%==========================================================================
function [Iu8, ptsStruct, threshold, ...
          noctaves, nscalelevels, diffusion] = parseKAZEInputs(I, points)

Iu8 = im2uint8(I);
switch class(points)
  case {'MSERRegions', 'vision.internal.MSERRegions_cg'}
    location = points.Location;
    scale    = computeMSERScale(points, 1.6);
    ptsObj   = KAZEPoints(location,'Scale',scale);
  case {'cornerPoints', 'vision.internal.cornerPoints_cg'}
    ptsObj = KAZEPoints(points.Location, 'Metric', points.Metric);
  case {'KAZEPoints'}
    ptsObj = points;
  case {'SURFPoints', 'vision.internal.SURFPoints_cg'}
    ptsObj = KAZEPoints(points.Location, 'Scale', points.Scale, ...
                        'Metric', points.Metric);    
  case {'BRISKPoints', 'vision.internal.BRISKPoints_cg'} 
    location = points.Location;        
    scale    = points.Scale ./ 6;  % map BRISK to SURF scale
    scale(scale < 1.6) = 1.6;      % saturate to min SURF scale
    ptsObj   = KAZEPoints(location,'Scale',scale);    
  otherwise  % convert raw [X,Y] coordinates to SURFPoints
    ptsObj = KAZEPoints(points);
end

%% populate the scale space related attributes
%if ~strcmpi(class(points),'KAZEPoints')
%    ptsObj = populateInternalKAZEPointsAttributes(ptsObj);
%end

% convert KAZEPoints object back to structure required by
% the ocvExtractKAZE built-in function.
% NOTE: the conversion of Scale from radius to diameter is not done at this
% point, but in a later step before calling the ocvExtractKAZE built-in
% function.
if isSimMode()
    ptsStruct.Location         = ptsObj.Location;
    ptsStruct.Scale            = ptsObj.Scale;
    ptsStruct.Metric           = ptsObj.Metric;
    ptsStruct.Orientation      = ptsObj.Orientation;
    ptsStruct.Misc             = ptsObj.getLayerID();
    noctaves                   = ptsObj.getNumOctaves();
    nscalelevels               = ptsObj.getNumScaleLevels();
    diffusion                  = ptsObj.getDiffusion();
    threshold                  = single(0); % Threshold is ignored.
else
    error(message('vision:extractFeatures:noCodegenKAZE'));
end

%==========================================================================
%function outPts = populateInternalKAZEPointsAttributes(inPts)
%outPts = inPts;
%outPts = setLayerID(outPts, ones(length(inPts), 1));
%outPts = setNumOctaves(outPts, 1);
%outPts = setNumScaleLevels(outPts, 3);
%outPts = setDiffusion(outPts, 'region');

%==========================================================================
function checkImage(I)
vision.internal.inputValidation.validateImage(I, 'I', 'grayscale');

%==========================================================================
function checkPoints(points)

sz = [NaN 2];

validateattributes(points,{'int16', 'uint16', 'int32', 'uint32', ...
    'single', 'double'}, {'2d', 'nonsparse', 'real', 'size', sz},...
    mfilename, 'POINTS', 2);

%==========================================================================
function str = checkMethod(method)

str = validatestring(method,{'Block','SURF','KAZE','FREAK','BRISK','Auto'},...
    mfilename,'Method');

%==========================================================================
function checkBlockSize(blockSize)

validateattributes(blockSize,{'numeric'}, {'nonempty', ...
    'finite', 'nonsparse', 'real', 'positive', 'integer', 'odd', ...
    'scalar'}, mfilename, 'BlockSize');

%==========================================================================
function checkFeatureSize(FeatureSize)
validateattributes(FeatureSize,{'numeric'}, {'scalar'}, 'extractFeatures',...
    'FEATURE_SIZE');

%<flag> message catalog?
coder.internal.errorIf(FeatureSize ~= 64 && FeatureSize ~= 128, ...
    'vision:extractFeatures:invalidFeatureSize');

%==========================================================================
% Extract block features
%==========================================================================
function [features, valid_points] = extractBlockFeatures(I, points, ...
    blockSize)

if isCornerPointObj(points) || isBRISKPointsObj(points)
    % for cornerPoints and BRISKPoints, output points is same as input
    % points.
    [features, valid_indices] = ...
        extractBlockAlg(I, points.Location, blockSize);
    
    valid_points = extractValidPoints(points, valid_indices);
 else
    % For other input, valid_points is the location of points
    if isSURFPointObj(points) || isMSERRegionObj(points) || isKAZEPointObj(points)
        pointsTmp = points.Location;
    else
        % X/Y points
        pointsTmp = points;
    end
    
    [features, valid_indices] = extractBlockAlg(I, pointsTmp, blockSize);
    
    valid_points = extractValidPoints(pointsTmp, valid_indices);
end

function [features, valid_indices] = extractBlockAlg(I, points, blockSize)
% Define casting constants
intClass = 'int32';
uintClass = 'uint32';

% Define length of feature vector
lengthFV = cast(blockSize*blockSize, uintClass);

nPoints = size(points,1);
if (islogical(I))
    features = false(nPoints, lengthFV);
else
    features = zeros(nPoints, lengthFV, 'like', I);
end
valid_indices = zeros(nPoints, 1);

%--------------------------------------------------------
% Define working variables needed for feature extraction
%--------------------------------------------------------
% Determine image size
nRows = cast(size(I, 1), intClass);
nCols = cast(size(I, 2), intClass);

% Compute half length of blockSize-by-blockSize neighborhood in units of
% integer pixels
halfSize = cast( (blockSize-mod(blockSize, 2)) / 2, intClass);

%------------------
% Extract features
%------------------
nValidPoints = cast(0, uintClass);
% Iterate over the set of input interest points, extracting features when
% the blockSize-by-blockSize neighborhood centered at the interest point is
% fully contained within the image boundary.
for k = 1:nPoints
    % Convert current interest point coordinates to integer pixels (Note:
    % geometric origin is at (0.5, 0.5)).
    [c, r] = castAndRound(points, k, intClass);
    % c = cast_ef(round_ef(points(k,1)), intClass);
    % r = cast_ef(round_ef(points(k,2)), intClass);
    
    % Check if interest point is within the image boundary
    if (c > halfSize && c <= (nCols - halfSize) && ...
        r > halfSize && r <= (nRows - halfSize))
        % Increment valid interest point count
        nValidPoints = nValidPoints + 1;        
        % Reshape raw image data around the interest point into a feature
        % vector
        features(nValidPoints, :) = reshape(I(r-halfSize:r+halfSize, ...
            c-halfSize:c+halfSize), 1, lengthFV);
        % Save associated interest point location
        valid_indices(nValidPoints) = k;
    end
end

% Trim output data
features = features(1:nValidPoints, :);
valid_indices = valid_indices(1:nValidPoints,:);

%==========================================================================
% Extract SURF features
%==========================================================================
function [features, valid_points] = extractSURFFeatures(I, points, SURFSize,upright)
[Iu8,ptsStruct] = parseSURFInputs(I,points);

params.extended = SURFSize == 128;
params.upright  = upright;

if isSimMode()
    [vPts, features] = ocvExtractSurf(Iu8, ptsStruct, params);
else
    if coder.isColumnMajor
        % column-major (matlab) to row-major (opencv)        
        Iu8T = Iu8';
    else
        Iu8T = Iu8;
    end    

    % SURFSize is the width of the feature
    [outLocation, outScale, outMetric, outSignOfLaplacian, outOrientation, features] = ...
        vision.internal.buildable.extractSurfBuildable.extractSurf_uint8(Iu8T, ...
        ptsStruct.Location, ptsStruct.Scale, ptsStruct.Metric, ...
        ptsStruct.SignOfLaplacian, SURFSize, params.extended, params.upright);
    
    vPts.Location        = outLocation;
    vPts.Scale           = outScale;
    vPts.Metric          = outMetric;
    vPts.SignOfLaplacian = outSignOfLaplacian;
    vPts.Orientation     = outOrientation;
end

% modify the orientation so that it is measured counter-clockwise from
% horizontal the x-axis
vPts.Orientation = single(2*pi) - vPts.Orientation;

if isCornerPointObj(points)
    % For cornerPoints input, valid_points is a cornerPoints object
    valid_points = cornerPoints(vPts.Location, 'Metric', vPts.Metric);
    
elseif isBRISKPointsObj(points)
    valid_points = BRISKPoints(vPts.Location, 'Metric', vPts.Metric,...
        'Scale', 6 * vPts.Scale, 'Orientation', vPts.Orientation);
else
    % For other inputs, valid_points is a SURFPoints object
    valid_points = SURFPoints(vPts.Location, vPts);
end

%==========================================================================
% Extract KAZE features
%==========================================================================
function [features, valid_points] = extractKAZEFeatures(I, points, FeatureSize, upright)

% retrieve extraction parameters and prepare extraction inputs.
[Iu8, ptsStruct, threshold, noctaves, nscalelevels, diffusion] = parseKAZEInputs(I,points);

ptsStruct.Scale = ptsStruct.Scale*2; % convert radius to diameter

params.extended = FeatureSize == 128;
params.upright  = upright;

if isSimMode()
    diffusionCode = vision.internal.detector.convertKAZEDiffusionToOCVCode(diffusion);
    [features, vPts] = ocvExtractKAZE(Iu8, ptsStruct, params.extended, ...
                                      params.upright, threshold, ...
                                      noctaves, nscalelevels, ...
                                      diffusionCode);
else
    error(message('vision:extractFeatures:noCodegenKAZE'));
end

% modify the orientation so that it is measured counter-clockwise from
% horizontal the x-axis
vPts.Orientation = single(pi/2) - vPts.Orientation;
vPts.Scale = vPts.Scale/2; % convert from diameter to radius

if isCornerPointObj(points)
    % For cornerPoints input, valid_points is a cornerPoints object
    valid_points = cornerPoints(vPts.Location, 'Metric', vPts.Metric);
    
elseif isBRISKPointsObj(points)
    valid_points = BRISKPoints(vPts.Location, 'Metric', vPts.Metric,...
        'Scale', 6 * vPts.Scale, 'Orientation', vPts.Orientation);
else
    % For other inputs, valid_points is a KAZEPoints object
    valid_points = KAZEPoints(vPts.Location, 'Diffusion', diffusion, ...
                              'Scale', vPts.Scale, 'Orientation', vPts.Orientation, ...
                              'Metric', vPts.Metric, 'NumOctaves', noctaves, ...
                              'NumScaleLevels', nscalelevels, 'LayerID', vPts.Misc);
end

%==========================================================================
% Extract freak features
%==========================================================================
function [features, valid_points] = extractFreakFeatures(I, points, upright)

Iu8 = im2uint8(I);

ptsStruct = pointsToFREAKPoints(points);

% configure parameters
params.nbOctave              = 4;
params.orientationNormalized = ~upright;
params.scaleNormalized       = true;
params.patternScale          = 7;

% extract
if isSimMode()
    [validPts, features] = ocvExtractFreak(Iu8, ptsStruct, params);
else
    if coder.isColumnMajor
        % column-major (matlab) to row-major (opencv)        
        Iu8T = Iu8';
    else
        Iu8T = Iu8;
    end      
    [outLocation, outScale, outMetric, outMisc, outOrientation, features] = ...
        vision.internal.buildable.extractFreakBuildable.extractFreak_uint8(Iu8T, ...
        ptsStruct.Location, ptsStruct.Scale, ptsStruct.Metric, ptsStruct.Misc, ...
        params.nbOctave, params.orientationNormalized, ...
        params.scaleNormalized, params.patternScale); 
    validPts.Location        = outLocation;
    validPts.Scale           = outScale;
    validPts.Metric          = outMetric;
    validPts.Misc            = outMisc;
    validPts.Orientation     = outOrientation; % yes for FREAK too
end

% repackage features to the desired final format
features = binaryFeatures(features);

validPts.Orientation = correctOrientation(validPts.Orientation, upright);

valid_points = extractValidPoints(points, validPts.Misc);

if isSURFPointObj(points) || isBRISKPointsObj(points) || isKAZEPointObj(points)
    % update with orientation estimated during extraction    
    valid_points = setOrientation(valid_points, validPts.Orientation);    
end

%==========================================================================
% Extract BRISK features
%==========================================================================
function [features, valid_points] = extractBRISKFeatures(I,points,upright)

Iu8 = im2uint8(I);

ptsStruct = pointsToBRISKPoints(points);

params.upright = upright;

if isSimMode()
    [features, validPts] = ocvExtractBRISK(Iu8, ptsStruct, params);
else
    [features, validPts] = ...
        vision.internal.buildable.extractBRISKBuildable.extractBRISKFeatures(Iu8, ptsStruct, params);
end

features = binaryFeatures(features);

validPts.Orientation = correctOrientation(validPts.Orientation, upright);

valid_points = extractValidPoints(points, validPts.Misc);

if isSURFPointObj(points) || isBRISKPointsObj(points) || isKAZEPointObj(points)
    % update with orientation estimated during extraction    
    valid_points = setOrientation(valid_points, validPts.Orientation);    
end

%==========================================================================
% Correct the orientation returned from OpenCV such that it is measured
% counter-clockwise from horizontal the x-axis. 
% 
% For upright features, the convention is that they have orientations of
% pi/2. However, OpenCV's orientation values are zero when orientation is
% not estimated. As a result, the orientation is manually set to pi/2.
%==========================================================================
function orientation = correctOrientation(orientation, upright)
if upright    
    % By convention, upright features have orientation of pi/2.     
    orientation(:) = single(pi/2);
else
    orientation(:) = single(2*pi) - orientation;   
end

%==========================================================================
% Compute the scale for MSER regions
%==========================================================================
function scale = computeMSERScale(points, minScale)
if isempty(points.Axes)
    scale = zeros(0,1,'single');
else
    majorAxes  = points.Axes(:,1);
    minorAxes  = points.Axes(:,2);
    % Make the scale proportional to the ellipse area.
    scale      = 1/8*sqrt(majorAxes.*minorAxes);
    scale((scale < minScale)) = single(minScale);
end


%==========================================================================
% Converts any point type to make it compatible with FREAK
%==========================================================================
function ptsStruct = pointsToFREAKPoints(points)

switch class(points)
    case {'MSERRegions','vision.internal.MSERRegions_cg'}
        ptsStruct.Location = points.Location;
        scale = computeMSERScale(points, 1.6);
        ptsStruct.Scale    = round(scale * 7.5);
        ptsStruct.Metric   = zeros(size(scale), 'single');
        ptsStruct.Orientation = zeros(size(scale), 'single');
        len = size(points.Location,1);
    case {'SURFPoints','vision.internal.SURFPoints_cg'}
        ptsStruct.Location = points.Location;
        ptsStruct.Scale    = round(points.Scale .* 7.5);
        ptsStruct.Metric   = points.Metric;
        ptsStruct.Orientation = points.Orientation;
        len = size(points.Location,1);
    case {'KAZEPoints'}
        ptsStruct.Location = points.Location;
        ptsStruct.Scale    = round(points.Scale .* 7.5);
        ptsStruct.Metric   = points.Metric;
        ptsStruct.Orientation = points.Orientation;
        len = size(points.Location,1);
    case {'cornerPoints','vision.internal.cornerPoints_cg'}
        ptsStruct.Location = points.Location;
        % The value of 18 below corresponds to the FREAK pattern radius.
        ptsStruct.Scale    = ones(size(points.Metric), 'single').*18;
        ptsStruct.Metric   = points.Metric;
        ptsStruct.Orientation = zeros(size(points.Metric), 'single');
        len = size(points.Location,1);
    case {'BRISKPoints','vision.internal.BRISKPoints_cg'}
        ptsStruct.Location    = points.Location;
        % The value of 12 and 18 below corresponds to the BRISK and FREAK
        % pattern radius, respectively. 
        ptsStruct.Scale       = points.Scale .* (18/12);
        ptsStruct.Metric      = points.Metric;
        ptsStruct.Orientation = points.Orientation;
        len = size(points.Location,1);
    otherwise
        ptsStruct.Location = single(points);       
        % The value of 18 below corresponds to the FREAK pattern radius.
        ptsStruct.Scale    = ones(1, size(points,1), 'single').*18;
        ptsStruct.Metric   = zeros(1, size(points, 1), 'single');
        ptsStruct.Orientation = zeros(1, size(points,1), 'single');
        len = size(points,1);
end

% encode the point index in the Misc property; we'll use it to determine
% which points were removed during the extraction process
ptsStruct.Misc = int32(1):int32(len);

%==========================================================================
% Maps data from feature points to equivalent BRISK points.
%==========================================================================
function ptsStruct = pointsToBRISKPoints(points)

switch class(points)
    case {'MSERRegions','vision.internal.MSERRegions_cg'}
        ptsStruct.Location = points.Location;                        
        scale = computeMSERScale(points, 12);
        ptsStruct.Scale    = scale;
        ptsStruct.Metric   = zeros(size(scale), 'single');
        ptsStruct.Orientation = zeros(1, length(scale),'single');
        len = size(points.Location,1);
        
    case {'SURFPoints','vision.internal.SURFPoints_cg'}
        ptsStruct.Location = points.Location;
        ptsStruct.Metric   = points.Metric;
        
        % Set the BRISK scale to be 10*s which covers most of the
        % equivalent SURF extraction region.
        ptsStruct.Scale    = round(points.Scale .* 10);
        ptsStruct.Orientation = points.Orientation;
        len = size(points.Location,1);
        
    case {'KAZEPoints'}
        ptsStruct.Location = points.Location;
        ptsStruct.Metric   = points.Metric;
        
        % Set the BRISK scale to be 10*s which covers most of the
        % equivalent KAZE extraction region.
        ptsStruct.Scale    = round(points.Scale .* 10);
        ptsStruct.Orientation = points.Orientation;
        len = size(points.Location,1);
        
    case {'cornerPoints','vision.internal.cornerPoints_cg'}
        % The value of 12 corresponds to the BRISK pattern size at
        % scale 0. Corner points are treated as single scale detections.
        ptsStruct.Location = points.Location;                 
        ptsStruct.Metric   = points.Metric;
        ptsStruct.Scale    = ones(size(points.Metric), 'single').* 12;
        ptsStruct.Orientation = zeros(1, length(points.Metric), 'single');
        len = size(points.Location,1);
        
    case {'BRISKPoints','vision.internal.BRISKPoints_cg'}        
        ptsStruct.Location    = points.Location;
        ptsStruct.Metric      = points.Metric;
        ptsStruct.Scale       = points.Scale;
        ptsStruct.Orientation = points.Orientation;       
        len = size(points.Location,1);
        
    otherwise
        ptsStruct.Location = single(points);
        ptsStruct.Metric   = zeros(1, size(points, 1), 'single');        
        ptsStruct.Scale    = ones(1, size(points, 1), 'single').*12;
        ptsStruct.Orientation = zeros(1,size(points,1),'single');
        len = size(points,1);
end

% encode the point index in the Misc property; we'll use it to determine
% which points were removed during the extraction process
ptsStruct.Misc = int32(1):int32(len);

%==========================================================================
function [c, r] = castAndRound(points, k, intClass)

if ~isobject(points)
    c = cast(round(points(k,1)), intClass);
    r = cast(round(points(k,2)), intClass);
else
    c=0;
    r=0;
end

%==========================================================================
function validPoints = extractValidPoints(points, idx)
if isnumeric(points)
    validPoints = points(idx,:);
else    
    if isempty(coder.target)
        validPoints = points(idx);
    else
        validPoints = getIndexedObj(points, idx);
    end
end

%==========================================================================
function issueWarningIf(valueIsTrue, id)
coder.extrinsic('warning','message');
if valueIsTrue   
   warning(message(id));       
end

%==========================================================================
function flag = isCornerPointObj(points)

flag = isa(points, 'cornerPoints') || ...
       isa(points, 'vision.internal.cornerPoints_cg');
   
%==========================================================================
function flag = isSURFPointObj(points)

flag = isa(points, 'SURFPoints') || ...
       isa(points, 'vision.internal.SURFPoints_cg');

%==========================================================================
function flag = isKAZEPointObj(points)

flag = isa(points, 'KAZEPoints');
   
%==========================================================================
function flag = isMSERRegionObj(points)

flag = isa(points, 'MSERRegions') || ...
       isa(points, 'vision.internal.MSERRegions_cg');
   
%==========================================================================
function flag = isBRISKPointsObj(points)

flag = isa(points, 'BRISKPoints') || ...
       isa(points, 'vision.internal.BRISKPoints_cg');
   
%==========================================================================
function flag = isSimMode()

flag = isempty(coder.target);

