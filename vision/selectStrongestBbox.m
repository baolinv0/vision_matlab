function [selectedBbox, selectedScore, index] = ...
                selectStrongestBbox(bbox, score, varargin)
%selectStrongestBbox Select strongest bounding boxes from overlapping clusters.
%  [selectedBbox, selectedScore] = selectStrongestBbox(bbox, score)
%  eliminates overlapping bounding boxes from M-by-4 input, bbox, and
%  returns only the boxes, selectedBbox, that have high confidence score.
%  scores is an M-by-1 vector of scores corresponding to the input bounding
%  boxes. This process is often referred to as non-maximum suppression.
%  Each row of input, bbox, contains [x y width height], where x and y are
%  an upper left corner of a bounding box. 
%
%  [selectedBbox, selectedScore, index] = selectStrongestBbox(bbox, score)
%  additionally returns the index vector associated with selectedBbox. This
%  vector contains the indices to the selected boxes in the bbox input.
%   
%  [selectedBbox, selectedScore, index] = selectStrongestBbox(... , Name,
%  Value) specifies additional name-value pairs described below:
%
%   'RatioType'         A string, 'Union' or 'Min', specifying the
%                       denominator of bounding box overlap ratio. 
%                       See bboxOverlapRatio for detailed explanation of 
%                       the ratio definition.
%
%                       Default: 'Union'
%                       
%   'OverlapThreshold'  A scalar from 0 to 1. All bounding boxes around a
%                       reference box are removed if their overlap ratio 
%                       is above this threshold.
%
%                       Default: 0.5
%
%  Class Support 
%  ------------- 
%  bbox and score must be real, finite, and nonsparse. They can be
%  uint8, int8, uint16, int16, uint32, int32, single or double.
%  OverlapThreshold can be single or double. Class of index output is
%  double. Class of selectedBbox is the same as that of bbox input. Class
%  of selectedScore is the same as that of score input.
%
%  Example 
%  ------- 
%  % load the pretrained people detector and disable the bounding box merging
%  peopleDetector = vision.PeopleDetector('ClassificationThreshold',0,'MergeDetections',false);
%
%  I = imread('visionteam1.jpg'); 
%  [bbox, score] = step(peopleDetector, I); 
%  I1 = insertObjectAnnotation(I, 'rectangle', bbox, cellstr(num2str(score)), 'Color', 'r');
%
%  % run the non-maximal suppression on bounding boxes
%  [selectedBbox, selectedScore] = selectStrongestBbox(bbox, score); 
%  I2 = insertObjectAnnotation(I, 'rectangle', selectedBbox, cellstr(num2str(selectedScore)), 'Color', 'r');
%
%  figure, imshow(I1); title('Detected people and detection scores before suppression'); 
%  figure, imshow(I2); title('Detected people and detection scores after suppression');
%
%  See also bboxOverlapRatio

%  Copyright 2013-2014 The MathWorks, Inc.

%#codegen
%#ok<*EMCLS>
%#ok<*EMCA>

isUsingCodeGeneration = ~isempty(coder.target);

% Parse and check inputs
if isUsingCodeGeneration
    checkInputBboxAndScoreCodegen(bbox, score);
    [ratioType, overlapThreshold] = validateAndParseOptInputsCodegen(varargin{:});
else
    checkInputBboxAndScore(bbox, score);
    [ratioType, overlapThreshold] = validateAndParseOptInputs(varargin{:});
end

if isempty(bbox),
    selectedBbox = bbox;
    selectedScore = score;
    index = [];
    return;
end

if strncmpi(ratioType, 'Union', 1),
    isDivByUnion = true;
else
    isDivByUnion = false;
end

if ~isfloat(bbox),
    inputBbox = single(bbox);
else
    inputBbox = bbox;
end

% sort the bbox according to the score
[~, ind] = sort(score, 'descend'); 
inputBbox = inputBbox(ind, :);

if isUsingCodeGeneration,
    selectedIndex = bboxOverlapSuppressionCodegen(inputBbox, ...
                                    overlapThreshold, isDivByUnion);
else
    [~, selectedIndex] = visionBboxOverlapSuppression(inputBbox, ...
                                    overlapThreshold, isDivByUnion);
end

index = sort(ind(selectedIndex), 'ascend');
selectedBbox = bbox(index, :);
selectedScore = score(index);

end

%==========================================================================
function [ratioType, overlapThreshold] = ...
                               validateAndParseOptInputs(varargin)
% Validate and parse optional inputs

defaults = struct('RatioType', 'Union', 'OverlapThreshold', 0.5);

% Setup parser
parser = inputParser;
parser.CaseSensitive = false;
parser.FunctionName  = mfilename;

parser.addParameter('RatioType', defaults.RatioType, @checkRatioType);
parser.addParameter('OverlapThreshold', ...
                    defaults.OverlapThreshold, @checkOverlapThreshold);

% Parse input
parser.parse(varargin{:});

ratioType = parser.Results.RatioType;

overlapThreshold = parser.Results.OverlapThreshold;

end

%==========================================================================
function checkInputBboxAndScore(bbox, score)
% Validate the input box and score

validateattributes(bbox,{'uint8', 'int8', 'uint16', 'int16', 'uint32', ...
    'int32', 'double', 'single'}, {'real','nonsparse','finite','size',[NaN, 4]}, ...
    mfilename, 'bbox', 1);

validateattributes(score,{'uint8', 'int8', 'uint16', 'int16', 'uint32', ...
    'int32', 'double', 'single'}, {'real','nonsparse','finite','size',[NaN, 1]}, ...
    mfilename, 'score', 2);

if (size(bbox,1) ~= size(score,1))
    error(message('vision:visionlib:unmatchedBboxAndScore'));
end

if (any(bbox(:,3)<=0) || any(bbox(:,4)<=0))
    error(message('vision:visionlib:invalidBboxHeightWidth'));
end
end

%========================================================================== 
function checkRatioType(value)
% Validate the input ratioType string

list = {'Union', 'Min'};
validateattributes(value, {'char'}, {'nonempty'}, mfilename, 'RatioType');

validatestring(value, list, mfilename, 'RatioType');
end

%==========================================================================
function checkOverlapThreshold(threshold)
% Validate 'OverlapThreshold'

validateattributes(threshold, {'single', 'double'}, {'nonempty', 'nonnan', ...
    'finite', 'nonsparse', 'real', 'scalar', '>=', 0, '<=', 1}, ...
    mfilename, 'OverlapThreshold');
end

%==========================================================================
function checkInputBboxAndScoreCodegen(bbox, score)
% Validate the input box and score

validateattributes(bbox,{'uint8', 'int8', 'uint16', 'int16', 'uint32', ...
    'int32', 'double', 'single'}, {'real','nonsparse','finite','size',[NaN, 4]}, ...
    mfilename, 'bbox', 1);

validateattributes(score,{'uint8', 'int8', 'uint16', 'int16', 'uint32', ...
    'int32', 'double', 'single'}, {'real','nonsparse','finite','size',[NaN, 1]}, ...
    mfilename, 'score', 2);

coder.internal.errorIf((size(bbox,1) ~= size(score,1)), ...
                        'vision:visionlib:unmatchedBboxAndScore');

coder.internal.errorIf((any(bbox(:,3)<=0) || any(bbox(:,4)<=0)), ...
                        'vision:visionlib:invalidBboxHeightWidth');
end

%==========================================================================
function [ratioType, overlapThreshold] = ...
                               validateAndParseOptInputsCodegen(varargin)
                           
defaults = struct('RatioType', 'Union', 'OverlapThreshold',  0.5);

if ~isempty(varargin)
    % Set parser inputs
    params = struct( ...
        'RatioType',             uint32(0), ...
        'OverlapThreshold',      uint32(0));

    popt = struct( ...
        'CaseSensitivity', false, ...
        'StructExpand',    true);

    % Parse parameter/value pairs
    optarg = eml_parse_parameter_inputs(params, popt, varargin{:});
    ratioType = eml_get_parameter_value(optarg.RatioType, ...
                            defaults.RatioType, varargin{:});    
    overlapThreshold  = eml_get_parameter_value(optarg.OverlapThreshold, ...
                            defaults.OverlapThreshold, varargin{:});
    
    checkRatioType(ratioType);
    checkOverlapThreshold(overlapThreshold);       
else
    ratioType = defaults.RatioType;
    overlapThreshold = defaults.OverlapThreshold;
end
end

%==========================================================================
function selectedIndex = bboxOverlapSuppressionCodegen(inputBbox, ...
                                    overlapThreshold, isDivByUnion)
isKept = true(size(inputBbox,1), 1); 
area = inputBbox(:,3).*inputBbox(:,4);
x1 = inputBbox(:,1); 
x2 = inputBbox(:,1)+inputBbox(:,3); 
y1 = inputBbox(:,2); 
y2 = inputBbox(:,2)+inputBbox(:,4);

% for each bbox i, suppress all surrounded bbox j where j>i and overlap
% ratio is larger than overlapThreshold
numOfBbox = size(inputBbox,1);
for i = 1:numOfBbox 
    if ~isKept(i) 
        continue; 
    end
    for j = (i+1):numOfBbox 
        if ~isKept(j)
            continue; 
        end

        % compute the intersect box
        width = min(x2(i), x2(j)) - max(x1(i), x1(j)); 
        if width <= 0 
            continue; 
        end

        height = min(y2(i), y2(j)) - max(y1(i), y1(j)); 
        if height <= 0 
            continue; 
        end

        areaOfIntersect = width * height; 
        if isDivByUnion 
            overlapRatio = areaOfIntersect/(area(i)+area(j)-areaOfIntersect); 
        else
            overlapRatio = areaOfIntersect/min(area(i), area(j)); 
        end

        if overlapRatio > overlapThreshold 
            isKept(j) = false; 
        end
    end
end

selectedIndex = find(isKept); 
end