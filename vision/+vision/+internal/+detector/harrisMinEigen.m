function corners = harrisMinEigen(method, I, varargin)
% harrisMinEigen Compute corner metric
%   POINTS = harrisMinEigen('Harris',I) returns a cornerPoints object,
%   POINTS, containing information about the feature points detected in a
%   2-D grayscale image I, using the Harris-Stephens algorithm.
%
%   POINTS = harrisMinEigen('MinEigen',I) returns a cornerPoints object,
%   POINTS, containing information about the feature points detected in a
%   2-D grayscale image I, using the minimum eigenvalue algorithm developed
%   by Shi and Tomasi.
%
%   POINTS = harrisMinEigen(...,Name,Value) specifies additional
%   name-value pair arguments described below:
%
%   'MinQuality'  A scalar Q, 0 <= Q <= 1, specifying the minimum accepted
%                 quality of corners as a fraction of the maximum corner
%                 metric value in the image. Larger values of Q can be used
%                 to remove erroneous corners.
% 
%                 Default: 0.01
%
%   'FilterSize'  An odd integer, S >= 3, specifying a Gaussian filter 
%                 which is used to smooth the gradient of the image.
%                 The size of the filter is S-by-S and the standard
%                 deviation of the filter is (S/3).
%
%                 Default: 5
%
%   'ROI'         A vector of the format [X Y WIDTH HEIGHT], specifying
%                 a rectangular region in which corners will be detected.
%                 [X Y] is the upper left corner of the region.
%
%                 Default: [1 1 size(I,2) size(I,1)]
%
% Class Support
% -------------
% The input image I can be logical, uint8, int16, uint16, single, or
% double, and it must be real and nonsparse.

% Copyright 2012 The MathWorks, Inc.

%#codegen
%#ok<*EMCA>

% Check and parse inputs.
if isSimMode()    
    try %#ok<EMTC>
        [params, filterSize] = parseInputs(I, varargin{:});    
    catch ME
        throwAsCaller(ME);
    end
else
    [params, filterSize] = parseInputs(I, varargin{:});
end

% Convert image to single.
I = im2single(I);



if params.usingROI   
    % If an ROI has been defined, we expand it so corners will be detected
    % on valid pixels instead of padded pixels. We then crop the image
    % within the expanded region.
    imageSize   = size(I);
    expandSize  = floor(params.FilterSize / 2);
    expandedROI = vision.internal.detector.expandROI(imageSize, ...
        params.ROI, expandSize);
    Ic = vision.internal.detector.cropImage(I, expandedROI);    
else
    expandedROI = coder.nullcopy(zeros(1, 4, 'like', params.ROI));
    Ic = I;    
end

% Create a 2-D Gaussian filter.
filter2D = createFilter(filterSize);
% Compute the corner metric matrix.
metricMatrix = cornerMetric(method, Ic, filter2D);
% Find peaks, i.e., corners, in the corner metric matrix.
locations = vision.internal.findPeaks(metricMatrix, params.MinQuality);
locations = subPixelLocation(metricMatrix, locations);

% Compute corner metric values at the corner locations.
metricValues = computeMetric(metricMatrix, locations);

if params.usingROI
    % Because the ROI was expanded earlier, we need to exclude corners
    % which locate outside the original ROI.
    [locations, metricValues] = ...
        vision.internal.detector.excludePointsOutsideROI(...
        params.ROI, expandedROI, locations, metricValues);
end

% Pack the output to a cornerPoints object.
corners = cornerPoints(locations, 'Metric', metricValues);

%==========================================================================
% Compute corner metric value at the sub-pixel locations by using
% bilinear interpolation
function values = computeMetric(metric, loc)
x = loc(:, 1);
y = loc(:, 2);
x1 = floor(x);
y1 = floor(y);
x2 = x1 + 1;
y2 = y1 + 1;

sz = size(metric);
values = metric(sub2ind(sz,y1,x1)) .* (x2-x) .* (y2-y) ...
         + metric(sub2ind(sz,y1,x2)) .* (x-x1) .* (y2-y) ...
         + metric(sub2ind(sz,y2,x1)) .* (x2-x) .* (y-y1) ...
         + metric(sub2ind(sz,y2,x2)) .* (x-x1) .* (y-y1);

%==========================================================================
% Compute corner metric matrix
function metric = cornerMetric(method, I, filter2D)
% Compute gradients
A = imfilter(I,[-1 0 1] ,'replicate','same','conv');
B = imfilter(I,[-1 0 1]','replicate','same','conv');

% Crop the valid gradients
A = A(2:end-1,2:end-1);
B = B(2:end-1,2:end-1);

% Compute A, B, and C, which will be used to compute corner metric.
C = A .* B;
A = A .* A;
B = B .* B;

% Filter A, B, and C.
A = imfilter(A,filter2D,'replicate','full','conv');
B = imfilter(B,filter2D,'replicate','full','conv');
C = imfilter(C,filter2D,'replicate','full','conv');

% Clip to image size
removed = max(0, (size(filter2D,1)-1) / 2 - 1);
A = A(removed+1:end-removed,removed+1:end-removed);
B = B(removed+1:end-removed,removed+1:end-removed);
C = C(removed+1:end-removed,removed+1:end-removed);

if strcmpi(method,'Harris')
    % The parameter k which was defined in the Harris method is set to 0.04
    k = 0.04; 
    metric = (A .* B) - (C .^ 2) - k * ( A + B ) .^ 2;
else
    metric = ((A + B) - sqrt((A - B) .^ 2 + 4 * C .^ 2)) / 2;
end

%==========================================================================
% Compute sub-pixel locations
function loc = subPixelLocation(metric, loc)
loc = subPixelLocationImpl(metric, reshape(loc', 2, 1, []));
loc = squeeze(loc)';

%==========================================================================
% Compute sub-pixel locations using bi-variate quadratic function fitting.
% Reference: http://en.wikipedia.org/wiki/Quadratic_function
function subPixelLoc = subPixelLocationImpl(metric, loc)

nLocs = size(loc,3);
patch = zeros([3, 3, nLocs], 'like', metric);
x = loc(1,1,:);
y = loc(2,1,:);
xm1 = x-1;
xp1 = x+1;
ym1 = y-1;
yp1 = y+1;
xsubs = [xm1, x, xp1;
         xm1, x, xp1;
         xm1, x, xp1];
ysubs = [ym1, ym1, ym1;
         y, y, y;
         yp1, yp1, yp1];
linind = sub2ind(size(metric), ysubs(:), xsubs(:));
patch(:) = metric(linind);

dx2 = ( patch(1,1,:) - 2*patch(1,2,:) +   patch(1,3,:) ...
    + 2*patch(2,1,:) - 4*patch(2,2,:) + 2*patch(2,3,:) ...
    +   patch(3,1,:) - 2*patch(3,2,:) +   patch(3,3,:) ) / 8;

dy2 = ( ( patch(1,1,:) + 2*patch(1,2,:) + patch(1,3,:) )...
    - 2*( patch(2,1,:) + 2*patch(2,2,:) + patch(2,3,:) )...
    +   ( patch(3,1,:) + 2*patch(3,2,:) + patch(3,3,:) )) / 8;

dxy = ( + patch(1,1,:) - patch(1,3,:) ...
        - patch(3,1,:) + patch(3,3,:) ) / 4;

dx = ( - patch(1,1,:) - 2*patch(2,1,:) - patch(3,1,:)...
       + patch(1,3,:) + 2*patch(2,3,:) + patch(3,3,:) ) / 8;

dy = ( - patch(1,1,:) - 2*patch(1,2,:) - patch(1,3,:) ...
       + patch(3,1,:) + 2*patch(3,2,:) + patch(3,3,:) ) / 8;

detinv = 1 ./ (dx2.*dy2 - 0.25.*dxy.*dxy);

% Calculate peak position and value
x = -0.5 * (dy2.*dx - 0.5*dxy.*dy) .* detinv; % X-Offset of quadratic peak
y = -0.5 * (dx2.*dy - 0.5*dxy.*dx) .* detinv; % Y-Offset of quadratic peak

% If both offsets are less than 1 pixel, the sub-pixel location is
% considered valid.
isValid = (abs(x) < 1) & (abs(y) < 1);
x(~isValid) = 0;
y(~isValid) = 0;
subPixelLoc = [x; y] + loc;

%==========================================================================
% Create a Gaussian filter
function f = createFilter(filterSize)
sigma = filterSize / 3;
f = fspecial('gaussian', filterSize, sigma);

%==========================================================================
function [params, filterSize] = parseInputs(I, varargin)

checkImage(I);

imageSize = size(I);

if isSimMode()    
    [params, filterSize] = parseInputs_sim(imageSize, varargin{:});    
else
    [params, filterSize] = parseInputs_cg(imageSize, varargin{:});
end

vision.internal.detector.checkMinQuality(params.MinQuality);
checkFilterSize(params.FilterSize, imageSize);

%==========================================================================
function [params, filterSize] = parseInputs_sim(imgSize, varargin)

% Instantiate an input parser
parser   = inputParser;
defaults = getParameterDefaults(imgSize);

% Parse and check the optional parameters
parser.addParameter('MinQuality', defaults.MinQuality);
parser.addParameter('FilterSize', defaults.FilterSize);
parser.addParameter('ROI',        defaults.ROI);
parser.parse(varargin{:});

params = parser.Results;
filterSize = params.FilterSize;

params.usingROI = isempty(regexp([parser.UsingDefaults{:} ''],...
    'ROI','once'));

if params.usingROI
    vision.internal.detector.checkROI(params.ROI, imgSize);   
end

params.ROI = vision.internal.detector.roundAndCastToInt32(params.ROI);

%==========================================================================
function [params, filterSize] = parseInputs_cg(imgSize, varargin)

% varargin must be non-empty
defaultsNoVal = getDefaultParametersNoVal();
properties    = getEmlParserProperties();

[defaults, defaultFilterSize] = getParameterDefaults(imgSize);

optarg = eml_parse_parameter_inputs(defaultsNoVal, properties, varargin{:});

MinQuality = eml_get_parameter_value(optarg.MinQuality, ...
    defaults.MinQuality, varargin{:});

FilterSize = eml_get_parameter_value(optarg.FilterSize, ...
    defaultFilterSize, varargin{:});

ROI = eml_get_parameter_value(optarg.ROI, defaults.ROI, varargin{:});   

% FilterSize must be a constant
if (nargin>1) && (optarg.FilterSize ~= uint32(0))
    % FilterSize is user-defined here
    eml_invariant(eml_is_const(FilterSize), ...
        eml_message('vision:harrisMinEigen:filterSizeNotConst'),...
        'IfNotConst','Fail');
end
params.MinQuality = MinQuality;
% filterSize looses its const'ness when it is put in struct 'params'.
% That is why Filter Size is passed separately.
params.FilterSize = FilterSize; filterSize = FilterSize;

usingROI = ~(optarg.ROI==uint32(0));

if usingROI
    params.usingROI = true;  
    vision.internal.detector.checkROI(ROI, imgSize);   
else
    params.usingROI = false;
end

params.ROI = vision.internal.detector.roundAndCastToInt32(ROI);

%==========================================================================
function [filterSize] = getFilterSizeDefault()
filterSize = coder.internal.const(5);

%==========================================================================
function [defaults, filterSize] = getParameterDefaults(imgSize)
filterSize = getFilterSizeDefault();
defaults = struct('MinQuality' , single(0.01), ...     
                  'FilterSize' , filterSize,...
                  'ROI', int32([1 1 imgSize([2 1])]));

%==========================================================================
function properties = getEmlParserProperties()

properties = struct( ...
    'CaseSensitivity', false, ...
    'StructExpand',    true, ...
    'PartialMatching', false);

%==========================================================================
function defaultsNoVal = getDefaultParametersNoVal()

defaultsNoVal = struct(...
    'MinQuality', uint32(0), ... 
    'FilterSize', uint32(0), ... 
    'ROI',  uint32(0));

%==========================================================================
function r = checkImage(I)

vision.internal.inputValidation.validateImage(I, 'I', 'grayscale');

r = true;

%==========================================================================
function tf = checkFilterSize(x,imageSize)

validateattributes(x,{'numeric'},...
    {'nonempty', 'nonnan', 'nonsparse', 'real', 'scalar', 'odd',...
    '>=', 3}, mfilename,'FilterSize');

% cross validate filter size and image size
maxSize = min(imageSize);
defaultFilterSize = getFilterSizeDefault();

coder.internal.errorIf(x > maxSize, ...
    'vision:harrisMinEigen:filterSizeGTImage',defaultFilterSize);

tf = true;

%==========================================================================
function flag = isSimMode()

flag = isempty(coder.target);
