function [displayText iconString indexes SFcnText ...
    numPercentMinWidthNewLines convSpec fontFileName] = ...
    vipblktxtrnd(blk, action, varargin) 
% VIPBLKTXTRND Mask helper function for Insert Text block

% Copyright 1995-2009 The MathWorks, Inc.

persistent cache
if isempty(cache)
    cache.fontFileName = [];
    cache.fontFace = [];
end

idx.INTEN_INPORT_INDEX_INDEX    = 1;
idx.R_INPORT_INDEX_INDEX        = 1;
idx.G_INPORT_INDEX_INDEX        = 2;
idx.B_INPORT_INDEX_INDEX        = 3;
idx.WHICH_TEXT_IN_INDEX         = 4;
idx.REPLACEMENT_VARS_INDEX      = 5;
idx.COLOR_IN_INDEX_INDEX        = 6;
idx.INTEN_IN_INDEX_INDEX        = 6;
idx.LOC_INDEX_INDEX             = 7;
idx.OPAC_INDEX_INDEX            = 8;

defaultFont = 'LucidaSansRegular';

if nargin==0, 
  action='dynamic'; 
  blk = gcbh;
  calledFromBlock = true;
else
  calledFromBlock = ~matlab.system.isSystemObject(blk);
end


if calledFromBlock
  inputTypeParm = get_param(blk, 'inputType');
  if ~strcmp(get_param(blk,'tag'),'vipblks_tmp_nd_forward_compat')
    if (~strcmp(inputTypeParm,'Obsolete'))
      if strcmp(inputTypeParm, 'Intensity')
        set_param(blk, 'imagePorts', 'One multidimensional signal');
        if (strcmp(get_param(blk,'getTextIntensityFrom'),'Specify via dialog'))
          %If Intensity comes via mask, copy that value to Color
          set_param(blk,'textColor', get_param(blk, 'textIntensity'));
          set_param(blk,'getTextColorFrom', 'Specify via dialog');
        else
          set_param(blk,'getTextColorFrom', 'Input port');
        end
      elseif strcmp(inputTypeParm, 'RGB')
        set_param(blk, 'imagePorts', 'Separate color signals');
      end
      set_param(blk, 'inputType','Obsolete');
    end
  end
end

if calledFromBlock
  isRGB = strcmp(get_param(blk, 'imagePorts'), 'Separate color signals');
else
  isRGB = false; %Always one multidimensional signal for System objects
end

switch action
case 'init'
%% Compute the font information
    % fontinfo(fontName) returns the filename of the font
    theText  = varargin{1};
    theText  = strtok(theText, char(0));% for null terminated string, take only first part
    fontFace = varargin{2};
    sameFontFace = strcmp(cache.fontFace, fontFace);
    
    if (sameFontFace)
        fontFileName = cache.fontFileName; 
        % assuming fontFileName exists (how often you change font files!)
    else
        fontFileName = fontinfo(fontFace);
        cache.fontFace = fontFace;
        cache.fontFileName = fontFileName;
    end
    
    if isempty(fontFileName) && calledFromBlock
        % We must assume that an invalid font was specified.
        % Throw a warning, set the name to the default, and continue.
        warning(message('vision:vipblktxtrnd:invalidFont', fontFace, defaultFont));
        set_param(blk, 'fontFace','LucidaSansRegular');
        fontFace = defaultFont;
        fontFileName = fontinfo(fontFace);
    end
    
%% Compute the port information    
    
    % Get the active port indices and number of ports
    [indexes, text, numPercent, convSpec, width, numNewLines] = ...
        getPortIndexes(blk, theText, idx, isRGB, calledFromBlock);
    numPercentMinWidthNewLines = [numPercent width+1 numNewLines];
    numInputPorts = max(indexes);

%% Compute the display text
    bVariable = false;
    if ~iscell(text) && ischar(text) % defined variables and string literals
        displayText = text;
    elseif iscell(text) && ischar(text{1}) % cell arrays
        displayText = text{1};
    else % undefined variables (use an unquoted string)
        bVariable = true;
        if calledFromBlock
          displayText = get_param(blk, 'theText');
        else
          displayText = text;
        end
    end
    if length(displayText) > 11
        % The mask icon string cannot have three consecutive periods in it.
        displayText = [displayText(1:8) '.'' ''..'];
    end
    if ~bVariable
        displayText = ['''''' displayText ''''''];
    end
    SFcnText = text;

%% Compute the icon string
    iconString = ['disp(displayText);' sprintf('\n')];
    if isRGB 
        iconString = sprintf('%s%s', iconString, gimmieRGBPortLabels);
        numInputs = 3;
    else
        iconString = sprintf('%s%s', iconString, gimmieIntensityPortLabels(numInputPorts));
        numInputs = 1;
    end
    
    % text selection
    if indexes(idx.WHICH_TEXT_IN_INDEX) ~= -1
        numInputs = numInputs + 1;
        iconString = sprintf('%s\nport_label(''input'', %d, ''%s'');',...
            iconString, numInputs, 'Select');
    end
    
    % replacement variables
    if indexes(idx.REPLACEMENT_VARS_INDEX) ~= -1
        numInputs = numInputs + 1;
        iconString = sprintf('%s\nport_label(''input'', %d, ''%s'');',...
            iconString, numInputs, 'Variables');
    end
    
    % text color/intensity input port
    if indexes(idx.COLOR_IN_INDEX_INDEX) ~= -1
        numInputs = numInputs + 1;
        iconString = sprintf('%s\nport_label(''input'', %d, ''%s'');',...
            iconString, numInputs, 'Color');
    end
    
    % text location
    if indexes(idx.LOC_INDEX_INDEX) ~= -1
        numInputs = numInputs + 1;
        iconString = sprintf('%s\nport_label(''input'', %d, ''%s'');',...
            iconString, numInputs, 'Location');
    end
        
    % text opacity
    if indexes(idx.OPAC_INDEX_INDEX) ~= -1
        numInputs = numInputs + 1;
        iconString = sprintf('%s\nport_label(''input'', %d, ''%s'');',...
            iconString, numInputs, 'Opacity');
    end
    
    % See if we need to add a badge for the block using the old 
    % coordinate system
    libname = strtok(get_param(blk,'ReferenceBlock'), '/');
    if isempty(libname) % must be inside the library
        libname = get_param(blk,'Parent');
    end
    if strncmp('vip',libname,3) % we are called from the old viptextngfix library

        % display a badge indicating that this block
        % needs to be replaced by its newer version            
        b = vision.internal.getRCBadge;

        % color(b.color);
        iconString = sprintf('%s\ncolor(''%s'');',...
                             iconString, b.color);

        % text(b.txtX, b.txtY, b.txt,...
        %      'verticalAlignment',b.va,'horizontalAlignment',b.ha);

        iconString = sprintf(['%s\ntext(%f, %f, ''%s'', ''verticalAlignment'',', ...
                            ' ''%s'', ''horizontalAlignment'', ''%s'');'],...
                             iconString, b.txtX, b.txtY, b.txt, b.va, b.ha);

        %plot(b.boxX,b.boxY);
        iconString = sprintf('%s\nplot(%s, %s);',...
                             iconString, mat2str(b.boxX),...
                             mat2str(b.boxY));
    end
    
case 'dynamic'
  if calledFromBlock
    vis_orig = get_param(blk,'MaskVisibilities');
    vis = vis_orig;
    
    % text color is vis{10}, menu is vis{9}
    % text intensity is vis{12}, menu is vis{11}
    [iInputType,iGetTextColorFrom,iTextColor,iGetTextIntensityFrom, ...
      iTextIntensity,iImagePorts, iImageTransposed] = deal(1,9,10,11,12,18,19);
    vis{iInputType} = 'off';
    vis{iImagePorts} = 'on';
    vis{iImageTransposed} = 'on';
    vis{iTextIntensity} = 'off'; vis{iGetTextIntensityFrom} = 'off';
    
    vis{iGetTextColorFrom} = 'on';
    if isFromDialog(blk, 'getTextColorFrom'),
      vis{iTextColor} = 'on';
    else
      vis{iTextColor} = 'off';
    end
    
    % now set enabled-ness of text location and opacity edit boxes, based on
    % the popups
    
    %location
    if isFromDialog(blk, 'getTextLocFrom'),
      vis{8} = 'on';
    else
      vis{8} = 'off';
    end
    
    %opacity
    if isFromDialog(blk, 'getTextOpacityFrom'),
      vis{14} = 'on';
    else
      vis{14} = 'off';
    end
    
    % update look of mask, if necessary
    if ~isequal(vis,vis_orig),
      set_param(blk,'MaskVisibilities',vis);
    end
  end

otherwise
   error(message('vision:vipblktxtrnd:unknownAction'));   
end

%----------------------------------------------------------
function [indexes, theBlockText ,numPercentAndMinWidth, convSpec, width, ...
    numNewLines] = getPortIndexes(blk, theBlockText,idx, isRGB, isBlock) 

% there are eight possible input ports

% 1 - red/intensity signal
% 2 - green
% 3 - blue
% 4 - which text (if using cell array of strings)
% 5 - replacement variables (if text contains %d, %f, etc.)
% 6 - text color/intensity value
% 7 - text location
% 8 - text opacity


if isRGB,
    indexes(idx.R_INPORT_INDEX_INDEX) = 1;
    indexes(idx.G_INPORT_INDEX_INDEX) = 2;
    indexes(idx.B_INPORT_INDEX_INDEX) = 3;
    currentIndex = 4;
else
    indexes(idx.INTEN_INPORT_INDEX_INDEX) = 1;
    indexes(idx.G_INPORT_INDEX_INDEX) = -1;
    indexes(idx.B_INPORT_INDEX_INDEX) = -1;
    currentIndex = 2;
end

if iscell(theBlockText),
    indexes(idx.WHICH_TEXT_IN_INDEX) = currentIndex;
    currentIndex = currentIndex + 1;
else
    indexes(idx.WHICH_TEXT_IN_INDEX) = -1;
end

% replacement variables
needsReplacementVarsInport = false;
numPercentAndMinWidth = 0;
maxnumPercentAndMinWidth = numPercentAndMinWidth;
convSpec = '';
prevConvSpec = convSpec;
maxMinWidth = 0;
minWidth = 0;
maxPrecision = 0;
precision = 0;
if iscell(theBlockText),
     maxNumNewLines = 0;
    for i=1:length(theBlockText),
        numNewLines = length(strfind(theBlockText{i},10));   
        if (numNewLines > maxNumNewLines), numNewLines = maxNumNewLines; end        
        locOfPercent = strfind(theBlockText{i}, '%');
        if ~isempty(locOfPercent),
            [convSpec, numPercentAndMinWidth, minWidth, precision] = viptxtrndconvspec(theBlockText{i},isBlock);  
            if any(convSpec - '%')
                needsReplacementVarsInport = true;        
            end            
            if ~isempty(prevConvSpec) && (convSpec ~= prevConvSpec)
              if isBlock
                error(message('vision:vipblktxtrnd:sameConvLetter'));
              else
                error(message('vision:system:vipblktxtrnd:sameConvLetter'));
              end
            end
            prevConvSpec = convSpec;
            if (numPercentAndMinWidth > maxnumPercentAndMinWidth)
                maxnumPercentAndMinWidth = numPercentAndMinWidth;
            end
            if (~isempty(minWidth) && (minWidth > maxMinWidth))
                maxMinWidth = minWidth;
            end
            if (~isempty(precision) && (precision > maxPrecision))
                maxPrecision = precision;
            end
        end
    end
    numPercentAndMinWidth = maxnumPercentAndMinWidth;
    minWidth = maxMinWidth;
    precision= maxPrecision;
else
    numNewLines = length(strfind(theBlockText,10));            
    if ~isempty(strfind(theBlockText, '%'))
        [convSpec, numPercentAndMinWidth,minWidth, precision] = viptxtrndconvspec(theBlockText,true);
        if any(convSpec - '%')
            needsReplacementVarsInport = true;        
        end
    end
end
width = max(minWidth,precision);
if needsReplacementVarsInport,
    indexes(idx.REPLACEMENT_VARS_INDEX) = currentIndex;
    currentIndex = currentIndex + 1;
else
    indexes(idx.REPLACEMENT_VARS_INDEX) = -1;
end


% color/intensity
if (isBlock && ~isFromDialog(blk, 'getTextColorFrom'))  || ...
    (~isBlock && strcmp(blk.ColorSource, 'Input port'))
    indexes(idx.COLOR_IN_INDEX_INDEX) = currentIndex;
    currentIndex = currentIndex + 1;
else
    indexes(idx.COLOR_IN_INDEX_INDEX) = -1;
end

%location
if (isBlock && ~isFromDialog(blk, 'getTextLocFrom')) || ...
    (~isBlock && strcmp(blk.LocationSource, 'Input port'))
    indexes(idx.LOC_INDEX_INDEX) = currentIndex;
    currentIndex = currentIndex + 1;
else
    indexes(idx.LOC_INDEX_INDEX) = -1;
end

%opacity
if (isBlock && ~isFromDialog(blk, 'getTextOpacityFrom')) || ...
   (~isBlock && strcmp(blk.OpacitySource, 'Input port'))
    indexes(idx.OPAC_INDEX_INDEX) = currentIndex;
else
    indexes(idx.OPAC_INDEX_INDEX) = -1;
end

%----------------------------------------------------------
function iconString = gimmieRGBPortLabels
iconString = sprintf('port_label(''input'', 1, ''R'');');
iconString = sprintf('%s\nport_label(''input'', 2, ''G'');', iconString);
iconString = sprintf('%s\nport_label(''input'', 3, ''B'');', iconString);

iconString = sprintf('%s\nport_label(''output'', 1, ''R'');', iconString);
iconString = sprintf('%s\nport_label(''output'', 2, ''G'');', iconString);
iconString = sprintf('%s\nport_label(''output'', 3, ''B'');', iconString);

%----------------------------------------------------------
function iconString = gimmieIntensityPortLabels(numInputs)
if numInputs > 1
    iconString = sprintf('port_label(''input'', 1, ''Image'');\n');
else
    iconString = '';
end
% There is only one (untitled) output for intensity.

%---------------------------------------------------------
function ret = isFromDialog(blk, paramName)
paramStr = get_param(blk, paramName);
ret = strcmp(paramStr, 'Specify via dialog') == 1;

% [EOF] vipblktxtrnd.m
