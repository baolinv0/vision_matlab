%detectPeopleACF Detect upright people using ACF features
%
% -------------------------------------------------------------------------
%    The detectPeopleACF will be removed in a future release. Use the
%    peopleDetectorACF function with equivalent functionality instead.
% -------------------------------------------------------------------------
%
%  bboxes = detectPeopleACF(I) detects upright people using Aggregate
%  Channel Features (ACF). The location of people within I are returned in
%  bboxes, an M-by-4 matrix defining M bounding boxes. Each row of bboxes
%  contains a four-element vector, [x, y, width, height]. This vector
%  specifies the upper-left corner and size of a bounding box in pixels.
%  The input image I must be a truecolor image.
%
%  [..., scores] = detectPeopleACF(I) optionally returns the detection
%  scores for each bounding box. The score for each detection is the
%  output of a soft-cascade classifier. The range of score values is [-inf
%  inf]. Larger score values indicate a higher confidence in the detection.
%
%  [...] = detectPeopleACF(I, roi) detects people within the rectangular
%  search region specified by roi. roi must be a 4-element vector, [x, y,
%  width, height], that defines a rectangular region of interest fully
%  contained in I.
%
%  [...] = detectPeopleACF(..., Name, Value) specifies additional
%  name-value pairs described below.
%
%  'Model'                The name of the ACF classification model. Valid
%                         values for this property are 'caltech-50x21'
%                         and 'inria-100x41'. The 'caltech-50x21'
%                         model was trained using the Caltech Pedestrian
%                         dataset. The 'inria-100x41' model was trained
%                         using the INRIA Person dataset.
%   
%                         Default: 'inria-100x41'
%
%  'NumScaleLevels'       Number of scale levels per octave, where each
%                         octave is a power of 2 downscaling of the image.
%                         Increase this number to detect people at finer
%                         scale increments. Recommended values are between
%                         4 and 8.
% 
%                         Default: 8
%
%  'WindowStride'         Specify the window stride for sliding-window
%                         object detection. The same stride is used in both
%                         the x and y directions.
%
%                         Default: 4
%
%  'SelectStrongest'      A logical scalar. Set this to true to eliminate
%                         overlapping bounding boxes based on their scores.
%                         This process is often referred to as non-maximum
%                         suppression. Set this to false to if you want to
%                         perform a custom selection operation. When set to
%                         false all the detected bounding boxes are
%                         returned.
% 
%                         Default: true
%
%  'MinSize'              Specify the size of the smallest region
%                         containing a person, in pixels, as a two-element
%                         vector, [height width]. When you know the minimum
%                         person size to detect beforehand, you can reduce
%                         computation time by setting this parameter to
%                         that known value. By default, 'MinSize' is the
%                         smallest upright person that can be detected by
%                         the classification model.
%                         
%                         Model          | Minimum Size
%                         --------------------------------------
%                         caltech-50x21  |  [50 21]
%                         inria-100x41   |  [100 41]
%
%  'MaxSize'              Specify the size of the biggest region containing
%                         a person, in pixels, as a two-element vector,
%                         [height width]. When you know the maximum person
%                         size to detect beforehand, you can reduce
%                         computation time by setting this parameter to
%                         that known value. Otherwise, the maximum size is
%                         the determined by the width and height of I.
%
%                         Default: size(I)
%
%  'Threshold'            The threshold value to control the classification
%                         accuracy and speed of individual image
%                         sub-regions as person or non-person during
%                         multi-scale object detection. Increase this
%                         threshold to speed up the performance at the risk
%                         of potentially missing true detections. Typical
%                         values range from -1 to 1.
%
%                         Default: -1
%
% Class Support
% -------------
% The input image I can be uint8, uint16, int16, double, single, and it
% must be real and non-sparse.
%
% Example: Detect People
% ----------------------
%
% I = imread('visionteam1.jpg');
% [bboxes, scores] = detectPeopleACF(I);
% 
% % Annotate detected people    
% I = insertObjectAnnotation(I, 'rectangle', bboxes, scores);
% figure
% imshow(I)
% title('Detected people and detection scores')
%
% See also vision.PeopleDetector, selectStrongestBbox, vision.CascadeObjectDetector.

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

function [bboxes, scores] = detectPeopleACF(I, varargin)

[params, detector] = parseInputs(I, varargin{:});

Iroi = vision.internal.detector.cropImageIfRequested(I, params.ROI, params.UseROI);

P = vision.internal.acf.computePyramid(Iroi, params);

[bboxes, scores] = vision.internal.acf.detect(P, detector, params);

bboxes = round(bboxes);

% Channels are padded during detection. This may lead to negative box
% positions. Clip boxes to ensure they are within image boundary.
bboxes = vision.internal.detector.clipBBox(bboxes, size(Iroi));

bboxes(:,1:2) = vision.internal.detector.addOffsetForROI(bboxes(:,1:2), params.ROI, params.UseROI);

if params.SelectStrongest    
    [bboxes, scores] = selectStrongestBbox(bboxes, scores, ...
        'RatioType', 'Min', 'OverlapThreshold', 0.65);
end

%--------------------------------------------------------------------------
function m = getModel(params)
persistent model id name

if isempty(model)    
    % first time initialization
    model = cell(1,2);    
    [data, id, name] = loadModel(params.Model);
    model{id} = data;
    
elseif ~strcmp(params.Model, name) 
    
    % model changed
    [name, id] = getModelNameAndID(params.Model);
    
    if isempty(model{id}) 
        % model not loaded yet. load it now.
        model{id} = loadModel(params.Model);
    end           
end

m = model{id};

%--------------------------------------------------------------------------
function [detector, id, name] = loadModel(name)

modelLocation = fullfile(toolboxdir('vision'), 'visionutilities', 'classifierdata','acf');

[name, id] = getModelNameAndID(name);

if id == 1
    modelFile = fullfile(modelLocation, 'AcfCaltech+Detector.mat');
    data      = load(modelFile);
    detector  = data.detector;
    
else
    modelFile = fullfile(modelLocation, 'AcfInriaDetector.mat');
    data      = load(modelFile);
    detector  = data.detector;
end

%--------------------------------------------------------------------------
function [name, id] = getModelNameAndID(name)

switch lower(name)
    case 'caltech-50x21'
        name =  'caltech-50x21';
        id   = 1;
        
    case 'inria-100x41'
        name = 'inria-100x41';
        id   = 2;
end

%--------------------------------------------------------------------------
function [params, detector] = parseInputs(I, varargin)

p = inputParser;
[M, N, ~] = size(I);
default = getParameterDefaults();
p.addOptional('ROI', zeros(0,4));
p.addParameter('Model', default.Model)
p.addParameter('Threshold', default.Threshold)
p.addParameter('WindowStride', default.WindowStride);
p.addParameter('NumScaleLevels', default.NumScaleLevels);
p.addParameter('MinSize', default.MinSize);
p.addParameter('MaxSize', [M N]);
p.addParameter('SelectStrongest', default.SelectStrongest, ...
    @(x)vision.internal.inputValidation.validateLogical(x,'SelectStrongest'));

p.parse(varargin{:});

userInput = p.Results;

wasMinSizeSpecified = ~ismember('MinSize', p.UsingDefaults);
wasMaxSizeSpecified = ~ismember('MaxSize', p.UsingDefaults);

% validate user input
checkImage(I);

modelname = checkModel(userInput.Model);

checkThreshold(userInput.Threshold);

checkStride(userInput.WindowStride);

checkSelectStrongest(userInput.SelectStrongest);

checkNumScaleLevels(userInput.NumScaleLevels);

modelSize = getModelSize(modelname);

if wasMinSizeSpecified
    checkMinSize(userInput.MinSize, modelSize);
                
else
    % set min size to model training size if not user specified.
    userInput.MinSize = modelSize;
end

if wasMaxSizeSpecified
    checkMaxSize(userInput.MaxSize, modelSize);
         
    % note: default max size set above in inputParser to size(I)
end

if wasMaxSizeSpecified && wasMinSizeSpecified
    % cross validate min and max size    
    coder.internal.errorIf(any(userInput.MinSize >= userInput.MaxSize) , ...
        'vision:ObjectDetector:minSizeGTMaxSize');
end

useROI = ~ismember('ROI', p.UsingDefaults);

if useROI
      
    vision.internal.detector.checkROI(userInput.ROI, size(I));          
          
    if ~isempty(userInput.ROI)
        sz = userInput.ROI([4 3]);
        checkImageSizes(sz, userInput, wasMinSizeSpecified, modelSize, ...
            'vision:ObjectDetector:ROILessThanMinSize', ...
            'vision:ObjectDetector:ROILessThanModelSize');
    end
       
else        
    
    checkImageSizes([M N], userInput, wasMinSizeSpecified, modelSize, ...
        'vision:ObjectDetector:ImageLessThanMinSize', ...
        'vision:ObjectDetector:ImageLessThanModelSize');
              
end

% set user input to expected type
params.ROI             = double(userInput.ROI);
params.UseROI          = useROI;
params.Model           = modelname;
params.Threshold       = double(userInput.Threshold);
params.MinSize         = double(userInput.MinSize);
params.MaxSize         = double(userInput.MaxSize);
params.SelectStrongest = logical(userInput.SelectStrongest);
params.WindowStride    = double(userInput.WindowStride);
params.NumScaleLevels  = double(userInput.NumScaleLevels);
params.NumApprox       = params.NumScaleLevels - 1;

% Get model and extract additional parameters
model = getModel(params);

detector = model.clf;

% Channel related parameters
pPyramid = model.opts.pPyramid;
params.ModelSize          = model.opts.modelDs;
params.ModelSizePadded    = model.opts.modelDsPad;
params.Shrink             = pPyramid.pChns.shrink;
params.ChannelPadding     = pPyramid.pad;
params.Lambdas            = pPyramid.lambdas;
params.SmoothChannels     = pPyramid.smooth;
params.PreSmoothColor     = pPyramid.pChns.pColor.smooth;
params.NumUpscaledOctaves = pPyramid.nOctUp;

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

%--------------------------------------------------------------------------
% Issue warning if sz < min size or sz < model size.
%--------------------------------------------------------------------------
function checkImageSizes(sz, userInput, wasMinSizeSpecified, modelSize, minSizeID, modelID)
if wasMinSizeSpecified
    if any(sz < userInput.MinSize)
        warning(message(minSizeID, ...
            printSizeVector(sz),...
            printSizeVector(userInput.MinSize)));
    end
else
    if any(sz < modelSize)
        warning(message(modelID, ...
            printSizeVector(sz),...
            printSizeVector(modelSize)));
    end
end

%--------------------------------------------------------------------------
function vstr = printSizeVector(v)
vstr = sprintf('[%d %d]',v(1),v(2));
    
%--------------------------------------------------------------------------
% Return minimum size for a given model name.
%--------------------------------------------------------------------------
function sz = getModelSize(modelname)

switch modelname
    case 'caltech-50x21'
        sz = [50 21];       
        
    case 'inria-100x41'
        sz = [100 41];        
end

%--------------------------------------------------------------------------
function checkImage(I)

vision.internal.inputValidation.validateImage(I, 'I', 'rgb');

%--------------------------------------------------------------------------
function checkMinSize(minSize, modelSize)

checkSize(minSize, 'MinSize');

% validate that MinSize is greater than or equal to the minimum
% object size used to train the classification model
coder.internal.errorIf(any(minSize < modelSize) , ...
    'vision:ObjectDetector:minSizeLTTrainingSize', ...
    modelSize(1),modelSize(2));

%--------------------------------------------------------------------------
function valid = checkModel(model)
valid = validatestring(model,{'inria-100x41','caltech-50x21'},...
    mfilename, 'Model');

%--------------------------------------------------------------------------
function checkThreshold(threshold)

validateattributes(threshold,{'numeric'},...
    {'nonempty','nonsparse','scalar','real','finite'}, ...
    mfilename, 'Threshold');

%--------------------------------------------------------------------------
function checkStride(stride)

validateattributes(stride,{'numeric'},...
    {'nonempty','nonsparse','real','finite','positive','scalar','integer'},...
    mfilename, 'WindowStride');

%--------------------------------------------------------------------------
function checkSelectStrongest(strongest)
vision.internal.inputValidation.validateLogical(strongest,'SelectStrongest')

%--------------------------------------------------------------------------
function checkMaxSize(maxSize, modelSize)

checkSize(maxSize, 'MaxSize');

% validate the MaxSize is greater than the model size when
% MinSize is not specified
coder.internal.errorIf(any(modelSize >= maxSize) , ...
    'vision:ObjectDetector:modelMinSizeGTMaxSize', ...
    modelSize(1),modelSize(2));

%--------------------------------------------------------------------------
function checkSize(sz, name)
validateattributes(sz,{'numeric'},...
    {'nonempty','nonsparse','real','finite','integer','positive','size',[1,2]},...
    mfilename,name);

%--------------------------------------------------------------------------
function checkNumScaleLevels(NumScaleLevels)
classes = {'numeric'};
validateattributes(NumScaleLevels,classes,...
    {'nonempty','nonsparse','scalar','real','integer','finite','positive'},...
    mfilename,'NumScaleLevels');

%--------------------------------------------------------------------------
function default = getParameterDefaults()

default.Model = 'inria-100x41';
default.Threshold           = -1;
default.WindowStride        = 4;
default.NumScaleLevels      = 8;
default.MinSize             = getModelSize(default.Model);
default.MaxSize             = [];
default.SelectStrongest     = true;
