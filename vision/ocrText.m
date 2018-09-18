% ocrText Object for storing OCR results.
%
% ocrText is returned by the ocr function and contains the recognized text
% and metadata collected during OCR. This data is stored in the following
% properties:
%
% ocrText properties:
%   Text                        - The text recognized by OCR
%   CharacterBoundingBoxes      - Bounding box locations of the characters
%   CharacterConfidences        - A vector of character confidences
%   Words                       - A cell array of recognized words
%   WordBoundingBoxes           - Bounding box locations of the words
%   WordConfidences             - A vector of word confidences
%
% ocrText methods:
%   locateText           - Locate text that matches a specific pattern
%
% bboxes = locateText(ocrText, pattern) returns bounding boxes around text
% within an image using the information in ocrText to find text that
% exactly matches the pattern. ocrText is returned by the ocr function. The
% pattern to find can be a single string or a cell array of strings. The
% returned bounding boxes are stored in an M-by-4 matrix, where each row is
% a four-element vector, [x y width height], that specifies the upper left
% corner and size of a rectangular region in pixels.
%
% [...] = locateText(ocrText, pattern, Name, Value) specifies
% additional name-value pair arguments described below:
%
% UseRegexp      A logical scalar. Set to true to treat the pattern as a
%                regular expression. See <a href="matlab:doc('regexp')">regexp</a> for more information about
%                regular expressions.
%
%                Default: false
%
% IgnoreCase     A logical scalar. Set to true to perform case insensitive
%                text location.
%
%                Default: false
%
% Example 1 - Highlight text in an image
% --------------------------------------
%    businessCard = imread('businessCard.png');
%    ocrResults   = ocr(businessCard);
%    bboxes = locateText(ocrResults, 'MathWorks', 'IgnoreCase', true);
%    Iocr   = insertShape(businessCard, 'FilledRectangle', bboxes);
%    figure; imshow(Iocr);
%
% Example 2 - Find text using regular expressions
% -----------------------------------------------
%    businessCard = imread('businessCard.png');
%    ocrResults   = ocr(businessCard);
%    bboxes = locateText(ocrResults, 'www.*com','UseRegexp', true);
%    img    = insertShape(businessCard, 'FilledRectangle', bboxes);
%    figure; imshow(img);
%
% See also ocr, ocrTrainer, regexp, strfind, insertShape

%#codegen
%#ok<*EMCA>
classdef ocrText
    properties(GetAccess = public,SetAccess = private)
        % Text - An array of characters recognized by OCR, including
        % white space and new line characters.
        Text        
        
        % CharacterBoundingBoxes - An M-by-4 matrix of bounding box
        % locations. Each row of CharacterBoundingBoxes is a four-element
        % vector, [x y width height], that specifies the upper left corner
        % and size of a rectangular region in pixels. The width and height
        % of bounding boxes corresponding to new line characters is zero.
        CharacterBoundingBoxes
        
        % CharacterConfidences - An array of character confidences between
        % 0 and 1. Confidence values should be interpreted as
        % probabilities. Spaces between words and new line characters have
        % confidence values of NaN as these are not explicitly recognized
        % during OCR.
        CharacterConfidences
        
        % Words - A cell array of recognized words.
        Words
        
        % WordBoundingBoxes - An M-by-4 matrix of bounding box locations.
        % Each row of WordBoundingBoxes is a four-element vector, [x y
        % width height], that specifies the upper left corner and size of a
        % rectangular region in pixels.
        WordBoundingBoxes
        
        % WordConfidences - An array of character confidences between 0 and
        % 1. Confidence values should be interpreted as probabilities.
        WordConfidences
                
    end    
    
    properties(Hidden, Access = private)
        pTextInfo        
    end
    
    methods
        function words = get.Words(obj)
            % Words access is not supported in codegen.
            coder.internal.assert(isempty(coder.target), ...
            'vision:ocr:codegenInvalidWordsAccess');
            
            words = obj.Words;            
        end
    end
    
    methods (Access = private)
        
        function this = ocrText(txt, metadata, params)
            if nargin ~= 0    
                
                if strcmpi(params.TextLayout, 'Character')
                    % Remove trailing newlines inserted by tesseract. This
                    % produces single character results for the character
                    % text layout mode.
                    newlines = txt == char(10);
                    txt(newlines) = [];
                    
                    metadata.CharacterBBox(newlines(:),:) = [];
                    metadata.CharacterConfidence(newlines(:)) = [];
                    metadata.CharacterWordIndex(newlines(:)) = [];
                end
                
                
                this.pTextInfo = metadata;
                this.Text      = txt;         
                
                if numel(this.Text) ~= size(metadata.CharacterBBox,1)
                    % Text and metadata are inconsistent. Use the text
                    % associated with the metadata instead.
                    this.Text = metadata.Characters;
                end
                
                % Get metadata for words.
                [this.WordConfidences, this.WordBoundingBoxes, this.Words] ...
                    = getWordMetadata(this);
                
                % Get bounding boxes for new line characters.
                newlines      = strfind(this.Text,char(10));           
                newlineBBoxes = getNewlineBBoxes(this, newlines);
                this.pTextInfo.CharacterBBox(newlines(:),:) = newlineBBoxes;
                
                % Get bounding boxes for spaces.
                spaces      = findSpaces(this);
                spaceBBoxes = getSpaceBBoxes(this, spaces);
                this.pTextInfo.CharacterBBox(spaces(:),:) = spaceBBoxes;
                
                % Fill metadata for Characters
                this.CharacterConfidences = this.pTextInfo.CharacterConfidence * single(0.01);
                
                % Confidence values less than zero indicate new line or
                % space characters. The negative confidence values are
                % converted to NaN in order to indicate they are not valid
                % confidences.
                this.CharacterConfidences(this.CharacterConfidences < 0) = NaN;
                this.CharacterBoundingBoxes = this.pTextInfo.CharacterBBox;
        
            end
        end
    end

    methods
           
        function bboxes = locateText(this, pattern, varargin)
            % bboxes = locateText(ocrText, pattern) returns bounding boxes
            % around text within an image using the information in ocrText
            % to find text that exactly matches the pattern. ocrText is
            % returned by the ocr function. The pattern to find can be a
            % single string or a cell array of strings. The returned
            % bounding boxes are stored in an M-by-4 matrix, where each row
            % is a four-element vector, [x y width height], that specifies
            % the upper left corner and size of a rectangular region in
            % pixels.
            %
            % [...] = locateText(ocrText, pattern, Name, Value) specifies
            % additional name-value pair arguments described below:
            %
            % UseRegexp      A logical scalar. Set to true to treat the
            %                pattern as a regular expression. See <a
            %                href="matlab:doc('regexp')">regexp</a> for
            %                more information about regular expressions.
            %
            %                Default: false
            %
            % IgnoreCase     A logical scalar. Set to true to perform case
            %                insensitive text location.
            %
            %                Default: false
            %
            % Example 1 - Highlight text in an image
            % --------------------------------------
            %    businessCard = imread('businessCard.png');
            %    ocrResults   = ocr(businessCard);
            %    bboxes = locateText(ocrResults, 'MathWorks', 'IgnoreCase', true);
            %    Iocr   = insertShape(businessCard, 'FilledRectangle', bboxes);
            %    figure; imshow(Iocr);
            %
            % Example 2 - Find text using regular expressions
            % -----------------------------------------------
            %    businessCard = imread('businessCard.png');
            %    ocrResults   = ocr(businessCard);
            %    bboxes = locateText(ocrResults, 'www.*com','UseRegexp', true);
            %    img    = insertShape(businessCard, 'FilledRectangle', bboxes);
            %    figure; imshow(img);
            %
            % See also ocr, regexp, strfind, insertShape

            params = checkInputs(pattern, varargin{:});
            
            if isscalar(this)
                bboxes = locateTextScalar(this, this.Text, pattern, ...
                    params.IgnoreCase, params.UseRegexp);
            else
                validateattributes(this,{class(this)},{'vector'});
                numROI = numel(this);
                bboxes = cell(numROI,1);
                for n = 1:numROI;
                    bboxes{n} = locateTextScalar(this(n), this(n).Text, ...
                        pattern, params.IgnoreCase, params.UseRegexp);
                end
            end
            
        end               
    end
    
    methods(Access = private)
        % -----------------------------------------------------------------
        % Returns bounding boxes around Text from startIndex to endIndex
        % -----------------------------------------------------------------
        function bbox = ind2bbox(this, startIndex, endIndex)                               
            
            startIndex = int32(startIndex);
            endIndex   = int32(endIndex);
            
            % Find the text line where Text(startIndex) is located
            widx   = this.pTextInfo.CharacterWordIndex(startIndex);
            tlidx  = this.pTextInfo.WordTextLineIndex(widx);
                                      
            % Define the end of all the text lines            
            endOfTextLines = this.pTextInfo.TextLineCharacterIndex(tlidx:end,:);
            
            % adjust for new lines at the end of the lines
            endOfTextLines = endOfTextLines(:,2) - 1;
            
            % clip last text line, which is a empty new line
            endOfTextLines(end) = length(this.Text);
            
            % Determine the number of line wraps that are present 
            numLineWraps = int32(sum(endIndex > endOfTextLines));
            tl = tlidx:tlidx+numLineWraps;
                        
            % Check if number of line wraps exceed number of textlines
            numTextLines = size(this.pTextInfo.TextLineBBox,1);
            if tlidx+numLineWraps > numTextLines
                numLineWraps = numTextLines - tlidx;
                tl = tlidx:tlidx+numLineWraps;
            end
            
            if numLineWraps
                % The set of indices, startIndex:endIndex, cover multiple
                % lines of text. We must partition this set and create
                % sub-sets that span only 1 line at a time so that we can
                % create bounding boxes for each line of text.
                
                % create array to hold sets of indices
                i1 = zeros(numLineWraps+1,1);
                i2 = zeros(numLineWraps+1,1);
                
                % store the starting and ending indices for each text line.
                tlIndexes = this.pTextInfo.TextLineCharacterIndex(tl,:);
                
                % partition startIndex:endIndex
                i1(1)       = startIndex;                                              
                i1(2:end)   = tlIndexes(2:end,1)';
                
                i2(1:end-1) = tlIndexes(1:end-1,2)'-2; % -2 for new line and one-past-the-last index value
                i2(end)     = endIndex;
                
                % Create a bounding box for each text line.
                n = numel(tl);
                bbox = zeros(n,4);
                for j = 1:n                                        
                    % get the bounding boxes of all the characters in the
                    % line of text between i1(j):i2(j)
                    charBBoxes = this.pTextInfo.CharacterBBox(i1(j):i2(j),:);
                    
                    if isempty(charBBoxes), continue, end;
                                                                              
                    bbox(j,:) = bboxUnion(charBBoxes);

                end
            else                   
                charBBoxes = this.pTextInfo.CharacterBBox(startIndex:endIndex,:);
                                                
                bbox = bboxUnion(charBBoxes);                
            end
            
        end
        
        % -----------------------------------------------------------------
        % Scalar version of locateText. Calls either strfind or regexp,
        % based on user selection.
        % -----------------------------------------------------------------
        function bboxes = locateTextScalar(this, txt, expr, ...
                ignoreCase, useRegexp)
            if logical(useRegexp)
                bboxes = regexpScalar(this,txt,expr,ignoreCase);
            else
                bboxes = strfindScalar(this,txt,expr,ignoreCase);
            end
        end
        
        % -----------------------------------------------------------------
        % Scalar version of strfind. Invokes strfind to locate text.
        % -----------------------------------------------------------------
        function bboxes = strfindScalar(this,txt, str, ignoreCase)
            if logical(ignoreCase)
                str = lower(str);
                txt = lower(txt);
            end
            if iscell(str)
                startIndex = cell(1,numel(str));
                endIndex   = cell(1,numel(str));
                for i = 1:numel(str)
                    startIndex{i} = strfind(txt,str{i});
                    endIndex{i}   = startIndex{i} + numel(str{i}) - 1;
                end
                startIndex = cell2mat(startIndex);
                endIndex   = cell2mat(endIndex);
            else
                startIndex = strfind(txt,str);
                endIndex   = startIndex + numel(str) - 1;
            end
            
            bboxes = populateBBox(this,startIndex, endIndex);
            
        end
        
        % -----------------------------------------------------------------
        % Populates bounding boxes that are generated for text between
        % startIndex and endIndex. 
        % -----------------------------------------------------------------
        function bboxes = populateBBox(this,startIndex, endIndex)
            bboxes = zeros(0,4);
            for i = 1:numel(startIndex)
                bboxes = [bboxes; ind2bbox(this, startIndex(i),endIndex(i))]; %#ok<AGROW>
            end
        end
        
        % -----------------------------------------------------------------
        % Scalar version of regexp for ocrText. Invokes regexp to locate
        % text.
        % -----------------------------------------------------------------
        function bboxes = regexpScalar(this, txt, expr, ignoreCase)
            if isempty(coder.target)
                if ignoreCase
                    [startIndex, endIndex] = regexpi(txt, expr, 'start','end');
                else
                    [startIndex, endIndex] = regexp(txt, expr, 'start','end');
                end
                
                if iscell(expr)
                    startIndex = cell2mat(startIndex);
                    endIndex   = cell2mat(endIndex);
                end
                bboxes = populateBBox(this, startIndex, endIndex);
            else
                bboxes = zeros(0,4);
            end
        end
        
        % -----------------------------------------------------------------
        % Get bounding boxes for new lines.
        % -----------------------------------------------------------------
        function bboxes = getNewlineBBoxes(this, newlines)
            % Get bboxes for newline characters. Newline characters are
            % "virtual" characters. They don't have a real bounding boxes,
            % but we need to make sure they have something that makes sense
            % for computations later on. Here a newline is given a bounding
            % box located at the end of the text line with a width and
            % height of zero.
            if isempty(newlines)
                bboxes = zeros(0, 4);
            else
                wordIdx = this.pTextInfo.CharacterWordIndex(newlines);
                tind = this.pTextInfo.WordTextLineIndex(wordIdx);
                bboxes = zeros(numel(tind), 4);
                for i = 1:numel(tind)
                    
                    textLineBBox = this.pTextInfo.TextLineBBox(tind(i),:);
                    % xy is at end of textline, width and height are zero
                    x = textLineBBox(1) + textLineBBox(3);
                    y = textLineBBox(2);
                    w = 0;
                    h = 0;
                    
                    bboxes(i,:) = [x y w h];
                    
                end
            end
        end
        
        % -----------------------------------------------------------------
        % Get bounding boxes for spaces.
        % -----------------------------------------------------------------
        function bboxes = getSpaceBBoxes(this,spaceIdx)
            % Spaces are not assigned bounding boxes by Tesseract.
            % Therefore, a bounding box for spaces is manually created to
            % ensure consistent processing later on. The bounding box for
            % a space between two words, w1 and w2, spans the distance
            % between w1 and w2. The x y location of the bounding
            % box for a space starts at the top right corner of the
            % bounding box for w1. The width equals the distance between w1
            % and w2, and the height is the set equal to the height of w1.
                                       
            wordIdx  = this.pTextInfo.CharacterWordIndex(spaceIdx);
            bboxes   = zeros(numel(wordIdx), 4);
            
            for i = 1:numel(wordIdx)
                wordBBox = this.pTextInfo.WordBBox(wordIdx(i),:);
                x = wordBBox(1) + wordBBox(3);
                y = wordBBox(2);
                
                w = max(this.pTextInfo.WordBBox(wordIdx(i)+1,1) - x, 1);
                h = wordBBox(4);
                
                bboxes(i,:) = [x y w h];
            end
        end
        % -----------------------------------------------------------------
        % Get word related metadata.
        % -----------------------------------------------------------------
        function [conf, bbox, words] = getWordMetadata(this)
            indices = this.pTextInfo.WordCharacterIndex;
            numWords = size(indices,1);
            
            conf = this.pTextInfo.WordConfidence .* single(0.01);
            bbox = this.pTextInfo.WordBBox;
            if isempty(coder.target)
                words = cell(numWords,1);
                for i = 1:size(indices,1)
                    words{i} = this.Text(indices(i,1):indices(i,2)-1);
                end
            else
                words = '';
            end
        end
        
        % -----------------------------------------------------------------
        % Return the indices to all the space characters between words.
        % -----------------------------------------------------------------
        function idx = findSpaces(this)                                                     
          
            % find all the spaces in Text
            allSpaces = this.Text' == char(32);                       
            
            % The spaces in Text might occur in the middle of actual words
            % when a small CharacterSet is used. These spaces must be
            % removed because they are not real spaces between words.
            %
            % Spaces in the middle of the word are removed by finding the
            % intersection between all the spaces and the real spaces
            % between words, which is encoded by CharacterConfidence values
            % of -1. Newlines locations are also encoded using
            % CharacterConfidences of -1, so the real space locations
            % cannot be determined using only the CharacterConfidences.
            
            isRealSpaceOrNewLine = this.pTextInfo.CharacterConfidence < 0;
                        
            idx = find(isRealSpaceOrNewLine(:) & allSpaces(:));
        end
    end

    methods(Hidden, Static)
        % -----------------------------------------------------------------
        % Create an ocrText object given text and metadata information.
        % -----------------------------------------------------------------
        function textInfo = create(txt,metadata,params)
            if iscell(txt)
                n = size(txt,1);
                if n > 0
                    textInfo(n,1) = ocrText(txt{end},metadata(end),params); %#ok<*EMVDF>
                    for i = 1:n-1
                        textInfo(i) = ocrText(txt{i},metadata(i),params);
                    end
                else
                    % create empty object array
                    textInfo = ocrText.empty(0,1);
                end
            else
                textInfo = ocrText(txt,metadata,params);
            end
        end
    end
end

% -------------------------------------------------------------------------
function params = checkInputs(pattern, varargin)

if isempty(coder.target)
    parser = inputParser();
    
    parser.addParameter('UseRegexp',  false);
    parser.addParameter('IgnoreCase', false);
    
    parse(parser, varargin{:});
    params = parser.Results;
    
else
    params = checkInputsCodegen(varargin{:});
end

if iscell(pattern)
    validateattributes(pattern,{'cell'},{'vector','row','nonempty'},'locateText');
    if ~iscellstr(pattern)
        error(message('vision:ocr:notAllStrings'));
    end
else    
    validateattributes(pattern, {'char'},{'vector','row','nonempty'},'locateText');
end

checkLogical(params.UseRegexp,  'UseRegexp');
checkLogical(params.IgnoreCase, 'IgnoreCase');

end

% -------------------------------------------------------------------------
function results = checkInputsCodegen(varargin)

pvPairs = struct( ...
    'UseRegexp',  uint32(0), ...
    'IgnoreCase', uint32(0));

popt = struct( ...
    'CaseSensitivity', false, ...
    'StructExpand'   , true, ...
    'PartialMatching', true);

optarg = eml_parse_parameter_inputs(pvPairs, popt, varargin{:});

results.UseRegexp  = eml_get_parameter_value(optarg.UseRegexp, ...
    false, varargin{:});

results.IgnoreCase = eml_get_parameter_value(optarg.IgnoreCase, ...
    false, varargin{:});

% UseRegexp is not supported in codegen.
coder.internal.errorIf(logical(results.UseRegexp),...
    'vision:ocr:codegenRegexpUnsupported');

end

% -------------------------------------------------------------------------
function checkLogical(tf,name)
vision.internal.errorIfNotFixedSize(tf, name);
validateattributes(tf, {'logical','numeric'},...
    {'nonnan', 'scalar', 'real','nonsparse'},...
    'locateText',name);
end

% -------------------------------------------------------------------------
% Merges multiple bboxes into one encompassing bbox
% -------------------------------------------------------------------------
function bbox = bboxUnion(bboxes)
x1 = bboxes(:,1);
y1 = bboxes(:,2);
x2 = bboxes(:,1) + bboxes(:,3) - 1;
y2 = bboxes(:,2) + bboxes(:,4) - 1;

x = min(x1);
y = min(y1);

w = max(x2) - x + 1;
h = max(y2) - y + 1;

bbox = [x y w h];
end
                    
