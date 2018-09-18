function RGB = insertText(I, position, text, varargin)
%insertText Insert text in image or video stream.
%  This function inserts text into an image or video. You can use it with
%  either a grayscale or truecolor image input. 
%
%  RGB = insertText(I, position, textString) returns a truecolor image
%  with text string inserted into it. The input image, I, can be either a
%  truecolor or grayscale image. position is an M-by-2 matrix of [x y]
%  coordinates of the upper-left corner of the text bounding box. The input
%  textString can be a single UNICODE text string or a cell array of
%  UNICODE strings of length M, where M is the number of rows in position.
%  If a single text string is provided it is used for all positions.
%
%  RGB = insertText(I, position, numericValue) returns a truecolor image
%  with numeric values inserted into it. numericValue can be a scalar or a
%  vector of length M. If a scalar value is provided it is used for all
%  positions. Numeric values are converted to string using format '%0.5g'
%  as used by SPRINTF.
%
%  RGB = insertText(..., Name, Value)
%  specifies additional name-value pair arguments described below:
%
%  'Font'          Font face of text. Specify the font of the text as one 
%                  of the available truetype fonts installed on your
%                  system. To get a list of available fonts, type
%                  'listTrueTypeFonts' in the command prompt.
%
%                  Default: 'LucidaSansRegular'
%
%  'FontSize'      Font size, specified in points, as a positive integer 
%                  value. Value must be between 1 and 200.
%
%                  Default: 12
%
%  'TextColor'     Color for the text string. You can specify a different
%                  color for each string, or one color for all the strings.
%                  - To specify a color for each text string, set
%                    'TextColor' to a cell array of M strings or an M-by-3
%                    matrix of RGB values.
%                  - To specify one color for all text strings, set
%                    'TextColor' to either a color string or an [R G B]
%                    vector.
%                  RGB values must be in the range of the image data type.
%                  Supported color strings are, 'blue', 'green', 'red',
%                  'cyan', 'magenta', 'yellow', 'black', 'white'
%
%                  Default: 'black'
%
%  'BoxColor'      Color of the text box. Specify the color in the same way
%                  as the 'TextColor'.
%   
%                  Default: 'yellow'
%
%  'BoxOpacity'    A scalar value from 0 to 1 defining the opacity of the
%                  text box. 0 corresponds to fully transparent and 1 to
%                  fully opaque. No text box appears when BoxOpacity is 0.
%                         
%                  Default: 0.6
% 
%  'AnchorPoint'   Defines the relative location of a point on the text
%                  box. Text box for each text string is positioned by
%                  placing the reference point (called anchor point) of the
%                  text box at point [x y] defined by a row in 'position'.
%                  AnchorPoint can be one of the following strings:
%                  'LeftTop',    'CenterTop',    'RightTop', 
%                  'LeftCenter', 'Center',       'RightCenter', 
%                  'LeftBottom', 'CenterBottom', 'RightBottom'                    
%   
%                  Default: 'LeftTop'
%
%  Note
%  ----
%  For code generation, only ASCII or extended ASCII textString is supported.
%
%  Class Support
%  -------------
%  The class of input I can be uint8, uint16, int16, double, single. Output
%  RGB matches the class of I.
%
%  Example 1: Insert numeric values and Non-ASCII character
%  --------------------------------------------------------
%  I = imread('peppers.png');
%  position =  [1 50; 100 50]; % [x y]
%  value = [555 pi];
% 
%  % Display numeric values
%  RGB = insertText(I, position, value, 'Font', 'LucidaSansRegular', ...
%                   'AnchorPoint', 'LeftBottom');
%  % Display non-ASCII character (U+014C)
%  OWithMacron=native2unicode([hex2dec('C5') hex2dec('8C')],'UTF-8');
%  RGB = insertText(RGB, [256 50], OWithMacron, 'BoxColor', 'w');
%  figure
%  imshow(RGB)
%  title('Numeric values and Non-ASCII character')
%
%  Example 2: Insert numbers and strings
%  -------------------------------------
%  I = imread('board.tif');
%  % Create texts with fractional values
%  text_str = cell(3,1);
%  conf_val = [85.212 98.76 78.342]; % Detection confidence
%  for ii=1:3
%     text_str{ii} = ['Confidence: ' num2str(conf_val(ii),'%0.2f') '%'];
%  end
%  position = [23 373; 35 185; 77 107]; % [x y]
%  box_color = {'red','green','yellow'};
% 
%  RGB = insertText(I, position, text_str, 'FontSize', 18, ...
%         'BoxColor', box_color, 'BoxOpacity', 0.4);
%  figure
%  imshow(RGB)
%  title('Board')
%
%  See also insertShape, insertMarker, insertObjectAnnotation,
%     listTrueTypeFonts

%#codegen
%#ok<*EMCA>

% included shapeWidth, shapeHeight parameter to control text box width
% for insertObjectAnnotation

%% == Parse inputs and validate ==
narginchk(3,19);
 
[RGB, position, text, isScalarText, anchorPoint, textColor, boxColor, ...
    boxOpacity, font, fontFileName, faceIndex, fontSize, ...
    shapeWidth, shapeHeight, isEmpty] = ...
    validateAndParseInputs(I, position, text, varargin{:});

% handle empty I or empty position
if isEmpty    
    return;
end

%% == get glyph info ==
if isSimMode
  [glyphStruct,fontStruct,maxBitmapSize]= ...
      populateGlyphBuffer_sim(font,fontFileName,faceIndex,fontSize);
else
  [glyphStruct,fontStruct,maxBitmapSize]= ...
      populateGlyphBuffer_cg(fontFileName,faceIndex,fontSize);
end

isNumericText = coder.internal.const(isnumeric(text));
numPos = size(position, 1);
textIdx = 1;
for ii=1:numPos
    if (~isScalarText)
        textIdx = ii;
    end

    %thisText = getTextStr(text, textIdx);
    if (isNumericText)
        thisTextVal = text(textIdx);
        thisText = cvstNum2Str(thisTextVal);
    else
        thisText = text{textIdx};
    end

    thisTextU16 = uint16(thisText);
    
    if (~isempty(thisTextU16))
        %% == Output ==
        if isSimMode()
            numPlanes = 3;
            anchorPointVal = int32(sum(lower(anchorPoint)));
            [RGB, textLocXY, hasMissingCharInFont, spaceCharWidth] ...
                = visionInsertTextBox(RGB, position(ii,:), thisTextU16, ...
                anchorPointVal, boxColor(ii,:), boxOpacity, ...
                glyphStruct, fontStruct, ...
                shapeWidth(ii), shapeHeight(ii), numPlanes);
            
            if (hasMissingCharInFont)
                if isDefaultFont(font)
                    warning(message('vision:insertText:missingCharInDefFont', font));
                else
                    warning(message('vision:insertText:missingCharInFont', font));
                end
            end
            
            textLocationXY.x = textLocXY(1);
            textLocationXY.y = textLocXY(2);
            
            visionInsertGlyph(RGB, thisTextU16, textLocationXY, ...
                textColor(ii,:),glyphStruct,fontStruct,spaceCharWidth, ...
                maxBitmapSize);            
        else
            
            %% == insert text box ==
            [RGB, textLocationXY, spaceCharWidth] = insertTextBox(RGB, ...
                position(ii,:), thisTextU16, anchorPoint, ...
                boxColor(ii,:), boxOpacity, glyphStruct, fontStruct, ...
                shapeWidth(ii), shapeHeight(ii));
            RGB = insertGlyphs(RGB, thisTextU16, textLocationXY, ...
                textColor(ii,:),glyphStruct,fontStruct,spaceCharWidth);

        end
    end
end
%==========================================================================
% Parse inputs and validate for simulation
%==========================================================================
function [RGB,position,outText,isScalarText,anchorPoint,textColor,...
    boxColor,boxOpacity,font,fontFileName,faceIndex, ...
    fontSize,shapeWidth,shapeHeight,isEmpty] = ...
    validateAndParseInputs(I, position, text, varargin)

coder.extrinsic('listTrueTypeFonts');
    
%--input image--
checkImage(I);
RGB = convert2RGB(I);
inpClass = class(I);
    
%--position--
% position data type does not depend on input data type
validateattributes(position, {'numeric'}, ...
    {'real','nonsparse', '2d', 'finite', 'size', [NaN 2]}, ...
    mfilename,'POSITION', 2);
position = int32(position);
numPos = size(position, 1);

%--text--
checkText(text);

% text conversion:
[numTexts, outText] = getTexts(text);

%--isEmpty--
isEmpty = isempty(I) || isempty(position);

%--other optional parameters--
if isSimMode()
  [anchorPoint, textColor, boxColor, boxOpacity, ...
      font, fontSize, shapeWidth, shapeHeight] = ...
      validateAndParseOptInputs_sim(inpClass,varargin{:}); 
else
  [anchorPoint, textColor, boxColor, boxOpacity, ...
      font, fontSize, shapeWidth, shapeHeight] = ...
      validateAndParseOptInputs_cg(inpClass,varargin{:});         
end
crossCheckInputs(position, numTexts, textColor, boxColor);
textColor  = getColorMatrix(inpClass, numPos, textColor);
boxColor   = getColorMatrix(inpClass, numPos, boxColor);
shapeWidth  = getShapeDimMatrix(shapeWidth, numPos);
shapeHeight = getShapeDimMatrix(shapeHeight, numPos);
if isSimMode()
    [fontFileName, faceIndex] = getFontFilenameFaceindex_sim(font);
else
    [fontFileName, faceIndex] = coder.internal.const( ...
               getFontFilenameFaceindex_cg(coder.internal.const(font)));
end
% check that fontFileName is not empty
errIf0(isempty(fontFileName), 'vision:insertText:FontFileMissing');    

isScalarText = (numTexts==1);
%==========================================================================
function [anchorPoint,textColor,boxColor,boxOpacity, ...
    font,fontSize, shapeWidth, shapeHeight] = ...
    validateAndParseOptInputs_sim(inpClass,varargin)
% Validate and parse optional inputs

persistent parser
persistent oldInpClass

if isempty(parser)||isempty(oldInpClass)||(~strcmp(oldInpClass, inpClass))
  defaults = getDefaultParameters(inpClass);

  % Setup parser
  parser = inputParser;
  parser.CaseSensitive = false;
  parser.FunctionName  = mfilename;

  parser.addParameter('AnchorPoint', defaults.AnchorPoint);
  parser.addParameter('TextColor', defaults.TextColor);
  parser.addParameter('BoxColor', defaults.BoxColor);
  parser.addParameter('BoxOpacity', defaults.BoxOpacity, ...
                         @checkBoxOpacity);
  parser.addParameter('Font', defaults.Font);
  parser.addParameter('FontSize', defaults.FontSize, @checkFontSize);
  parser.addParameter('ShapeWidth',defaults.ShapeWidth,@checkShapeWidth);
  parser.addParameter('ShapeHeight',defaults.ShapeHeight,@checkShapeHeight);

    oldInpClass = inpClass;
end
%Parse input
parser.parse(varargin{:});

anchorPoint = checkAnchorPoint(parser.Results.AnchorPoint);
textColor   = checkColor(parser.Results.TextColor, 'TextColor');
boxColor    = checkColor(parser.Results.BoxColor, 'BoxColor');
boxOpacity  = double(parser.Results.BoxOpacity);
font        = checkFont(parser.Results.Font);% readjusted case in font name
fontSize    = int32(parser.Results.FontSize);
shapeWidth  = int32(parser.Results.ShapeWidth);
shapeHeight = int32(parser.Results.ShapeHeight);

%==========================================================================
function [anchorPoint,textColor,boxColor,boxOpacity, ...
    font,fontSize, shapeWidth, shapeHeight] = ...
    validateAndParseOptInputs_cg(inpClass,varargin)
% Validate and parse optional inputs

defaultsNoVal = getDefaultParametersNoVal();
defaults = getDefaultParameters(inpClass);
properties    = getEmlParserProperties();

optarg = eml_parse_parameter_inputs(defaultsNoVal,properties,varargin{:});

anchorPoint  = (eml_get_parameter_value(optarg.AnchorPoint, ...
            defaults.AnchorPoint, varargin{:}));
textColor  = (eml_get_parameter_value(optarg.TextColor, ...
    defaults.TextColor, varargin{:}));
boxColor  = (eml_get_parameter_value(optarg.BoxColor, ...
    defaults.BoxColor, varargin{:}));
boxOpacity  = (eml_get_parameter_value(optarg.BoxOpacity, ...
    defaults.BoxOpacity, varargin{:}));
font  = (eml_get_parameter_value(optarg.Font, ...
    defaults.Font, varargin{:}));
fontSize  = (eml_get_parameter_value(optarg.FontSize, ...
    defaults.FontSize, varargin{:}));
shapeWidth  = (eml_get_parameter_value(optarg.ShapeWidth, ...
    defaults.ShapeWidth, varargin{:}));
shapeHeight  = (eml_get_parameter_value(optarg.ShapeHeight, ...
    defaults.ShapeHeight, varargin{:}));

anchorPoint = coder.internal.const(checkAnchorPoint(anchorPoint));
textColor   = checkColor(textColor, 'TextColor');
boxColor    = checkColor(boxColor, 'BoxColor');
checkBoxOpacity(boxOpacity);
boxOpacity  = double(boxOpacity);

% FontSize must be a constant
if (nargin>1) && (optarg.FontSize ~= uint32(0))
    % FontSize is user-defined here
    eml_invariant(eml_is_const(fontSize), ...
        eml_message('vision:insertText:FontSizeNonConst'));
end

font        = coder.internal.const(checkFont(font));% readjusted case
checkFontSize(fontSize);
fontSize    = coder.internal.const(int32(fontSize));

% shapeWidth, shapeHeight for internal use only; skipping checks in codegen

%==========================================================================
function checkImage(I)
% Validate input image

validateattributes(I,{'uint8', 'uint16', 'int16', 'double', 'single'}, ...
    {'real','nonsparse'}, mfilename, 'I', 1)
% input image must be 2d or 3d (with 3 planes)
errIf0((ndims(I) > 3) || ((size(I,3) ~= 1) && (size(I,3) ~= 3)), ...
    'vision:dims:imageNot2DorRGB');

%==========================================================================
function checkText(text)
% Validate text

if isnumeric(text)
   validateattributes(text, {'numeric'}, ...
       {'real', 'nonsparse', 'nonnan', 'finite', 'nonempty', 'vector'}, ...
       mfilename, 'TEXT');  
else
    if ischar(text)
        validateattributes(text,{'char'},{},mfilename, 'TEXT');  
        
        textCell = {text};
    else
        validateattributes(text,{'cell'}, {'nonempty', 'vector'}, ...
                                                    mfilename, 'TEXT');
        for i=1:length(text)
            errIf0(~ischar(text{i}), 'vision:insertText:textCellNonChar');
        end

        textCell = text;
    end
    
    % Following escape characters are not supported
    % \b     Backspace
    % \f     Form feed
    % \r     Carriage return
    % \t     Horizontal tab 
    
    % \n     line termination : supported by insertText, 
    %                           but not by insertObjectAnnotation 
    if isSimMode()
        throwErrorForEscapeChar_sim(textCell, {'\b','\f','\r','\t'});    
    else
        throwErrorForEscapeChar_cg(textCell);    
    end
end

%==========================================================================
function throwErrorForEscapeChar_sim(textCell, escapeCharsCell)

for ii=1:length(escapeCharsCell)
    thisCell = escapeCharsCell{ii};
    escapeChar    = sprintf(thisCell);
    escapeCharIdx = strfind(textCell, escapeChar);
    hasEscapeChar = ~isempty([escapeCharIdx{1:end}]);
    errIf1(hasEscapeChar, 'vision:insertText:unsupportedEscapeChar', ...
           thisCell);
end

%==========================================================================
function throwErrorForEscapeChar_cg(textCell)

% This function is used only if input text is Non-numeric

for i=1:length(textCell)
    txtTmp = uint16(textCell{i});

    % Escape characters: {'\b','\f','\r','\t'}
    escapeCharU16_b    = uint16(8); % uint16(sprintf('\b'))
    hasEscapeChar_b = ~isempty(find(txtTmp == escapeCharU16_b, 1));
    errIf1(hasEscapeChar_b,'vision:insertText:unsupportedEscapeChar','\b');  

    escapeCharU16_f    = uint16(12); % uint16(sprintf('\f'))
    hasEscapeChar_f = ~isempty(find(txtTmp == escapeCharU16_f, 1));
    errIf1(hasEscapeChar_f,'vision:insertText:unsupportedEscapeChar','\f'); 

    escapeCharU16_r    = uint16(13); % uint16(sprintf('\r'))
    hasEscapeChar_r = ~isempty(find(txtTmp == escapeCharU16_r, 1));
    errIf1(hasEscapeChar_r,'vision:insertText:unsupportedEscapeChar','\r'); 

    escapeCharU16_t    = uint16(9); % uint16(sprintf('\t'))
    hasEscapeChar_t = ~isempty(find(txtTmp == escapeCharU16_t, 1));
    errIf1(hasEscapeChar_t,'vision:insertText:unsupportedEscapeChar','\t'); 
end
%==========================================================================
function anchorPointOut = checkAnchorPoint(anchorPoint)
% Validate AnchorPoint
                     
anchorPointOut = coder.internal.const(validatestring(anchorPoint, ...
              {'LeftTop', 'LeftCenter', 'LeftBottom', ... 
               'RightTop', 'RightCenter', 'RightBottom', ...
               'CenterTop', 'CenterCenter', 'Center', 'CenterBottom'}, ...
               mfilename,'AnchorPoint'));
                               
%==========================================================================
function crossCheckInputs(position, numTexts, textColor, boxColor)
% Cross validate inputs

numRowsPositions = size(position, 1); 
numBoxColor      = getNumColors(boxColor);
numTextColors    = getNumColors(textColor);

% cross check text and position (rows)
errIf0((numTexts ~=1) && (numTexts ~= numRowsPositions), ...
       'vision:insertText:invalidNumTexts');

% cross check color and position (rows). Empty color is caught here
errIf0((numBoxColor ~= 1) && (numRowsPositions ~= numBoxColor), ...
    'vision:insertText:invalidNumPosNumBoxColor');

% cross check text color and position (rows). Empty color is caught here
errIf0((numTextColors ~= 1) && (numRowsPositions ~= numTextColors), ...
    'vision:insertText:invalidNumPosNumTextColor');

%==========================================================================
function colorOut = getColorMatrix(inpClass, numPos, color)

colorRGB = colorRGBValue(color, inpClass);
if (size(colorRGB, 1)==1)
    colorOut = repmat(colorRGB, [numPos 1]);
else
    colorOut = colorRGB;
end

%==========================================================================
function shapeDimOut = getShapeDimMatrix(shapeDim, numPos)

if length(shapeDim)==1
    shapeDimOut = repmat(shapeDim, [numPos 1]);
else
    shapeDimOut = shapeDim;
end

%==========================================================================
function numColors = getNumColors(color)

% Get number of colors
numColors = 1;
if isnumeric(color)
    numColors = size(color,1);
elseif iscell(color) % if color='red', it is converted to cell earlier
    numColors = length(color);
end

%==========================================================================
function flag = isDefaultFont(font)
% called only in sim mode
flag = false;
if strcmp(getDefaultFont_sim(), font)
    flag = true;
end
    

%==========================================================================
function defaultFont = getDefaultFont_sim()

persistent origDefFont

if isempty(origDefFont)
    origDefFont = vision.internal.getDefaultFont();
end
defaultFont = origDefFont;

%==========================================================================
function defaultFont = getDefaultFont_cg()

coder.extrinsic('vision.internal.getDefaultFont');
defaultFont = coder.internal.const(vision.internal.getDefaultFont());

%==========================================================================
function defaults = getDefaultParameters(inpClass)

% Get default values for optional parameters
% default color 'black', default text color 'yellow'

if isSimMode()
    origDefFont = getDefaultFont_sim();
else
    origDefFont = getDefaultFont_cg();
end

black = [0 0 0]; 
switch inpClass
   case {'double', 'single'}
       yellow = [1 1 0];  
   case 'uint8'
       yellow = [255 255 0];  
   case 'uint16'
       yellow = [65535  65535  0];          
   case 'int16'
       yellow = [32767  32767 -32768];
       black  = [-32768  -32768  -32768];         
end
    
defFont = coder.internal.const(origDefFont);
defaults = struct(...
    'AnchorPoint', 'LeftTop', ...
    'TextColor',  black, ...     
    'BoxColor', yellow, ... 
    'BoxOpacity', 0.6,...
    'Font', defFont, ...
    'FontSize', 12, ...
    'ShapeWidth', 0, ...
    'ShapeHeight', 0);

%==========================================================================
function defaults = getDefaultParametersNoVal()

defaults = struct(...
    'AnchorPoint', uint32(0), ...
    'TextColor',  uint32(0), ...     
    'BoxColor', uint32(0), ... 
    'BoxOpacity', uint32(0),...
    'Font', uint32(0), ...
    'FontSize', uint32(0), ...
    'ShapeWidth', uint32(0), ...
    'ShapeHeight', uint32(0));

%==========================================================================
function properties = getEmlParserProperties()

properties = struct( ...
    'CaseSensitivity', false, ...
    'StructExpand',    true, ...
    'PartialMatching', false);

%==========================================================================
function colorOut = checkColor(color, paramName) 
% Validate 'BoxColor' or 'TextColor'

% Validate color
if isnumeric(color)
   % must have 6 columns
   validateattributes(color, ...
       {'uint8','uint16','int16','double','single'},...
       {'real','nonsparse','nonnan', 'finite', '2d', 'size', [NaN 3]}, ...
       mfilename, paramName);
   colorOut = color;
else
   if ~isSimMode()
       % codegen does not support cell array
       errIf0(~isnumeric(color), 'vision:insertShape:colorNotNumeric');
       colorOut = color;
   else     
       if ischar(color)
           colorCell = {color};
       else
           validateattributes(color, {'cell'}, {}, mfilename, 'BoxColor');
           colorCell = color;
       end
       supportedColorStr = {'blue','green','red','cyan','magenta', ...
                            'yellow','black','white'};
       numCells = length(colorCell);
       colorOut = cell(1, numCells);
       for ii=1:numCells
           colorOut{ii} =  validatestring(colorCell{ii}, ...
                                  supportedColorStr, mfilename, paramName);
       end
    end
end

%==========================================================================
function fontOut = checkFont(font)
% Validate 'Font'. Do a case insensitive match
coder.extrinsic('vision.internal.getFontNamesInCell');
fontOut = coder.internal.const(validatestring(coder.internal.const(font), ...
    coder.internal.const(vision.internal.getFontNamesInCell()), ...
    mfilename,'Font'));

%==========================================================================
function tf = checkBoxOpacity(opacity)
% Validate 'BoxOpacity'

validateattributes(opacity, {'numeric'}, {'nonempty', 'nonnan', ...
    'finite', 'nonsparse', 'real', 'scalar', '>=', 0, '<=', 1}, ...
    mfilename, 'BoxOpacity');
tf = true;

%==========================================================================
function tf = checkFontSize(FontSize)
% Validate 'FontSize'
% Maximum font size in MS Word is 1638
validateattributes(FontSize, {'numeric'}, ...
    {'nonempty', 'integer', 'nonsparse', 'scalar', '>', 0, '<=', 200}, ...
    mfilename, 'FontSize');
tf = true;

%==========================================================================
function tf = checkShapeWidth(ShapeWidth)
% Validate 'ShapeWidth'
validateattributes(ShapeWidth, {'numeric'}, ...
    {'nonempty', 'integer', 'nonsparse', '>=', 0}, ...
    mfilename, 'ShapeWidth');
tf = true;

%==========================================================================
function tf = checkShapeHeight(ShapeHeight)
% Validate 'ShapeHeight'
validateattributes(ShapeHeight, {'numeric'}, ...
    {'nonempty', 'integer', 'nonsparse', '>=', 0}, ...
    mfilename, 'ShapeHeight');
tf = true;

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
        textColorCell = inColor;
    else
        textColorCell = {inColor};
    end

   numColors = length(textColorCell);
   outColor = zeros(numColors, 3, inpClass);

   for ii=1:numColors
    supportedColorStr = {'blue','green','red','cyan','magenta','yellow',...
                         'black','white'};  
    % http://www.mathworks.com/help/techdoc/ref/colorspec.html
    colorValuesFloat = [0 0 1;0 1 0;1 0 0;0 1 1;1 0 1;1 1 0;0 0 0;1 1 1];                    
    idx = strcmp(textColorCell{ii}, supportedColorStr);
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
function [numTexts, textOut] = getTexts(textIn)

if isnumeric(textIn)
   numTexts = length(textIn);
   textOut = textIn; % scalar or vector
else
   if ischar(textIn)
       numTexts = 1;
       textOut = {textIn};
   else % must be cell
       numTexts = length(textIn);
       textOut = textIn;
   end
end

%==========================================================================
function [glyphStruct, fontStruct, maxBitmapSize] = ...
      splitInfoStruct(infoStruct)

glyphStruct.glyphBitmapArray     = infoStruct.glyphBitmapArray; 
glyphStruct.glyphIdxFromCharcode = infoStruct.glyphIdxFromCharcode;   
glyphStruct.glyphBitmapStartIdx  = infoStruct.glyphBitmapStartIdx; 
glyphStruct.glyphWidths          = infoStruct.glyphWidths;          
glyphStruct.glyphHeights         = infoStruct.glyphHeights;        
glyphStruct.glyphXAdvances       = infoStruct.glyphXAdvances;       
glyphStruct.glyphLeftBearings    = infoStruct.glyphLeftBearings; 
glyphStruct.glyphTopBearings     = infoStruct.glyphTopBearings; 
%
fontStruct.fontAscend            = infoStruct.fontAscend; 
fontStruct.fontDescend           = infoStruct.fontDescend; 
fontStruct.fontLinespace         = infoStruct.fontLinespace;
maxBitmapSize                    = infoStruct.maxBitmapSize;

%==========================================================================
function infoStruct = populateInfoStruct_sim(fontFileName,...
                                             faceIndex,fontSize)

    [glyphBitmapArray, ...
    glyphIdxFromCharcode, ...  
    glyphBitmapStartIdx, ...
    glyphWidths, ...         
    glyphHeights, ...       
    glyphXAdvances, ...      
    glyphLeftBearings, ...
    glyphTopBearings, ...
    fontAscend, ...
    fontDescend, ...
    fontLinespace, ...
    maxBitmapSize]=visionPopulateGlyphBuffer(fontFileName,faceIndex, ...
                                             fontSize,false); 

infoStruct.glyphBitmapArray     = glyphBitmapArray; 
infoStruct.glyphIdxFromCharcode = glyphIdxFromCharcode;   
infoStruct.glyphBitmapStartIdx  = glyphBitmapStartIdx; 
infoStruct.glyphWidths          = glyphWidths;          
infoStruct.glyphHeights         = glyphHeights;        
infoStruct.glyphXAdvances       = glyphXAdvances;       
infoStruct.glyphLeftBearings    = glyphLeftBearings; 
infoStruct.glyphTopBearings     = glyphTopBearings; 
    %
infoStruct.fontAscend            = fontAscend; 
infoStruct.fontDescend           = fontDescend; 
infoStruct.fontLinespace         = fontLinespace;

infoStruct.maxBitmapSize         = maxBitmapSize;
   
%==========================================================================
function [glyphStruct, fontStruct, maxBitmapSize] = ...
    populateGlyphBuffer_sim(font,fontFileName, faceIndex, fontSize)

persistent fontHashTable
persistent infoStructArray

if isempty(fontHashTable)
    fontHashTable = containers.Map('KeyType', 'char', 'ValueType', 'uint16');
end
if isempty(infoStructArray)
    infoStructArray = [];
end

% create unique key from font name and font size
fontLower = lower(font);
thisKey = [fontLower num2str(fontSize)];

if isKey(fontHashTable, thisKey)
    % retrieve glyph and font info from table
    thisValue = fontHashTable(thisKey);
    infoStruct = infoStructArray(thisValue);
else
    try %#ok<EMTC>
     % populate infoStruct and append it to infoStructArray only at success
     infoStruct = populateInfoStruct_sim(fontFileName,faceIndex, fontSize);
    catch ME
     throw(ME);
    end
    
    % add the new key and the corresponding value.
    % the values are [1,2,3...]
    thisValue = uint16(fontHashTable.Count+1);
    fontHashTable(thisKey) = thisValue;

    infoStructArray = [infoStructArray infoStruct];    
    % here infoStructArray(thisValue) is the infoStruct corresponding to
    % thisKey
end

[glyphStruct, fontStruct, maxBitmapSize] = splitInfoStruct(infoStruct);

%==========================================================================
function [fontFileName, faceIndex] = getFontFilenameFaceindex_cg(font)

coder.extrinsic('listTrueTypeFonts');
oldFontFNameFIdx = coder.internal.const( ...
               listTrueTypeFonts(coder.internal.const(font)));
fontFileName = coder.internal.const(oldFontFNameFIdx.fileName);
faceIndex = coder.internal.const(oldFontFNameFIdx.faceIndex);

%==========================================================================
function [fontFileName, faceIndex] = getFontFilenameFaceindex_sim(font)

persistent oldFont
persistent oldFontFileName
persistent oldFaceIndex

if isempty(oldFontFileName) || ~strcmp(oldFont, font)
    oldFontFNameFIdx = coder.internal.const( ...
                   listTrueTypeFonts(coder.internal.const(font)));
    oldFontFileName = oldFontFNameFIdx.fileName;
    oldFaceIndex = oldFontFNameFIdx.faceIndex;
end
oldFont = font;
fontFileName = coder.internal.const(oldFontFileName);
faceIndex = coder.internal.const(oldFaceIndex);

%==========================================================================
function [glyphStruct, fontStruct, maxBitmapSize] = ...
    populateGlyphBuffer_cg(fontFileName, faceIndex, fontSize)

coder.extrinsic('visionPopulateGlyphBuffer');

% call built-in function
[glyphBitmapArray, ...
glyphIdxFromCharcode, ...  
glyphBitmapStartIdx, ...
glyphWidths, ...         
glyphHeights, ...       
glyphXAdvances, ...      
glyphLeftBearings, ...
glyphTopBearings, ...
fontAscend, ...
fontDescend, ...
fontLinespace, ...
maxBitmapSize] = coder.internal.const(...
     visionPopulateGlyphBuffer(fontFileName, faceIndex, fontSize, true)); 

glyphStruct.glyphBitmapArray     = glyphBitmapArray; 
glyphStruct.glyphIdxFromCharcode = glyphIdxFromCharcode;   
glyphStruct.glyphBitmapStartIdx  = glyphBitmapStartIdx; 
glyphStruct.glyphWidths          = glyphWidths;          
glyphStruct.glyphHeights         = glyphHeights;        
glyphStruct.glyphXAdvances       = glyphXAdvances;       
glyphStruct.glyphLeftBearings    = glyphLeftBearings; 
glyphStruct.glyphTopBearings     = glyphTopBearings; 
%
fontStruct.fontAscend            = fontAscend; 
fontStruct.fontDescend           = fontDescend; 
fontStruct.fontLinespace         = fontLinespace;

%==========================================================================
function [tbWidth, tbHeight, spaceCharWidth] = ...
    getTextboxWidthHeight(ucTextU16, glyphIdxFromCharcode, ...
                          glyphXAdvances, fontStruct, shapeWidth)

% New line character does not have any width; It just contributes to height
% So, for width computation, we don't consider NewLineCharacter.
%  That means: for five new line character and no text: 
%   text box height is non-zero, but width is zero, so no text box is drawn
%
% So, for height computation, we DO consider NewLineCharacter. That means:
% for each new line character, we increase the height

fontHeightWLinegap  = fontStruct.fontLinespace;
fontHeightWOLinegap = fontStruct.fontAscend - fontStruct.fontDescend;
%fontLinegap = fontHeightWLinegap - fontHeightWOLinegap;

ucNewlineCarcode = uint16(10);
idxNewlineChar = find(ucTextU16==ucNewlineCarcode);

numLines = length(idxNewlineChar)+1;
tbHeight = int32(fontHeightWOLinegap + fontHeightWLinegap*(numLines-1));

b1 = 1; % for converting 0-based to 1-based
spaceCharWidth = getSpaceCharWidth(glyphIdxFromCharcode, ...
    glyphXAdvances, fontHeightWOLinegap);
if isempty(idxNewlineChar)
   thisCharcodes_1b = ucTextU16+b1;
   thisGlyphIdxs = glyphIdxFromCharcode(thisCharcodes_1b);
   thisGlyphIdxs_1b = thisGlyphIdxs + b1;    
   
   tbWidth = int32(sum(glyphXAdvances(thisGlyphIdxs_1b)));
   % glyph index 0 means no glyph found 
   numMissingGlyph =sum(uint32(glyphIdxFromCharcode(thisCharcodes_1b))==0); 
   tbWidth = int32(tbWidth + int32(numMissingGlyph*spaceCharWidth));
else
   %first segment
   firstSegment = ucTextU16(1:(idxNewlineChar(1)-1));
   thisCharcodes_1b = firstSegment+b1;
   thisGlyphIdxs = glyphIdxFromCharcode(thisCharcodes_1b);
   thisGlyphIdxs_1b = thisGlyphIdxs + b1;     
   lenFirstSegment = sum(glyphXAdvances(thisGlyphIdxs_1b));
   
   % for character code with no glyph, we replace that by space; account
   % for space width
   numMissingGlyph=sum(uint32(glyphIdxFromCharcode(thisCharcodes_1b))==0);
   lenFirstSegment = lenFirstSegment + numMissingGlyph*spaceCharWidth;
   maxLen = int32(0);
   for i=2:(length(idxNewlineChar)-1)
     startIdx = idxNewlineChar(i)+1;
     endIdx = idxNewlineChar(i+1)-1;
     thisSegment = ucTextU16(startIdx:endIdx);
     thisCharcodes_1b = thisSegment+b1;
     thisGlyphIdxs = glyphIdxFromCharcode(thisCharcodes_1b);
     thisGlyphIdxs_1b = thisGlyphIdxs + b1;     
     lenThisSegment = sum(glyphXAdvances(thisGlyphIdxs_1b));
     numMissingGlyph=sum(uint32(glyphIdxFromCharcode(thisCharcodes_1b))==0);
     lenThisSegment = lenThisSegment + numMissingGlyph*spaceCharWidth;
     
     if lenThisSegment > maxLen
         maxLen(:) = lenThisSegment;
     end
   end
   endSegment = ucTextU16((idxNewlineChar(end)+1):end);
    
   thisCharcodes_1b = endSegment+b1;
   thisGlyphIdxs = glyphIdxFromCharcode(thisCharcodes_1b);
   thisGlyphIdxs_1b = thisGlyphIdxs + b1;     
   lenEndSegment = sum(glyphXAdvances(thisGlyphIdxs_1b));
   numMissingGlyph=sum(uint32(glyphIdxFromCharcode(thisCharcodes_1b))==0);
   lenEndSegment = lenEndSegment + numMissingGlyph*spaceCharWidth;
   
   maxLen = max([lenFirstSegment maxLen lenEndSegment]);    
   tbWidth = int32(maxLen);
end

% Adjust tbWidth if smaller than shapeWidth for insertObjectAnnotation
tbWidth = max(tbWidth, shapeWidth);

%==========================================================================
%  overlap condition: 
function hasOverlap = shapeAndImageHasOverlaps(bbox_x1, bbox_y1, ...
    shapeWidth, shapeHeight, imageWidth, imageHeight)

% returns true even if there is at least 1 pixel overlap
bbox_x2 = bbox_x1 + shapeWidth-1;
bbox_y2 = bbox_y1 + shapeHeight-1;

hasOverlap = (bbox_x1 <= imageWidth && bbox_x2 >= 1 && ...
              bbox_y1 <= imageHeight && bbox_y2 >= 1);

%==========================================================================
function [tbTopLeftX, tbTopLeftY] = getTextboxTopLeftPosition( ...
    tbLocationXY, tbWidth, tbHeight, anchorPoint, shapeWidth, ...
    shapeHeight, imageWidth, imageHeight)

tbLocationX = tbLocationXY(1);
tbLocationY = tbLocationXY(2);

switch lower(anchorPoint)
    case 'lefttop'
        tbTopLeftY = tbLocationY;
        tbTopLeftX = tbLocationX;
    case 'leftcenter'
        tbTopLeftY = tbLocationY-int32(tbHeight/2);
        tbTopLeftX = tbLocationX;     
    case 'leftbottom'
        tbTopLeftY = tbLocationY-int32(tbHeight)+1;
        tbTopLeftX = tbLocationX;   
        if (shapeWidth>0) && (shapeHeight>0)
            % make sure at least 1 pixel in bounding box is inside image
            hasOverlap = shapeAndImageHasOverlaps(tbTopLeftX, ...
                tbTopLeftY+tbHeight, shapeWidth, shapeHeight, ...
                imageWidth, imageHeight);
            
            if hasOverlap
                % top border
                if tbTopLeftY<1 % row 
                    % top of textBoxBorder outside image top border
                    if ((tbTopLeftY + tbHeight + shapeHeight)>=1) 
                        % bounding boxes bottom border is inside image's
                        % top border
                        tbTopLeftY = tbLocationY + shapeHeight +1; % row
                    end
                end
                
                % right border
                bboxLeftBorder = tbTopLeftX;
                % in next line we will readjust textBoxLeftBorder. So we
                % need to save the original bboxLeftBorder in above line
                textBoxRightBorder = tbTopLeftX + tbWidth; % col
                adjBorder = textBoxRightBorder - imageWidth;
                if adjBorder > 0 % col 
                    % right of textBoxBorder outside image right border
                    if tbTopLeftX <= imageWidth % col 
                        % bounding boxes left border is inside image's
                        % right border
                        tbTopLeftX = tbTopLeftX - adjBorder + 1; % col
                    % else
                        %	tbTopLeftY  = imageW + 100; % put textbox's
                        %	top border far away so that it is not drawn
                    end
                end
                % left border
                if tbTopLeftX < 1 % col 
                    % left of textBoxBorder outside image left border
                    if bboxLeftBorder + shapeWidth >= 1 % col 
                        % bounding boxes right border is inside image's
                        % left border
                        tbTopLeftX = int32(1); % col
                    % else
                        %	tbTopLeftY  = -(textBoxWidth + 100);%put
                        %	textbox's left border far away so that it is
                        %	not drawn
                    end
                end
            else
               tbTopLeftY = int32(-32767);%far away
               tbTopLeftX = int32(-32767);%far away
            end
        end
    case 'righttop'
        tbTopLeftY = tbLocationY;
        tbTopLeftX = tbLocationX-int32(tbWidth)+1;
    case 'rightcenter'
        tbTopLeftY = tbLocationY-int32(tbHeight/2);
        tbTopLeftX = tbLocationX-int32(tbWidth)+1;     
    case 'rightbottom'
        tbTopLeftY = tbLocationY-int32(tbHeight)+1;
        tbTopLeftX = tbLocationX-int32(tbWidth)+1; 
    case 'centertop'
        tbTopLeftY = tbLocationY;
        tbTopLeftX = tbLocationX-int32(tbWidth/2);
    case 'center'
        tbTopLeftY = tbLocationY-int32(tbHeight/2);
        tbTopLeftX = tbLocationX-int32(tbWidth/2);     
    case 'centerbottom'
        tbTopLeftY = tbLocationY-int32(tbHeight)+1;
        tbTopLeftX = tbLocationX-int32(tbWidth/2);    
end

%==========================================================================
function RGB = insertTextBoxCore(imgIn, tbTopLeftX, tbTopLeftY, ...
                               tbWidth, tbHeight, boxColor, boxOpacity)

RGB = imgIn;
imSize = int32(size(RGB));
numRowsIm = imSize(1);
numColsIm = imSize(2);
numPLanes = imSize(3);

oneI32 = int32(1);

startR = tbTopLeftY;
endR   = tbTopLeftY+int32(tbHeight)-oneI32;
startC = tbTopLeftX;
endC   = tbTopLeftX+int32(tbWidth)-oneI32;

noOverlap = (startR>numRowsIm) || (endR<oneI32) || ...
            (startC>numColsIm) || (endC<oneI32);
            
if (~noOverlap)
    if (startR<oneI32)
        startR = oneI32;
    end
    if (endR>numRowsIm)
        endR = numRowsIm;
    end  
    if (startC<oneI32)
        startC = oneI32;
    end
    if (endC>numColsIm)
        endC = numColsIm;
    end     
    if (boxOpacity>=1) % boxOpacity>1 is caught in arg check
        for i=1:numPLanes
            RGB(startR:endR, startC:endC, i) = boxColor(i);
        end
    else
        [zeroOrHalf, cClassName] = getValueAndClass(RGB);
        for i=1:numPLanes
            for c=startC:endC
                for r=startR:endR
                    tmp1 = double(boxOpacity*double(boxColor(i))) + zeroOrHalf;
                    tmp2 = (1-boxOpacity)*double(RGB(r,c, i)) + zeroOrHalf;
                    tmp11 = cCast(cClassName, tmp1);
                    tmp22 = cCast(cClassName, tmp2);
                    RGB(r,c, i) = tmp11 + tmp22;
                end
            end
        end
    end
end

%==========================================================================
function [zeroOrHalf, cClassName] = getValueAndClass(RGB)

if isfloat(RGB)
   zeroOrHalf = 0;
else
   zeroOrHalf = 0.5;
end

mClassName = class(RGB);
if isa(RGB, 'double')
    cClassName = 'real_T';
elseif isa(RGB, 'single')
    cClassName = 'real32_T';  
else
    cClassName = [mClassName '_T'];
end

function outVal = cCast(outClass, inVal)
outVal = coder.nullcopy(zeros(1,1,outClass));
outVal = coder.ceval(['('   outClass  ')'], inVal);

%==========================================================================
function [RGB, textLocationXY, spaceCharWidth] = insertTextBox(RGB, ...
    position, ucTextU16, ...
    anchorPoint, boxColor, boxOpacity, ...
    glyphStruct, fontStruct, ...
    shapeWidth, shapeHeight)

% Step-1: get compact textbox width and height
% position is an M-by-2 matrix of [x y] coordinates of the upper-left
% corner of the text bounding box.
[tbWidth, tbHeight, spaceCharWidth] = getTextboxWidthHeight(ucTextU16, ...
   glyphStruct.glyphIdxFromCharcode,glyphStruct.glyphXAdvances, ...
   fontStruct, shapeWidth);

% Step-2: add margin to textbox width and height
MARGIN_LeftOrRight = spaceCharWidth; % used 3 before
MARGIN_TopOrBottom = spaceCharWidth; % used 3 before
% only add left/right margin if the text extends past the shapeWidth
if tbWidth>shapeWidth
    tbWidth  = tbWidth + 2*MARGIN_LeftOrRight;
end
tbHeight = tbHeight + 2*MARGIN_TopOrBottom;

% Step-3: Consider anchor point and get text box top-left corner position
tbLocationXY = position;
imageWidth  = size(RGB,2);
imageHeight = size(RGB,1);
[tbTopLeftX, tbTopLeftY] = getTextboxTopLeftPosition(tbLocationXY, ...
    tbWidth, tbHeight, anchorPoint, shapeWidth, shapeHeight, ...
    imageWidth, imageHeight);

% % Step-3a: Shift left appropriate amount, if needed. If tbTopLeftX +
% % tbWidth is larger than RGB dimensions, shift tbTopLeftX
% if tbTopLeftX + tbWidth > size(RGB, 2)
%     % Calculate excess width beyond image width
%     excessWidth = tbTopLeftX + tbWidth - size(RGB, 2);
%     if excessWidth > tbTopLeftX
%         tbTopLeftX = 0;
%     else
%         tbTopLeftX = tbTopLeftX - excessWidth;
%     end
% end

% Step-4: get outputs
RGB = insertTextBoxCore(RGB, tbTopLeftX, tbTopLeftY, ...
    tbWidth, tbHeight, boxColor, boxOpacity);

textLocationXY.x = tbTopLeftX + int32(MARGIN_LeftOrRight);
textLocationXY.y = tbTopLeftY + int32(MARGIN_TopOrBottom);

%==========================================================================
function imgOut = insertGlyphs(imgIn, ucTextU16, ...
                    textLocationXY, textColor, ...
                    glyphStruct, fontStruct, spaceCharWidth)

imSize = int32(size(imgIn));
imgOut = imgIn;
numRowsIm = imSize(1);
numColsIm = imSize(2);
oneI32 = int32(1);

numChars = length(ucTextU16); 
b1 = 1; % to convert to 1 based indexing
fontHeightWLinegap = fontStruct.fontLinespace;
    
penX = int32(textLocationXY.x);
% go to reference baseline (near the middle of the glyph)
penY = int32(textLocationXY.y) + fontStruct.fontAscend; 

isNewLineChar = (ucTextU16 == uint16(10));
for i=1:numChars
    %see logic in mdlOutputs of sviptextrender.cpp
    if isNewLineChar(i)
        % go to next line
        penY = penY + fontHeightWLinegap;
        % reset x position to the beginning on a line
        penX = textLocationXY.x;
    else
        thisCharcode = ucTextU16(i);
        thisCharcode_1b = thisCharcode+b1;
        thisGlyphIdx = glyphStruct.glyphIdxFromCharcode(thisCharcode_1b);
        thisGlyphIdx_1b = thisGlyphIdx + b1;
        glyphExists = (thisGlyphIdx ~= 0);
        if ~glyphExists
            penX = penX + int32(spaceCharWidth);
        else
            thisGlyphW = glyphStruct.glyphWidths(thisGlyphIdx_1b);
            thisGlyphH = glyphStruct.glyphHeights(thisGlyphIdx_1b);
            
            xx=penX+int32(glyphStruct.glyphLeftBearings(thisGlyphIdx_1b));
            yy=penY-int32(glyphStruct.glyphTopBearings(thisGlyphIdx_1b));
            startR_im = yy;
            endR_im = yy+int32(thisGlyphH)- oneI32;
            startC_im = xx;
            endC_im = xx+int32(thisGlyphW)- oneI32;
            % take care of clipping for out of bound image
            noOverlap = (startR_im>numRowsIm) || (endR_im<oneI32) || ...
                        (startC_im>numColsIm) || (endC_im<oneI32);
            
            if (~noOverlap) % if no overlap, skip this glyph
                startR_gl = oneI32;
                startC_gl = oneI32;
                endR_gl = int32(thisGlyphH);
                endC_gl = int32(thisGlyphW);
                if (startR_im<1)
                    startR_gl = -startR_im+int32(2);
                    startR_im = oneI32;
                end
                if (endR_im>numRowsIm)
                    endR_gl = int32(thisGlyphH) - (endR_im - numRowsIm);
                    endR_im = numRowsIm;
                end
                if (startC_im<1)
                    startC_gl = -startC_im+int32(2);
                    startC_im = oneI32;
                end
                if (endC_im>numColsIm)
                    endC_gl = int32(thisGlyphW) - (endC_im - numColsIm);
                    endC_im = numColsIm;
                end
                
                imgIdx.startR_im = startR_im;
                imgIdx.startC_im = startC_im;
                imgIdx.endR_im = endR_im;
                imgIdx.endC_im = endC_im;
                
                glIdx.startR_gl = startR_gl;
                glIdx.startC_gl = startC_gl;
                glIdx.endR_gl = endR_gl;
                glIdx.endC_gl = endC_gl;
                
                bitmapStartIdx_1b = ...
                    glyphStruct.glyphBitmapStartIdx(thisGlyphIdx_1b) + b1;
                bitmapEndIdx_1b =  bitmapStartIdx_1b + ...
                                 uint32(thisGlyphW*thisGlyphH) - uint32(1);
                thisGlyphBitmap = glyphStruct.glyphBitmapArray(...
                                        bitmapStartIdx_1b:bitmapEndIdx_1b);
                thisGlyphBitmap = ...
                    reshape(thisGlyphBitmap,[thisGlyphW thisGlyphH]);
                
                thisGlyphBitmap = thisGlyphBitmap';
                % antialiasing
                if isfloat(imgOut)
                    % text color is double/single([0 1]) range;
                    % no need to convert it
                    imgOut = doGlyph_float(imgOut, thisGlyphBitmap, ...
                        imgIdx, glIdx, textColor);
                elseif isa(imgOut,'uint8')
                    % text color is uint8([0 255]) range; 
                    % no need to convert it
                    imgOut = doGlyph_uint8(imgOut, thisGlyphBitmap, ...
                        imgIdx, glIdx, textColor);
                elseif isa(imgOut,'uint16')
                    % text color is uint16([0 65535]) range; 
                    % no need to convert it
                    imgOut = doGlyph_uint16(imgOut, thisGlyphBitmap, ...
                        imgIdx, glIdx, textColor);                    
                elseif isa(imgOut,'int16')
                    imgOut = doGlyph_int16(imgOut, thisGlyphBitmap, ...
                        imgIdx, glIdx, textColor);
                end
            end
            % update X position for next character
            penX=penX+int32(glyphStruct.glyphXAdvances(thisGlyphIdx_1b));
        end
    end
end

%==========================================================================
function spaceCharWidth = getSpaceCharWidth(glyphIdxFromCharcode, ...
    glyphXAdvances, fontHeightWOLinegap)

% For space char, width is zero, but XAdvances is non-zero.
% Note that for missing glyph, glyph index is zero (do not use zero glyph
% width as an indicator of missing glyph)

b1 = 1; % for converting 0-based to 1-based
spaceGlyphIdx = glyphIdxFromCharcode(32+b1);
if (spaceGlyphIdx==0)
    spaceCharWidth = int32(fontHeightWOLinegap/4);
else
    spaceCharWidth = int32(glyphXAdvances(spaceGlyphIdx+b1));
end

%==========================================================================
function flag = isSimMode()

flag = isempty(coder.target);

%==========================================================================
function errIf0(condition, msgID)

coder.internal.errorIf(condition, msgID);

%==========================================================================
function errIf1(condition, msgID, strArg)

coder.internal.errorIf(condition, msgID, strArg);

%==========================================================================
function str = cvstNum2Str(num)
if isSimMode
    str = num2str(num);
else
    % sprintf works on regular char (does not work on wide char)
    str1 = repmat(char(0),1,30);
    numDbl = double(num);
    coder.inline('always');
    coder.cinclude('<stdio.h>');
    coder.ceval('sprintf', coder.ref(str1), cstring('%0.5g'), numDbl);
    str = mstring(str1);
end

%==========================================================================
% Put a C termination character '\0' at the end of MATLAB string
function y = cstring(x)
    y = [x char(0)];

%==========================================================================
% Remove trailing null termination characters '\0' at the end of C string 
function  mStr = mstring(cStr)
endIdx = 0;
for i=1:length(cStr)
    if (double(cStr(i)) == double(char(0)))
        endIdx = i-1;
        break;
    end
end
mStr = cStr(1:endIdx);
    
%==========================================================================
function imgOut = doGlyph_float(imgIn, thisGlyphBitmap, ...
                                imgIdx, glIdx, textColor)
                            
imgOut = imgIn;
numPLanes = size(imgIn, 3);

startR_im = imgIdx.startR_im;
startC_im = imgIdx.startC_im;
endR_im = imgIdx.endR_im;
endC_im = imgIdx.endC_im;

startR_gl = glIdx.startR_gl;
startC_gl = glIdx.startC_gl;
endR_gl = glIdx.endR_gl;
endC_gl = glIdx.endC_gl;
         
thisGlyphCut_u8 = thisGlyphBitmap(startR_gl:endR_gl, startC_gl:endC_gl);
thisGlyphCut_float = double(thisGlyphCut_u8)/255;

for idx=1:numPLanes
   cg = 1;
   for c = startC_im:endC_im
      rg = 1;
      for r = startR_im:endR_im
          glyphVal = thisGlyphCut_float(rg,cg);
          if (glyphVal == 1)
             imgOut(r,c,idx) = textColor(idx);
          elseif (glyphVal ~= 0)
             imgOut(r,c,idx)=(textColor(idx)-imgOut(r,c,idx))*glyphVal ...
                    + imgOut(r,c,idx);                    
          end
          rg = rg+1;
      end
      cg = cg+1;
    end
end

%==========================================================================
function imgOut = doGlyph_uint8(imgIn, thisGlyphBitmap, ...
                                         imgIdx, glIdx, textColor)
    
MAX_VAL_DT = uint16(255);
imgOut = imgIn;
numPLanes = size(imgIn, 3);

startR_im = imgIdx.startR_im;
startC_im = imgIdx.startC_im;
endR_im = imgIdx.endR_im;
endC_im = imgIdx.endC_im;

startR_gl = glIdx.startR_gl;
startC_gl = glIdx.startC_gl;
endR_gl = glIdx.endR_gl;
endC_gl = glIdx.endC_gl;

WhiteU8 = uint8(255);
BlackU8 = uint8(0);

thisGlyphCut_u8 = thisGlyphBitmap(startR_gl:endR_gl, startC_gl:endC_gl);
for idx=1:numPLanes
    % max value of product of two uint8 takes uint16; so
    % do the computation on uint16
    cg = 1;
    for c = startC_im:endC_im
        rg = 1;
        for r = startR_im:endR_im
            glyphVal = thisGlyphCut_u8(rg,cg);
            if (glyphVal == WhiteU8)
                imgOut(r,c,idx) = textColor(idx);
            elseif (glyphVal ~= BlackU8)
                tmp1 = uint16(imgOut(r,c,idx)) .* ...
                    uint16(MAX_VAL_DT - uint16(glyphVal));
                tmp2 = tmp1 + uint16 (uint16(textColor(idx)) *  ...
                    uint16(glyphVal));
                tmp3 = uint16(tmp2/MAX_VAL_DT);
                imgOut(r,c,idx) = tmp3;                    
            end
            rg = rg+1;
        end
        cg = cg+1;
    end
end

%==========================================================================
function imgOut = doGlyph_uint16(imgIn, thisGlyphBitmap, ...
                                         imgIdx, glIdx, textColor) 

MAX_VAL_DT = uint32(65535);
imgOut = imgIn;
numPLanes = size(imgIn, 3);

startR_im = imgIdx.startR_im;
startC_im = imgIdx.startC_im;
endR_im = imgIdx.endR_im;
endC_im = imgIdx.endC_im;

startR_gl = glIdx.startR_gl;
startC_gl = glIdx.startC_gl;
endR_gl = glIdx.endR_gl;
endC_gl = glIdx.endC_gl;

thisGlyphCut_u8 = thisGlyphBitmap(startR_gl:endR_gl, startC_gl:endC_gl);
thisGlyphCut_u16 = im2uint16(thisGlyphCut_u8);

for idx=1:numPLanes
    % max value of product of two uint8 takes uint16; so
    % do the computation on uint16     
    cg = 1;
    for c = startC_im:endC_im
        rg = 1;
        for r = startR_im:endR_im
            glyphVal = thisGlyphCut_u16(rg,cg);
            if (glyphVal == uint16(65535))
                imgOut(r,c,idx) = textColor(idx);
            elseif (glyphVal ~= uint16(0))
                tmp1 = uint32(imgOut(r,c,idx)) .* ...
                    uint32(MAX_VAL_DT - uint32(glyphVal));
                tmp2 = tmp1 + uint32(uint32(textColor(idx)) *  ...
                    uint32(glyphVal));
                tmp3 = uint32(tmp2/MAX_VAL_DT);
                imgOut(r,c,idx) = tmp3;                    
            end
            rg = rg+1;
        end
        cg = cg+1;
    end  
end  

%==========================================================================
function imgOut = doGlyph_int16(imgIn, thisGlyphBitmap, ...
                                         imgIdx, glIdx, textColor) 
    
imgOut = imgIn;
numPLanes = size(imgIn, 3);

startR_im = imgIdx.startR_im;
startC_im = imgIdx.startC_im;
endR_im = imgIdx.endR_im;
endC_im = imgIdx.endC_im;

startR_gl = glIdx.startR_gl;
startC_gl = glIdx.startC_gl;
endR_gl = glIdx.endR_gl;
endC_gl = glIdx.endC_gl;

MAX_VAL_DT = uint32(65535);
textColor_u16 = im2uint16(textColor);

thisGlyphCut_u8 = thisGlyphBitmap(startR_gl:endR_gl, startC_gl:endC_gl);
thisGlyphCut_u16 = im2uint16(thisGlyphCut_u8);

for idx=1:numPLanes
    % max value of product of two uint8 takes uint16; so
    % do the computation on uint16    
    cg = 1;
    for c = startC_im:endC_im
        rg = 1;
        for r = startR_im:endR_im
            glyphVal = thisGlyphCut_u16(rg,cg);
            if (glyphVal == uint16(65535))
                imgOut(r,c,idx) = textColor(idx);
            elseif (glyphVal ~= uint16(0))
                tmp1 = uint32(im2uint16(imgOut(r,c,idx))) .* ...
                    uint32(MAX_VAL_DT - uint32(glyphVal));
                tmp2 = tmp1 + uint32(uint32(textColor_u16(idx)) *  ...
                    uint32(glyphVal));
                tmp3 = uint32(tmp2/MAX_VAL_DT);
                imgOut(r,c,idx) = im2int16(uint16(tmp3));                    
            end
            rg = rg+1;
        end
        cg = cg+1;
    end
end 
