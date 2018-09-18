function RGB = insertMarker(I, position, varargin)
%insertMarker Insert markers in image or video stream.
%  This function marks points in images with a specified marker. The
%  markers are drawn by overwriting pixel values. You can use it with
%  either a grayscale or truecolor image input.
%
% RGB = insertMarker(I, POSITION) returns a truecolor image with inserted
% plus markers. The input image, I, can be either a truecolor or grayscale
% image. The input POSITION can be either an M-by-2 matrix of M number of
% [x y] pairs or any of the  <a href="matlab:helpview(fullfile(docroot,'toolbox','vision','vision.map'),'pointfeaturetypes')">point feature types</a>. The center positions for the
% markers are defined by either the [x y] pairs of the matrix or by the
% POSITION.Location property of the cornerPoints object.
%
%  RGB = insertMarker(I, POSITION, MARKER) returns a truecolor image
%  marked with MARKER. MARKER is a string that specifies marker type. It
%  can be full text or corresponding symbol as shown in parentheses:
%  'circle' (or 'o'), 'x-mark' (or 'x'), 'plus' (or '+'), 'star' (or '*'),
%  'square' (or 's') 
%  Default marker: 'plus'
%
%  RGB = insertMarker(...,'Name',Value,...) specifies additional name-value
%  pair arguments described below:
%
%  'Size'            Specifies the size of the marker, in pixels. It's a
%                    scalar with value greater than or equal to 1.
%
%                    Default: 3
%
%  'Color'           Defines marker's color. It can be specified as:
%                    - a 'color' string or an [R, G, B] vector defining a
%                      color for all markers, or
%                    - a cell array of M strings or an M-by-3 matrix of 
%                      RGB values for each marker
%
%                    RGB values must be in the range of the image data type. 
%
%                    Supported color strings are: 'blue', 'green', 'red',
%                    'cyan', 'magenta', 'yellow', 'black', 'white'
%
%                    Default: 'green'
% 
%  Class Support
%  -------------
%  The class of input I can be uint8, uint16, int16, double, single. Output
%  RGB matches the class of I.
%
%  Example:
%  --------
%  I = imread('peppers.png');
%
%  % draw plus('+')
%  RGB = insertMarker(I, [147 279]); 
%
%  % draw four x-marks
%  pos   = [120 248;195 246;195 312;120 312];
%  color = {'red', 'white', 'green', 'magenta'};
%  RGB = insertMarker(RGB, pos, 'x', 'color', color, 'size', 10); 
%
%  % show output
%  imshow(RGB);
%
%  See also insertShape, insertObjectAnnotation, insertText, cornerPoints, 
%    SURFPoints, BRISKPoints, MSERRegions

%#codegen
%#ok<*EMCLS>
%#ok<*EMCA>

%% == Parse inputs and validate ==
checkNumArgin(I, position, varargin{:});
 
[tmpRGB, position, markerIdx, markerSize, color, isEmpty]= ...
    validateAndParseInputs(I, position, varargin{:});

% handle empty I or empty position
if isEmpty 
    RGB = tmpRGB;
    return;
end
%% == Setup System Objects ==
dtClass = coder.internal.const(class(I));
h_MarkerInserter = getSystemObjects(markerIdx, dtClass, markerSize, ...
    tmpRGB, position,color);

%% == Output ==
% insert marker
tuneMarkersize(h_MarkerInserter, markerSize);
RGB = h_MarkerInserter.step(tmpRGB, position, color);

%==========================================================================
function checkNumArgin(varargin)

if (isSimMode())
    narginchk(2,7);
else
    eml_lib_assert(nargin >= 2 && nargin <= 7, ...
       'vision:insertMarker:NotEnoughArgs', 'Not enough input arguments.');
end

%==========================================================================
function flag = isSimMode()

flag = isempty(coder.target);

%==========================================================================
% Parse inputs and validate
%==========================================================================
function [RGB, position, markerIdx, markerSize, color, isEmpty] = ...
                validateAndParseInputs(I, points, varargin)

%--input image--
checkImage(I);
RGB = convert2RGB(I);
inpClass = coder.internal.const(class(I));

%--position--
% position data type does not depend on input data type 
% (input numeric or a cornerPoints object, output int32)

if ~isempty(coder.target)
    % In codegen, point objects are not supported.
    validateattributes(points, {'numeric'}, {}, mfilename, 'POSITION');
end

positionTemp = vision.internal.inputValidation.checkAndConvertPoints(...
    points, mfilename, 'POSITION');
% Check for infs and nans, because checkAndConvertPoints does not.
validateattributes(positionTemp, {'numeric'}, {'finite'}, mfilename, 'POSITION');
position = int32(positionTemp);

numRowsPos = size(position, 1);

%--isEmpty--
isEmpty = anyEmpty(I, position);

if isEmpty   
    markerIdx  = IDX_PLUS();
    markerSize = 3; % not used
    color      = ones(1,3, inpClass); % not used
else
    %--other optional parameters--
    [markerIdx, markerSize, tmpColor] = ...
        validateAndParseOptInputs(inpClass,varargin{:});
    crossCheckInputs(numRowsPos, tmpColor);    
    
    color = getColorMatrix(inpClass, numRowsPos, tmpColor);
end

%==========================================================================
function isAnyEmpty = anyEmpty(I, position)
% for fixS, check max size
% for varS, check run-time size

if isSimMode()
    isAnyEmpty = isempty(I) || isempty(position);
else
    isAnyEmpty = false;
end

%==========================================================================
function [markerIdx, markerSize, color] = ...
                               validateAndParseOptInputs(inpClass,varargin)
% Validate and parse optional inputs

defaults = getDefaultParameters(inpClass);
if nargin>1 % varargin{:} is non-empty
    if isSimMode()
        [markerIdx, markerSize, color] = ...
                       validateAndParseOptInputs_sim(defaults,varargin{:});

    else
        [markerIdx, markerSize, color] = ...
                        validateAndParseOptInputs_cg(defaults,varargin{:});
    end
else % varargin{:} is empty (no name-value pair)
    markerIdx  = defaults.MarkerIdx;
    markerSize = defaults.Size;
    color      = defaults.Color;
end

%==========================================================================
function [markerIdx, markerSize, color] = ...
                           validateAndParseOptInputs_sim(defaults,varargin)

% varargin must be non-empty
parser = inputParser;
parser.CaseSensitive = false;
parser.FunctionName  = 'insertMarker';

parser.addOptional('Marker', defaults.Marker, @checkMarker);% not a pv pair
parser.addParameter('Size', defaults.Size, @checkMarkerSize);
parser.addParameter('Color', defaults.Color);

%Parse input
parser.parse(varargin{:});

marker     = checkAndReturnMarker(parser.Results.Marker);
markerIdx  = getMarkerIdx(marker);
markerSize = double(parser.Results.Size);
color      = checkColor(parser.Results.Color, 'Color');

%==========================================================================
function [markerIdx, markerSize, color] = ...
                            validateAndParseOptInputs_cg(defaults,varargin)

% varargin must be non-empty
defaultsNoVal = getDefaultParametersNoVal();
properties    = getEmlParserProperties();

% varargin may contain optional param (marker) and PV pair 
len = length(varargin);
% check if varargin{1} is marker

if (len==1) ||(len==3) || (len==5) % 1st_arg = marker
    firstArg  = varargin{1};
    % make sure that marker is constant (e.g. coder.Constant('Plus'))
    eml_invariant(eml_is_const(firstArg),...
            eml_message('vision:insertMarker:markerNonConst'));

    tmpMarker = checkAndReturnMarker(firstArg);
    markerIdx = getMarkerIdx(tmpMarker);

    pvPairStartIdx = 2; % varargin{2:end} must be PV pair  
else
    % len is expected to be even numbered; if odd numbered, it will be a
    % bad inputs arg and will be caught using numarg check or in the
    % following parsing stage
    markerIdx = IDX_PLUS();
    pvPairStartIdx = 1;
end  

optarg = eml_parse_parameter_inputs(defaultsNoVal, properties, ...
                                    varargin{pvPairStartIdx:end});

% opacity and smoothEdges (i.e., useAntiAliasing) are input mask params
% (not from port); that's why convert these to eml_const at parsing stage

markerSize = tolower(eml_get_parameter_value( ...
              optarg.Size, defaults.Size, varargin{pvPairStartIdx:end}));
color  = tolower(eml_get_parameter_value(optarg.Color, ...
            defaults.Color, varargin{pvPairStartIdx:end}));
checkMarkerSize(markerSize);       
color  = checkColor(color, 'Color');        

%==========================================================================
function str = tolower(str)
% convert a string to lower case 

if isSimMode()
    str = lower(str);
else
    str = eml_tolower(str);
end

%==========================================================================
function checkImage(I)
% Validate input image

validateattributes(I,{'uint8', 'uint16', 'int16', 'double', 'single'}, ...
    {'real','nonsparse'}, 'insertMarker', 'I', 1)

% input image must be 2d or 3d (with 3 planes)
errCond = (ndims(I) > 3) || ((size(I,3) ~= 1) && (size(I,3) ~= 3));
errIf0(errCond, 'vision:dims:imageNot2DorRGB');

%==========================================================================
function tf = checkMarker(marker)
% Validate 'MARKER'

checkAndReturnMarker(marker);
tf = true;

%==========================================================================
function markerOut = checkAndReturnMarker(marker)
% Validate 'MARKER' and output

markerOut = validatestring(marker,{'circle','o', ...
                                   'x-mark','x' ...
                                   'plus','+', ...
                                   'star','*', ...
                                   'square','s'},'insertMarker','MARKER');

%==========================================================================
function tf = checkMarkerSize(markerSize)
% Validate 'MarkerSize'

validateattributes(markerSize, {'numeric'}, ...
   {'nonsparse', 'integer', 'scalar', 'real', 'positive'}, ...
   'insertMarker', 'Size');
tf = true;
                               
%==========================================================================
function crossCheckInputs(numRowsPos, color)
% Cross validate inputs

numColors = getNumColors(color);
errCond = (numColors ~= 1) && (numRowsPos ~= numColors);
errIf0(errCond, 'vision:insertMarker:invalidNumPosNumColor');

%==========================================================================
function colorOut = getColorMatrix(inpClass, numMarkers, color)

colorRGB = colorRGBValue(color, inpClass);
if (size(colorRGB, 1)==1)
    colorOut = repmat(colorRGB, [numMarkers 1]);
else
    colorOut = colorRGB;
end

%==========================================================================
function numColors = getNumColors(color)

% Get number of colors
numColors = 1;
if isnumeric(color)
    numColors = size(color,1);
elseif iscell(color) % if color='red', color is converted to cell earlier
    numColors = length(color);
end

%==========================================================================
function defaults = getDefaultParameters(inpClass)

% Get default values for optional parameters
% default color 'green'

switch inpClass
   case {'double', 'single'}
       green = [0 1 0];  
   case 'uint8'
       green = [0 255 0];  
   case 'uint16'
       green = [0  65535  0];          
   case 'int16'
       green = [-32768  32767 -32768];
end
       
defaults = struct(...
    'Marker', 'Plus', ...
    'MarkerIdx', IDX_PLUS(), ...
    'Size', 3, ...
    'Color', green);

%==========================================================================
function defaultsNoVal = getDefaultParametersNoVal()

defaultsNoVal = struct(...
    'Marker', uint32(0), ... 
    'Size',   uint32(0), ... 
    'Color',  uint32(0));

%==========================================================================
function properties = getEmlParserProperties()

properties = struct( ...
    'CaseSensitivity', false, ...
    'StructExpand',    true, ...
    'PartialMatching', false);

%==========================================================================
function colorOut = checkColor(color, paramName) 
% Validate 'Color'

% Validate color
if isnumeric(color)
   % must have 6 columns
   validateattributes(color, ...
       {'uint8','uint16','int16','double','single'},...
       {'real','nonsparse','nonnan', 'finite', '2d', 'size', [NaN 3]}, ...
       'insertMarker', paramName);
   colorOut = color;
else
   if ~isSimMode()
       % codegen does not support cell array
       errIf0(~isnumeric(color), 'vision:insertMarker:colorNotNumeric');
       colorOut = color;
   else
       if ischar(color)
           colorCell = {color};
       else
           validateattributes(color, {'cell'}, {}, 'insertMarker', 'Color');
           colorCell = color;
       end
       supportedColorStr = {'blue','green','red','cyan','magenta', ...
                            'yellow','black','white'};
       numCells = length(colorCell);
       colorOut = cell(1, numCells);
       for ii=1:numCells
           colorOut{ii} =  validatestring(colorCell{ii}, ...
                             supportedColorStr, 'insertMarker', paramName);
       end
   end
end

%==========================================================================
function sizeOfCache = getCacheSizeForMarkerInserter()
% Marker inserter object needs to be created for the following
% parameters:
% input data type: double,single,uint8,uint16,int16
% marker: circle,x-mark,plus,star,square

numInDTypes = 5;
numMarkers  = 5;
sizeOfCache = [numInDTypes numMarkers];  

%========================================================================== 
function inRGB = convert2RGB(I)

if ismatrix(I)
    inRGB = cat(3, I , I, I);
else
    inRGB = I;
end

%==========================================================================
function outColor = colorRGBValue(inColor, inpClass)

if isnumeric(inColor)
    outColor = cast(inColor, inpClass);
else    
    if iscell(inColor)
        colorCell = inColor;
    else
        colorCell = {inColor};
    end

   numColors = length(colorCell);
   outColor = zeros(numColors, 3, inpClass);

   for ii=1:numColors
    supportedColorStr = {'blue','green','red','cyan','magenta','yellow',...
                         'black','white'};  
    % http://www.mathworks.com/help/techdoc/ref/colorspec.html
    colorValuesFloat = [0 0 1;0 1 0;1 0 0;0 1 1;1 0 1;1 1 0;0 0 0;1 1 1];                    
    idx = strcmp(colorCell{ii}, supportedColorStr);
    switch inpClass
       case {'double', 'single'}
           outColor(ii, :) = colorValuesFloat(idx, :);
       case {'uint8', 'uint16'} 
           colorValuesUint = colorValuesFloat*double(intmax(inpClass));
           outColor(ii, :) = colorValuesUint(idx, :);
       case 'int16'
           colorValuesInt16 = im2int16(colorValuesFloat);
           outColor(ii, :) = colorValuesInt16(idx, :);           
    end
   end
end

%==========================================================================
% Setup System Objects
%==========================================================================
function h_MarkerInserter = getSystemObjects(markerIdx,inpClass, markerSize, ...
                                           rgb, position, color)

if isSimMode()
    h_MarkerInserter = getSystemObjects_sim(markerIdx,inpClass, markerSize);
else
    h_MarkerInserter = getSystemObjects_cg(markerIdx,inpClass, ...
                                           rgb, position, color);  
end

%==========================================================================
function h_MarkerInserter = getSystemObjects_sim(markerIdx,inpClass,markerSize)

persistent cache % cache for storing System Objects

if isempty(cache)
    cache.markerInserterObjects  = cell(getCacheSizeForMarkerInserter());
end

inDTypeIdx = getDTypeIdx(inpClass);

if isempty(cache.markerInserterObjects{inDTypeIdx,markerIdx})
    marker = getMarkerNameFromIdx(markerIdx);
    h_MarkerInserter  = vision.MarkerInserter('Shape', marker, ...
          'BorderColorSource','Input port', 'Size', markerSize);

    % cache the MarkerInserter object in cell array
    cache.markerInserterObjects{inDTypeIdx,markerIdx}= h_MarkerInserter;
else
  % point to the existing object
  h_MarkerInserter = cache.markerInserterObjects{inDTypeIdx,markerIdx};    
end

%==========================================================================
function h_MarkerInserter = getSystemObjects_cg(markerIdx,inpClass, ...
                                           rgb, position, color)

inDTypeIdx = coder.internal.const(getDTypeIdx(inpClass));

h_MarkerInserter = vision.internal.textngraphics.createMarkerInserter_cg ...
    (inDTypeIdx, markerIdx, rgb, position, color);

%==========================================================================
function dtIdx = getDTypeIdx(dtClass)

switch dtClass
    case 'double'
        dtIdx = 1;
    case 'single'
        dtIdx = 2;
    case 'uint8'
        dtIdx = 3;
    case 'uint16'
        dtIdx = 4;
    case 'int16'
        dtIdx = 5;
end

%==========================================================================
function marker = getMarkerNameFromIdx(markerIdx)

marker = 'Plus';
switch (markerIdx)
    case 1 % 'circle'
        marker = 'Circle';
    case 2 % 'x-mark'
        marker = 'X-mark';
    case 3 % 'plus'
        marker = 'Plus';
    case 4 % 'star'
        marker = 'Star';
    case 5 % 'square'
        marker = 'Square';    
end

%==========================================================================
function markerIdx = getMarkerIdx(marker)

% marker is always in lower-case letters (from validatestring(marker, ...))
markerIdx = IDX_PLUS();
if (strcmp(marker,'circle')  || strcmp(marker,'o'))
    markerIdx = IDX_CIRCLE();
elseif (strcmp(marker,'x-mark') || strcmp(marker,'x'))
    markerIdx = IDX_XMARK();
elseif (strcmp(marker,'plus') || strcmp(marker,'+')) 
    markerIdx = IDX_PLUS();
elseif (strcmp(marker,'star') || strcmp(marker,'*'))
    markerIdx = IDX_STAR();
elseif (strcmp(marker,'square') || strcmp(marker,'s'))
    markerIdx = IDX_SQUARE();
end
coder.internal.prefer_const(markerIdx);
    
%========================================================================== 
function markerIdx = IDX_CIRCLE()
coder.inline('always');
markerIdx = int8(1);
    
%========================================================================== 
function markerIdx = IDX_XMARK()
coder.inline('always');
markerIdx = int8(2);
    
%========================================================================== 
function markerIdx = IDX_PLUS()
coder.inline('always');
markerIdx = int8(3);
    
%========================================================================== 
function markerIdx = IDX_STAR()
coder.inline('always');
markerIdx = int8(4);
    
%========================================================================== 
function markerIdx = IDX_SQUARE()
coder.inline('always');
markerIdx = int8(5);

%========================================================================== 
function tuneMarkersize(h_MarkerInserter, markerSize)

if (markerSize ~= h_MarkerInserter.Size)
    h_MarkerInserter.Size = markerSize;
end

%==========================================================================
function errIf0(condition, msgID)

coder.internal.errorIf(condition, msgID);

