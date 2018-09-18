function txt = ocr(I, varargin)
%OCR Recognize text using Optical Character Recognition.
%    txt = OCR(I) returns an ocrText object containing the recognized text,
%    the location of the text within I, and a metric indicating the
%    confidence of the recognition result. Confidence values range between
%    0 and 1 and should be interpreted as probabilities.
%
%    txt = OCR(I, roi) recognizes text in I within one or more rectangular
%    regions defined by an M-by-4 matrix, roi. Each row of roi is a
%    four-element vector, [x y width height], that specifies the upper-left
%    corner and size of a rectangular region of interest in pixels. Each
%    rectangle must be fully contained within I.
%
%    [...] = OCR(...,Name,Value) specifies additional name-value pair
%    arguments described below:
%
%    'TextLayout'    Specify the layout of the text within I as a string.
%                    Valid string values are 'Auto', 'Block', 'Line',
%                    'Word', or 'Character'.
%
%                    Default: 'Auto'
%                
%    'Language'      Specify the language to recognize as a string or a
%                    cell array of strings. The language can be specified
%                    using the name of a language such as 'English' or
%                    'Japanese'.
%
%                    <a href="matlab:helpview(fullfile(docroot,'toolbox','vision','vision.map'),'ocrLanguage')">A list of supported languages is shown in the documentation.</a>
%
%                    <a href="matlab:helpview(fullfile(docroot,'toolbox','vision','vision.map'),'ocrLanguage')">Custom trained languages are also supported.</a>
%
%                    Default: 'English'        
%
%    'CharacterSet'  Specify the character set as a string of characters.
%                    The classification process is constrained to select
%                    the best matches from this smaller set of characters.
%                    By default, all characters in the Language are used.
%
%                    Default: ''
%                       
% Class Support
% -------------
% The input image I can be logical, uint8, int16, uint16, single, or
% double, and it must be real and nonsparse. 
%
% Example 1 - Recognize text within an image
% ------------------------------------------
%
%    businessCard   = imread('businessCard.png');
%    ocrResults     = OCR(businessCard)
%    recognizedText = ocrResults.Text;    
%    figure
%    imshow(businessCard)
%    text(600, 150, recognizedText, ... 
%        'BackgroundColor', [1 1 1])
%
% Example 2 - Recognize text in regions of interest (ROI)
% -------------------------------------------------------
%    I = imread('handicapSign.jpg');
%    
%    % Define one or more rectangular regions of interest within I.
%    roi = [360 118 384 560];
%
%    % You may also use IMRECT to select a region using a mouse:
%    %    figure; imshow(I); roi = round(getPosition(imrect))
%
%    ocrResults = OCR(I, roi);   
%
%    % Insert recognized text into original image
%    Iocr = insertText(I, roi(1:2), ocrResults.Text, ...
%        'AnchorPoint', 'RightTop', 'FontSize',16);
%    figure
%    imshow(Iocr)
%
% Example 3 - Display word bounding boxes and recognition confidences
% -------------------------------------------------------------------
%    businessCard = imread('businessCard.png');
%    ocrResults = OCR(businessCard)
%    Iocr = insertObjectAnnotation(businessCard, 'rectangle', ...
%        ocrResults.WordBoundingBoxes, ...
%        ocrResults.WordConfidences);
%    figure
%    imshow(Iocr)
%
% Example 4 - Find and highlight text in the image
% ------------------------------------------------
%
%    businessCard = imread('businessCard.png');
%    ocrResults   = OCR(businessCard);
%    bboxes = locateText(ocrResults, 'MathWorks', 'IgnoreCase', true);
%    Iocr   = insertShape(businessCard, 'FilledRectangle', bboxes);
%    figure
%    imshow(Iocr)
%
% See also ocrTrainer, ocrText, ocrText>locateText, insertShape, insertText

% References 
% ---------- 
% An Overview of the Tesseract OCR Engine In ICDAR '07: Proceedings of the
% Ninth International Conference on Document Analysis and Recognition
% (ICDAR 2007) Vol 2 (2007), pp. 629-633 by R. Smith
%
% Ray Smith and Daria Antonova and Dar-Shyang Lee. Adapting the Tesseract
% Open Source OCR Engine for Multilingual OCR. . 2009
%
% Ray Smith. Hybrid Page Layout Analysis via Tab-Stop Detection.
% Proceedings of the 10th international conference on document analysis and
% recognition. 2009.

%#codegen
%#ok<*EMCA>

[roi, hasROI, params] = parseInputs(I,varargin{:});


if islogical(I) && ~params.PreprocessBinaryImage  
    % Process binary images as-is if the PreprocessBinaryImage is false.
    % This by-passes tesseract's binarization stage.
    [rawtext, metadata] = tesseract(params, I, roi, hasROI);    
else    
    Iu8 = im2uint8(I);    
    img = vision.internal.ocr.convertRGBToGray(Iu8);
    
    [rawtext, metadata] = tesseract(params, img, roi, hasROI);    
end

txt = ocrText.create(rawtext, metadata, params);

% -------------------------------------------------------------------------
% Invoke Tesseract
% -------------------------------------------------------------------------
function [txt, ocrMetadata] = tesseract(params, Iu8, roi, hasROI)

[isSet, prefix] = unsetTessDataPrefix();

resetParameters = hasLanguageChanged(params.Language);
 
if vision.internal.ocr.isCodegen()            
    tessOpts = codegenParseParams(params);        
    [txt, ocrMetadata] = vision.internal.buildable.OCRBuildable.tesseract(tessOpts, Iu8, hasROI, resetParameters);       
else    
    tessOpts = parseParams(params);
    [txt, ocrMetadata] = tesseractWrapper(tessOpts, Iu8, hasROI, roi, resetParameters);
end

coder.extrinsic('setenv')
if isSimOrMex()
    if isSet
        setenv('TESSDATA_PREFIX',prefix)
    end
end

% -------------------------------------------------------------------------
% Return true if the input language does not match the cached language.
% -------------------------------------------------------------------------
function tf = hasLanguageChanged(language)
persistent cachedLanguage

language = convertToCacheableValue(language);

% used fixed size language string to support codegen
% with max length of 4096.
n = min(4096, numel(language));
if isempty(cachedLanguage)
    cachedLanguage = zeros(1,4096,'uint8');
    cachedLanguage(1:n) = cast(language(1:n), 'uint8');
end

if isequal(language(1:n), cachedLanguage(1:n))
    tf = false;
else
    % language has changed. update cached value.
    cachedLanguage(1:n) = cast(language(1:n), 'uint8');
    tf = true;
end

% -------------------------------------------------------------------------
function lang = convertToCacheableValue(lang)
% cached multiple languages as concatenated string
if isempty(coder.target) && iscell(lang)
    lang = [lang{:}];
end

% -------------------------------------------------------------------------
% Parse inputs.
% -------------------------------------------------------------------------
function [roi, hasROI, params] = parseInputs(I, varargin)

sz = size(I);
vision.internal.inputValidation.validateImage(I);

if mod(nargin-1,2) == 1
    hasROI = true;
    roi = int32(round(varargin{1}));
    checkROI(roi,sz(1:2));
else
    hasROI = false;
    roi = ones(0,4,'int32');
end

if vision.internal.ocr.isCodegen()
    if hasROI
        userInput = codegenParseInputs(varargin{2:end});
    else
        userInput = codegenParseInputs(varargin{:});
    end
else
    p = getInputParser();
    parse(p, varargin{:});
    userInput = p.Results;
    
    userInput.UsingCharacterSet = isempty(regexp([p.UsingDefaults{:} ''],...
        'CharacterSet','once'));
    
end

validTextLayout = checkTextLayout(userInput.TextLayout);
[validLanguage, isCustomLanguage] = checkLanguage(userInput.Language);

if userInput.UsingCharacterSet    
    checkCharacterSet(userInput.CharacterSet);
end

checkPreprocessBinaryImage(userInput.PreprocessBinaryImage);

params = setParams(userInput, validLanguage, validTextLayout, isCustomLanguage);

% -------------------------------------------------------------------------
% Parse inputs during codegen.
% -------------------------------------------------------------------------
function results = codegenParseInputs(varargin)
pvPairs = struct( ...
    'TextLayout',   uint32(0), ...
    'Language',     uint32(0),...
    'CharacterSet', uint32(0),...
    'PreprocessBinaryImage',  uint32(0));

popt = struct( ...
    'CaseSensitivity', false, ...
    'StructExpand'   , true, ...
    'PartialMatching', true);

defaults = getParamDefaults();

optarg = eml_parse_parameter_inputs(pvPairs, popt, varargin{:});

results.TextLayout  = eml_get_parameter_value(optarg.TextLayout, ...
    defaults.TextLayout, varargin{:});

language = coder.internal.const(eml_get_parameter_value(optarg.Language, ...
    coder.internal.const(defaults.Language), varargin{:}));

results.CharacterSet = eml_get_parameter_value(optarg.CharacterSet, ...
    defaults.CharacterSet, varargin{:});

results.PreprocessBinaryImage  = eml_get_parameter_value(optarg.PreprocessBinaryImage, ...
    defaults.PreprocessBinaryImage, varargin{:});

% UsingCharacterSet true if the user supplied one
results.UsingCharacterSet = logical(optarg.CharacterSet);

results.Language = language;

% Warning if a non-English language or custom language is specified.
if ~(optarg.Language==uint32(0)) && ~strcmpi(language,'english')    
    coder.internal.compileWarning('vision:ocr:codegenASCIIOnly');    
end

% -------------------------------------------------------------------------
function checkROI(roi,imageSize)

for i = 1:size(roi,1)
    vision.internal.detector.checkROI(roi(i,:),imageSize);
end

% -------------------------------------------------------------------------
function isCustomLang = checkIfCustomLanguage(lang)

idx = strfind(lang, '.traineddata');
if isempty(idx)
    isCustomLang = false;
else
    isCustomLang = true;
end 

% -------------------------------------------------------------------------
function [lang, isCustomLanguage] = checkLanguage(userLanguage)

validateattributes(userLanguage,{'char','cell'},{'vector','row'}, ...
    mfilename,'Language');

coder.extrinsic('exist','filesep');
if ischar(userLanguage)
    isCustomLanguage = checkIfCustomLanguage(userLanguage);
    
    if vision.internal.ocr.isCodegen()
        modifiedLang = userLanguage;
    else
        % fix up filesep for current platform. This converts PC style \ to
        % unix style / or vice versa. This prevents failures when loading
        % tesseract data files.      
        modifiedLang = fixFilesep(userLanguage);
    end
    
    if ~isCustomLanguage        
        lang = vision.internal.ocr.validateLanguage(modifiedLang, vision.internal.ocr.ocrSpkgInstalled());        
    else
        
        lang = modifiedLang;           
        if vision.internal.ocr.isCodegen()
            coder.internal.errorIf(vision.internal.codegen.exist(lang) ~= 2,...
                'vision:ocr:languageDataFileNotFound', lang);        
        else
            coder.internal.errorIf(exist(lang,'file') ~= 2,...
                'vision:ocr:languageDataFileNotFound', lang);
        end
    end
    
else % cell array of languages strings
    
    % check custom language strings. When multiple custom languages are
    % specified, they must all be custom languages (i.e. 'English' and a
    % custom language is not allowed).
    
    isCustomLanguage = cellfun(@(x)checkIfCustomLanguage(x),userLanguage); %#ok<EMFH>
       
    isMixedCustomAndNonCustomLanguages = any(isCustomLanguage) && ~all(isCustomLanguage);
    
    if isMixedCustomAndNonCustomLanguages        
        error(message('vision:ocr:customAndNonCustom'));
    end
            
    if all(isCustomLanguage)
        
        % all had at least tessdata/*.traineddata
        isCustomLanguage = true;
               
        lang    = fixFilesep(userLanguage);                
        pathstr = cell(numel(lang),1);
        for i = 1:numel(lang)
           pathstr{i} = fileparts(lang{i});
        end
        
        % all language data files must be in the same tessdata folder
        if numel(unique(pathstr)) > 1
            error(message('vision:ocr:notUniqueLanguagePath'));
            % this will fail if one is a relative path and the other is a
            % full path to the same folder.
        end
        
        % All language data files must be accessible
        for i = 1:numel(lang)
            if ~exist(lang{i},'file')
                error(message('vision:ocr:languageDataFileNotFound',lang{i}));
            end
        end
    else        
        % check non-custom language strings
        isSupportPackageInstalled = vision.internal.ocr.ocrSpkgInstalled();
        for i = 1:numel(userLanguage)            
            lang{i} = vision.internal.ocr.validateLanguage(userLanguage{i}, isSupportPackageInstalled);
        end        
        isCustomLanguage = false;
    end
end

% -------------------------------------------------------------------------
function checkCharacterSet(list)

validateattributes(list, {'char'},{},mfilename,'CharacterSet'); % allow empty ''

if ~isempty(list)
    % make sure it's a vector
    validateattributes(list, {'char'},{'vector'},mfilename,'CharacterSet');
end
% -------------------------------------------------------------------------
function str = checkTextLayout(layout)

str = validatestring(layout,{'Auto','Block','Line','Word','Character'},...
    mfilename,'TextLayout');

% -------------------------------------------------------------------------
function checkPreprocessBinaryImage(value)

validateattributes(value, {'numeric','logical'}, ...
    {'nonnan', 'scalar', 'real','nonsparse'}, mfilename, 'PreprocessBinaryImage');

% -------------------------------------------------------------------------
function defaults = getParamDefaults()

defaults.TextLayout   = coder.internal.const('Auto');
defaults.Language     = coder.internal.const('English');
defaults.CharacterSet = coder.internal.const('');
defaults.PreprocessBinaryImage  = true;

% -------------------------------------------------------------------------
function params = setParams(userInput, language, textLayout, isCustomLanguage)

params.TextLayout        = textLayout;
params.Language          = language;
params.CharacterSet      = userInput.CharacterSet;
params.UsingCharacterSet = userInput.UsingCharacterSet;
params.isCustomLanguage  = coder.internal.const(isCustomLanguage);
params.PreprocessBinaryImage = logical(userInput.PreprocessBinaryImage);


% -------------------------------------------------------------------------
% Parse tesseract parameters
% -------------------------------------------------------------------------
function tessOpts = parseParams(params)

% Specify tesseract variable names as the fields of setVariable. The
% variable values should be specified as strings.
tessOpts.setVariable.tessedit_pageseg_mode = getTextLayout(params);

if params.UsingCharacterSet
    tessOpts.setVariable.tessedit_char_whitelist = params.CharacterSet;
end

% enable save_blob_choices to save individual character confidence values.
tessOpts.setVariable.save_blob_choices = 'T';

[tessdata, lang] = getLanguageInfo(params);

tessOpts.tessdata     = tessdata;
tessOpts.lang         = lang;

% Specify tesseract initialization variables names as the fields of
% initVariable. The variable values should be specified as strings.
tessOpts.initVariable = [];

% -------------------------------------------------------------------------
% codegen: Parse tesseract parameters
% -------------------------------------------------------------------------
function tessOpts = codegenParseParams(params)

textLayout = getTextLayout(params); 

if params.UsingCharacterSet
    charSet = params.CharacterSet;
else
    charSet = '';
end    

[tessdata,lang] = getLanguageInfo(params);

tessOpts.textLayout   = textLayout;
tessOpts.characterSet = charSet;
tessOpts.tessdata     = tessdata;
tessOpts.lang         = lang;

% -------------------------------------------------------------------------
% Return the parameter value used by tesseract to set the page segmentation
% mode (PSM). Setting other values for the page segmentation mode is not
% recommended.
% -------------------------------------------------------------------------
function textLayout = getTextLayout(params)

switch params.TextLayout
    case 'Auto'
        textLayout = '3'; 
    case 'Block'
        textLayout = '6';
    case 'Line'
        textLayout = '7';
    case 'Word'
        textLayout = '8';
    case 'Character'
        textLayout = '10';
    otherwise
        textLayout = '';  % codegen requires assignments for all paths               
end

% -------------------------------------------------------------------------
% Return the path to the tessdata folder and the language string.
% -------------------------------------------------------------------------
function [tessdata,lang] = getLanguageInfo(params)
coder.extrinsic('ctfroot','matlabroot','fullfile','regexpi');

if params.isCustomLanguage     
    % params.Language contains a validated file path to the Tesseract
    % language data file. The expected format is
    %
    %    'path/to/tessdata/foo.traineddata'
    %   
    % where foo is the language name.          
    if iscell(params.Language)
        
        % this section of code is not supported for code generation due to
        % limited cell array support.
        
        lang = cell(size(params.Language));
        for i = 1:numel(params.Language)
            indexStart = strfind(params.Language{i}, ['tessdata' filesep]) + 9; 
            indexEnd   = strfind(params.Language{i}, '.traineddata') - 1;
            lang{i} = params.Language{i}(indexStart(end):indexEnd(end));
        end
        if numel(lang) > 1
            % multiple language take the form "lang1+lang2+..."
            lang = strjoin(lang,'+');
        else
            lang = lang{1};
        end
        
        % find the string 'tessdata/foo.traineddata' located at the end of
        % language data path specified by the user.
        indexStart = regexpi(params.Language{1},...
            'tessdata[\/\\]+(\w+)\.traineddata$','start');     
        
        tessdata = params.Language{1}(1:indexStart-1);
        
        if isempty(tessdata)
            % tessdata located in the current directory
            tessdata = ['.' filesep];
        end                
    else      
        tessdata = getTessdataFromPath(params.Language);
        lang     = getLanguageFromPath(params.Language);                 
    end
    
else % a non-custom language
    lang     = vision.internal.ocr.convertLanguageToAlias(params.Language);       
    tessdata = vision.internal.ocr.locateTessdataFolder(lang);
end

% -------------------------------------------------------------------------
% Return the location of the tessdata folder from the path to a custom
% language data file.
%--------------------------------------------------------------------------
function tessdata = getTessdataFromPath(datapath)
indexStart = strfind(datapath,'tessdata');

% codegen: use isempty to check strfind result
if isempty(indexStart)
    start = 0;
else
    start = indexStart(end);
end

if start-1 == 0
    tessdata = './';
else
    tessdata = datapath(1:start-1);
end

% -------------------------------------------------------------------------
% Return language alias from the path to a custom language data file.
%--------------------------------------------------------------------------
function lang = getLanguageFromPath(datapath)

indexStart = strfind(datapath, 'tessdata') + 9;
indexEnd   = strfind(datapath, '.traineddata') - 1;

if isempty(indexStart) || isempty(indexEnd)
    lang = '';
else
    iStart = indexStart(end);
    iEnd   = indexEnd(end);
    lang   = datapath(iStart:iEnd);
end

% -------------------------------------------------------------------------
% Return the inputParser used for parameter parsing. The inputParser is
% created once and stored in a persistent variable to improve performance.
% -------------------------------------------------------------------------
function parser = getInputParser()
persistent p;
if isempty(p)   
    defaults = getParamDefaults();
    p = inputParser();      
    addOptional(p, 'ROI', []);
    addParameter(p, 'TextLayout',   defaults.TextLayout);
    addParameter(p, 'Language',     defaults.Language);
    addParameter(p, 'CharacterSet', defaults.CharacterSet);
    addParameter(p, 'PreprocessBinaryImage', ...
        defaults.PreprocessBinaryImage);
    
    parser = p;
else
    parser = p;
end


% -------------------------------------------------------------------------
function modifiedLang = fixFilesep(userLanguage)
% Fix filesep for current platform. This converts PC style \ to unix style
% / or vice versa. This prevents failures when loading tesseract data
% files.
if vision.internal.ocr.isCodegen()
    % this function is not used in codegen, but codegen requires outputs to
    % be assigned on all execution paths.  
    modifiedLang = userLanguage;
else
    modifiedLang = regexprep(userLanguage,'[\/\\]',filesep);
end

% -------------------------------------------------------------------------
% Clear the TESSDATA_PREFIX environment variable if it is set. This enables
% ocr to use the tessdata files specified using file paths instead of
% defaulting to the location of TESSDATA_PREFIX.
% -------------------------------------------------------------------------
function [isSet, prefix] = unsetTessDataPrefix()
coder.extrinsic('setenv','getenv')

if isSimOrMex()
    prefix = getenv('TESSDATA_PREFIX');
    if isempty(prefix)
        isSet = false;
    else
        setenv('TESSDATA_PREFIX','');
        isSet = true;
    end
else
    isSet  = false;
    prefix = '';
end

% -------------------------------------------------------------------------
% Check whether we are in sim or mex mode
% -------------------------------------------------------------------------
function tf = isSimOrMex()

tf = isempty(coder.target) || coder.target('MEX');
