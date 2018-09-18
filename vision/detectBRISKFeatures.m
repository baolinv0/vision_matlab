function points = detectBRISKFeatures(I, varargin) 
% detectBRISKFeatures Finds BRISK features.
%   points = detectBRISKFeatures(I) returns a BRISKPoints object, points,
%   containing information about BRISK features detected in a 2-D grayscale
%   image I. detectBRISKFeatures uses the Binary Robust Invariant Scalable
%   Keypoints (BRISK) algorithm to detect multi-scale corner features.
%
%   points = detectBRISKFeatures(I,Name,Value) specifies additional
%   name-value pair arguments described below:
%
%   'MinContrast'  A scalar T, 0 < T < 1, specifying the minimum intensity
%                  difference between a corner and its surrounding region,
%                  as a fraction of the maximum value of the image class.
%                  Increasing the value of T reduces the number of detected
%                  corners.
%
%                  Default: 0.2
%
%   'NumOctaves'   Integer scalar, NumOctaves >= 0. Increase this value to
%                  detect larger features. Recommended values are between 1
%                  and 4. Setting NumOctaves to zero disables multi-scale
%                  detection and performs the detection at the scale of I.
%                  
%                  Default: 4
%
%   'MinQuality'   A scalar Q, 0 <= Q <= 1, specifying the minimum accepted
%                  quality of corners as a fraction of the maximum corner
%                  metric value in the image. Larger values of Q can be
%                  used to remove erroneous corners.
% 
%                  Default: 0.1
%
%   'ROI'          A vector of the format [X Y WIDTH HEIGHT], specifying
%                  a rectangular region in which corners will be detected.
%                  [X Y] is the upper left corner of the region.
%
%                  Default: [1 1 size(I,2) size(I,1)]
%
% Class Support
% -------------
% The input image I can be logical, uint8, int16, uint16, single, 
% or double, and it must be real and nonsparse.
%
% Example
% -------
% % Detect BRISK points and mark their locations
%     I = imread('cameraman.tif');
%     points = detectBRISKFeatures(I);
%     imshow(I); hold on;
%     plot(points.selectStrongest(20));
%
% See also extractFeatures, matchFeatures, BRISKPoints,
%          detectHarrisFeatures, detectFASTFeatures,
%          detectMinEigenFeatures, detectSURFFeatures, detectMSERFeatures

% References
% ----------
% S. Leutenegger, M. Chli and R. Siegwart, BRISK: Binary Robust Invariant
% Scalable Keypoints, Proceedings of the IEEE International Conference on
% Computer Vision (ICCV) 2011.

% Copyright 2013 The MathWorks, Inc.

%#codegen

params = parseInputs(I, varargin{:});

points = detectBRISK(I, params);

points = selectPoints(points, params.MinQuality);

% -------------------------------------------------------------------------
% Process image and detect BRISK features
% -------------------------------------------------------------------------
function points = detectBRISK(I, params)

img  = vision.internal.detector.cropImageIfRequested(I, params.ROI, params.UsingROI);

Iu8  = im2uint8(img);

numOctaves = adjustNumOctaves(size(Iu8),params.NumOctaves);

if isempty(coder.target)
    rawPts = ocvDetectBRISK(Iu8, params.Threshold, numOctaves);
    
else
    rawPts = vision.internal.buildable.detectBRISKBuildable.detectBRISK(...
        Iu8, params.Threshold, numOctaves);
end

rawPts.Location = vision.internal.detector.addOffsetForROI(rawPts.Location, params.ROI, params.UsingROI);

points = BRISKPoints(rawPts.Location, 'Metric', rawPts.Metric, ...
    'Scale', rawPts.Scale, 'Orientation', rawPts.Orientation);


% -------------------------------------------------------------------------
% Limit number of octaves based on image size.
% -------------------------------------------------------------------------
function numOctaves = adjustNumOctaves(sz, n)
coder.internal.prefer_const(sz);
coder.internal.prefer_const(n);

maxNumOctaves = uint8(floor(log2(min(sz))));
coder.internal.prefer_const(maxNumOctaves);

if n > maxNumOctaves
    numOctaves = maxNumOctaves;
else
    numOctaves = n;
end
coder.internal.prefer_const(numOctaves);

% -------------------------------------------------------------------------
% Select points based on minimum quality 
% -------------------------------------------------------------------------
function selectedPoints = selectPoints(points, minQuality)
if isempty(points)
    selectedPoints = points;
else
    maxMetric = max(points.Metric);
    minMetric = minQuality * maxMetric;
    
    idx = points.Metric >= minMetric;
    if isempty(coder.target)
        selectedPoints = points(idx);
    else
        selectedPoints = points.getIndexedObj(idx);
    end
end

% -------------------------------------------------------------------------
% Default parameter values
% -------------------------------------------------------------------------
function defaults = getDefaultParameters(imgSize)

defaults = struct('MinContrast', single(0.2),...                 
                  'NumOctaves' , uint8(4),...
                  'MinQuality' , single(0.1), ...
                  'ROI', int32([1 1 imgSize([2 1])]));

% -------------------------------------------------------------------------
% Parse inputs
% -------------------------------------------------------------------------
function params = parseInputs(I,varargin)

if isempty(coder.target)
    parser = inputParser;
    
    defaults = getDefaultParameters(size(I));
    addParameter(parser, 'MinContrast', defaults.MinContrast);
    addParameter(parser, 'MinQuality',  defaults.MinQuality);
    addParameter(parser, 'NumOctaves',  defaults.NumOctaves);
    addParameter(parser, 'ROI',         defaults.ROI);
    
    parse(parser,varargin{:});
    
    userInput = parser.Results;  
    
    userInput.UsingROI = isempty(regexp([parser.UsingDefaults{:} ''],...
        'ROI','once'));
else
    userInput = codegenParseInputs(I,varargin{:});
end

validate(I,userInput);
params = setParams(userInput);

% -------------------------------------------------------------------------
% Input parameter parsing for codegen
% -------------------------------------------------------------------------
function results = codegenParseInputs(I,varargin)
pvPairs = struct( ...
    'MinContrast', uint32(0), ...
    'NumOctaves',  uint32(0), ...
    'MinQuality',  uint32(0),...
    'ROI',         uint32(0));

popt = struct( ...
    'CaseSensitivity', false, ...
    'StructExpand'   , true, ...
    'PartialMatching', false);

defaults = getDefaultParameters(size(I));

optarg = eml_parse_parameter_inputs(pvPairs, popt, varargin{:});

results.MinContrast  = eml_get_parameter_value(optarg.MinContrast, ...
    defaults.MinContrast, varargin{:});

results.NumOctaves = eml_get_parameter_value(optarg.NumOctaves, ...
    defaults.NumOctaves, varargin{:});

results.MinQuality = eml_get_parameter_value(optarg.MinQuality, ...
    defaults.MinQuality, varargin{:});

if optarg.ROI==uint32(0)
    results.UsingROI = false;
else
    results.UsingROI = true;
end

results.ROI = eml_get_parameter_value(optarg.ROI,defaults.ROI, varargin{:});

 
% -------------------------------------------------------------------------
% Set parameters based on user input
% -------------------------------------------------------------------------
function params = setParams(userInput)
minContrast = single(userInput.MinContrast);

params.Threshold  = uint8(minContrast * single(255.0));
params.NumOctaves = uint8(userInput.NumOctaves);
params.MinQuality = single(userInput.MinQuality);
params.UsingROI   = logical(userInput.UsingROI);
params.ROI        = userInput.ROI;

% -------------------------------------------------------------------------
% Validate user input
% -------------------------------------------------------------------------
function validate(I, userInput)

vision.internal.inputValidation.validateImage(I, 'I', 'grayscale');

vision.internal.detector.checkMinQuality(userInput.MinQuality);

vision.internal.detector.checkMinContrast(userInput.MinContrast);

if userInput.UsingROI
    vision.internal.detector.checkROI(userInput.ROI,size(I));
end

checkNumOctaves(userInput.NumOctaves);

% -------------------------------------------------------------------------
% Check number of octaves
% -------------------------------------------------------------------------
function checkNumOctaves(n)

vision.internal.errorIfNotFixedSize(n,'NumOctaves');

validateattributes(n,{'numeric'},...
    {'scalar','>=',0, 'real','nonsparse','integer'},...
    'detectBRISKFeatures','NumOctaves');

