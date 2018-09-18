function detector = peopleDetectorACF(varargin)
%peopleDetectorACF Detect upright people using ACF features.
%
%  detector = peopleDetectorACF() returns a pre-trained upright people
%  detector using Aggregate Channel Features (ACF). The detector is an
%  object of class acfObjectDetector, and is trained using the INRIA Person
%  dataset.
%
%  detector = peopleDetectorACF(name) returns a pre-trained upright people
%  detector based on specified model name. Valid model names are
%  'inria-100x41' and 'caltech-50x21'. The 'inria-100x41' model is trained
%  using the INRIA Person dataset. The 'caltech-50x21' model is trained
%  using the Caltech Pedestrian dataset.
%
% Example: Detect People
% ----------------------
% % Load the upright people detector
% detector = peopleDetectorACF();
%
% % Apply the detector
% I = imread('visionteam1.jpg');
% [bboxes, scores] = detect(detector, I);
% 
% % Annotate detected people    
% I = insertObjectAnnotation(I, 'rectangle', bboxes, scores);
% figure
% imshow(I)
% title('Detected people and detection scores')
%
% See also acfObjectDetector, acfObjectDetector/detect,
%       trainACFObjectDetector, vision.PeopleDetector, selectStrongestBbox,
%       vision.CascadeObjectDetector.

% References
% ----------
%   Dollar, Piotr, et al. "Fast feature pyramids for object detection."
%   Pattern Analysis and Machine Intelligence, IEEE Transactions on 36.8
%   (2014): 1532-1545.
%
%   Dollar, Piotr, et al. "Pedestrian detection: An evaluation of the state
%   of the art." Pattern Analysis and Machine Intelligence, IEEE
%   Transactions on 34.4 (2012): 743-761.
%
%   Dollar, Piotr, et al. "Pedestrian detection: A benchmark." Computer
%   Vision and Pattern Recognition, 2009. CVPR 2009. IEEE Conference on.
%   IEEE, 2009.

narginchk(0, 1);

if (isempty(varargin))
    name = 'inria-100x41';
else
    % validate user input
    name = checkModel(varargin{1});
end

% Get model and extract additional parameters
[model, ~, name] = loadModel(name);

params.ModelName = name;

% Channel related parameters
pPyramid = model.opts.pPyramid;
params.ModelSize          = round(model.opts.modelDs);
params.ModelSizePadded    = model.opts.modelDsPad;
params.Shrink             = pPyramid.pChns.shrink;
params.ChannelPadding     = pPyramid.pad;
params.Lambdas            = pPyramid.lambdas;
params.SmoothChannels     = pPyramid.smooth;
params.PreSmoothColor     = pPyramid.pChns.pColor.smooth;
params.NumUpscaledOctaves = pPyramid.nOctUp;
params.NumApprox          = pPyramid.nApprox;

% Parameters for gradient computation
params.gradient.FullOrientation       = model.opts.pPyramid.pChns.pGradMag.full;
params.gradient.NormalizationRadius   = model.opts.pPyramid.pChns.pGradMag.normRad;
params.gradient.NormalizationConstant = model.opts.pPyramid.pChns.pGradMag.normConst;

% Parameters for HOG computation
pGradHist = model.opts.pPyramid.pChns.pGradHist;
params.hog.NumBins   = pGradHist.nOrients;
params.hog.Normalize = pGradHist.useHog;

if isempty(pGradHist.binSize)
    params.hog.CellSize = params.Shrink;
else
    params.hog.CellSize = pGradHist.binSize;
end

switch pGradHist.softBin
    case 0
        % only interpolate orientation
        params.hog.Interpolation = 'Orientation';
    case 1
        % spatial and orientation interpolation.
        params.hog.Interpolation = 'Both';
end

params.hog.FullOrientation = params.gradient.FullOrientation;

% Training parameters
params.NumStages        = numel(model.opts.nWeak);
params.NegativeSamplesFactor = 10;
params.MaxWeakLearners  = model.opts.nWeak(end);

c = rmfield(model.clf, {'errs', 'losses'});
detector = acfObjectDetector(c, params);

%--------------------------------------------------------------------------
function [model, id, name] = loadModel(name)

modelLocation = fullfile(toolboxdir('vision'), 'visionutilities', 'classifierdata','acf');

[name, id] = getModelNameAndID(name);

if id == 1
    modelFile = fullfile(modelLocation, 'AcfInriaDetector.mat');
else
    modelFile = fullfile(modelLocation, 'AcfCaltech+Detector.mat');
end
data  = load(modelFile);
model = data.detector;

%--------------------------------------------------------------------------
function [name, id] = getModelNameAndID(name)

switch lower(name)
    case 'inria-100x41'
        name = 'inria-100x41';
        id   = 1;
    
    case 'caltech-50x21'
        name = 'caltech-50x21';
        id   = 2;    
end

%--------------------------------------------------------------------------
function valid = checkModel(model)
valid = validatestring(model,{'inria-100x41','caltech-50x21'},...
    mfilename, 'modelName');
