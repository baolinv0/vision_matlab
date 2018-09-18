%==========================================================================
% Validate and parse inputs for model fitting functions
%==========================================================================
function [ptCloud, ransacParams, sampleIndices, ...
    referenceVector, maxAngularDistance] = ...
    validateAndParseRansacInputs(filename, optionalConstraint, varargin)

% Default PV-pairs
defaults = struct('MaxNumTrials', 1000, 'Confidence', 99, 'SampleIndices', []);

parser = inputParser;
parser.CaseSensitive = false;
parser.FunctionName  = filename;

% Add required arguments
parser.addRequired('ptCloud', @validatePointCloudInput);
parser.addRequired('maxDistance', @(x)checkMaxDistance(x, filename));
% Add optional arguments for orientation constraints
if optionalConstraint
    parser.addOptional('referenceVector', [], @(x)checkReferenceVector(x, filename));
    parser.addOptional('maxAngularDistance', 5, @(x)checkMaxAngularDistance(x, filename));
end
% Add PV-pair arguments
parser.addParameter('MaxNumTrials', defaults.MaxNumTrials, ...
    @(x)checkMaxNumTrials(x, filename));
parser.addParameter('Confidence', defaults.Confidence, ...
    @(x)checkConfidence(x, filename));
parser.addParameter('SampleIndices', defaults.SampleIndices, ...
    @(x)checkSampleIndices(x, filename));

parser.parse(varargin{:});
    
params = parser.Results;

ptCloud         = params.ptCloud;
ransacParams.maxDistance     = params.maxDistance;
ransacParams.maxNumTrials    = params.MaxNumTrials;
ransacParams.confidence      = params.Confidence;
sampleIndices   = params.SampleIndices;
if optionalConstraint
    referenceVector = params.referenceVector;
    maxAngularDistance = params.maxAngularDistance;
    % Convert to radians
    maxAngularDistance = maxAngularDistance*pi/180;
else
    referenceVector = [];
    maxAngularDistance = [];
end

%==========================================================================
function tf = checkMaxDistance(value, filename)
validateattributes(value,{'single','double'}, ...
    {'real','scalar','nonnegative','finite'},filename,'maxDistance');
tf = true;

%==========================================================================
function tf = checkReferenceVector(value, filename)
validateattributes(value,{'single','double'}, ...
    {'real','finite','numel',3},filename,'referenceVector');
validateattributes(any(value), {'logical'}, ...
                {'nonzero'}, filename, 'referenceVector');
tf = true;

%==========================================================================
function tf = checkMaxAngularDistance(value, filename)
 validateattributes(value,{'single','double'}, ...
     {'real','scalar','nonnegative','finite'},filename,'maxAngularDistance');
tf = true;

%==========================================================================
function tf = checkMaxNumTrials(value, filename)
validateattributes(value, {'numeric'}, ...
    {'scalar', 'nonsparse', 'real', 'integer', 'positive'}, filename, 'MaxNumTrials');
tf = true;

%========================================================================== 
function tf = checkConfidence(value, filename)
validateattributes(value, {'numeric'}, ...
    {'scalar', 'nonsparse', 'real', 'positive', '<', 100}, filename, 'Confidence');
tf = true;

%========================================================================== 
function tf = checkSampleIndices(value, filename)
if ~isempty(value)
    validateattributes(value, {'numeric'}, ...
        {'integer', 'positive', 'real', 'vector'},...
        filename, 'SampleIndices');
else
    validateattributes(value, {'numeric'}, {'real'},...
        filename, 'SampleIndices');
end
tf = true;

%========================================================================== 
function tf = validatePointCloudInput(value)
if ~isa(value, 'pointCloud')
    error(message('vision:pointcloud:notPointCloudObject', 'ptCloud'));
end
tf = true;

