function params = parseInputs(I, varargin)
% Parse inputs for detectFASTFeatures.

vision.internal.inputValidation.validateImage(I, 'I', 'grayscale');

imageSize = size(I);

% Instantiate an input parser
parser = inputParser;
parser.FunctionName = 'detectFASTFeatures';
parser.CaseSensitive = false;

defaults = vision.internal.detector.fast.getDefaultParameters(imageSize);

parser.addParameter('MinQuality', defaults.MinQuality, ...
    @vision.internal.detector.checkMinQuality); 

parser.addParameter('MinContrast', defaults.MinContrast, ...
    @vision.internal.detector.checkMinContrast);

parser.addParameter('ROI', defaults.ROI);

% Parse and check the optional parameters
parser.parse(varargin{:});
params = parser.Results;

params.usingROI = isempty(regexp([parser.UsingDefaults{:} ''],...
    'ROI','once'));

if params.usingROI     
    vision.internal.detector.checkROI(params.ROI,imageSize);   
end

params.ROI = vision.internal.detector.roundAndCastToInt32(params.ROI);