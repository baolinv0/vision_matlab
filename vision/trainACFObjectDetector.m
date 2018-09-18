function detector = trainACFObjectDetector(trainingData, varargin)
%trainACFObjectDetector Train a model for an ACF object detector
%
%  detector = trainACFObjectDetector(trainingData) returns a trained
%  aggregate channel features (ACF) object detector. trainingData is a
%  table with two columns. The first column contains image file names. The
%  images can be grayscale or true color, in any format supported by
%  IMREAD. The second column contains M-by-4 matrices of [x y width height]
%  bounding boxes specifying object locations, e.g, positive instances.
%  Negative instances are automatically collected from images during the
%  training process. To create this table, you can use the imageLabeler 
%  app.
%
%  detector = trainACFObjectDetector(..., Name, Value) specifies
%  additional name-value pair arguments described below:
%
%  'ObjectTrainingSize'    A 2-element vector [height width] specifying  
%                          the size to which objects will be resized 
%                          during the training, or the string 'Auto'. If
%                          'Auto' is used, the function will determine the
%                          size automatically based on the median
%                          width-height ratio of the positive instances.
%                          Increasing the size may improve detection
%                          accuracy, but will also increase training and
%                          detection times.
%
%                          Default: 'Auto'
%
%  'NumStages'             Number of training stages for the iterative
%                          training process. Increasing this number may
%                          produce an improved detector with reduced
%                          training error, at the expense of longer
%                          training time.
%
%                          Default: 4
%
%  'NegativeSamplesFactor' A real-valued scalar which determines the 
%                          number of negative samples used at a stage as 
%                          a multiple of the number of positive samples. 
%                          Typical values range from 1 to 10.
%
%                          Default: 5
%
%  'MaxWeakLearners'       An integer or a vector to specify the maximum 
%                          number of weak learners in the trained detector.
%                          If it is a scalar, it specifies the number for
%                          the last stage. If it is a vector, its length
%                          must be equal to 'NumStages' and it specifies
%                          the number at each stage, typically with
%                          increasing number. The ACF detector uses
%                          boosting algorithm to create an ensemble of weak
%                          learners. Increase this value to improve the
%                          detection accuracy, at the expense of slower
%                          detection performance. Recommended ranges are a
%                          few hundred to a few thousand.
%
%                          Default: 2048
%
%  'Verbose'               Set true to display progress information.
%
%                          Default: true
%  Notes:
%  ------
%  - trainACFObjectDetector performs multiple rounds of bootstrapping if
%  need be. It is expected that it gets slower at the later stages of the
%  iterative process.
%
%  - The function supports parallel computing using
%  multiple MATLAB workers. Enable parallel computing using the 
%  <a href="matlab:preferences('Computer Vision System Toolbox')">preferences dialog</a>.
%
%  - The training process requires a large amount of memory. To avoid
%  running out of memory, use this function on a 64-bit operating system
%  with a sufficient amount of RAM.
%
%  - The returned ACF object detector uses seven channels of features that
%  include luv color space and image gradient at multiple scales.
%
%  Example - Train a stop sign detector
%  ------------------------------------
%  % Load training data
%  load('stopSignsAndCars.mat')
%
%  % Select the ground truth for stop signs
%  stopSigns = stopSignsAndCars(:, 1:2);
%
%  % Add fullpath to image files
%  stopSigns.imageFilename = fullfile(toolboxdir('vision'),'visiondata', ...
%      stopSigns.imageFilename);
%
%  % Train the ACF detector. 
%  acfDetector = trainACFObjectDetector(stopSigns,'NegativeSamplesFactor',2);
%
%  % Test the ACF detector on a test image.
%  img = imread('stopSignTest.jpg');
%
%  [bboxes, scores] = detect(acfDetector, img);
%
%  % Display the detection result
%  for i = 1:length(scores)
%      annotation = sprintf('Confidence = %.1f', scores(i));
%      img = insertObjectAnnotation(img, 'rectangle', bboxes(i,:), annotation);
%  end
%
%  figure
%  imshow(img)
%
% See also acfObjectDetector, peopleDetectorACF, trainRCNNObjectDetector, 
%          trainCascadeObjectDetector, imageLabeler.

% Copyright 2016 The MathWorks, Inc.
%
% References
% ----------
%   Dollar, Piotr, et al. "Fast feature pyramids for object detection."
%   Pattern Analysis and Machine Intelligence, IEEE Transactions on 36.8
%   (2014): 1532-1545.

params = parseInputs(trainingData, varargin{:});
printer = vision.internal.MessagePrinter.configure(params.Verbose);

printer.printMessage('vision:acfObjectDetector:trainBegin');
printer.printMessage('vision:acfObjectDetector:trainStageSummary', ...
    params.NumStages, params.ModelSize(1), params.ModelSize(2));

tStart = tic;

imds = imageDatastore(trainingData{:, 1});
classifier = [];
prevStream = RandStream.setGlobalStream(RandStream('mrg32k3a','Seed',0));

% Collect positive examples
positiveImageSet = vision.internal.acf.sampleWindows(imds, ...
    trainingData{:, 2}, params, true, classifier, printer);

if isempty(positiveImageSet)
    error(message('vision:acfObjectDetector:TooFewPositiveExamples')); 
end

% Compute local decorrelation filters if required
if (length(params.FilterSize) == 2)
    positiveInstances = vision.internal.acf.computeSingleScaleChannels(...
        positiveImageSet, params);
    params.Filters = vision.internal.acf.channelCorrelation(...
        positiveInstances, params.FilterSize(1), params.FilterSize(2));
end

% Compute lambdas
if (isempty(params.Lambdas))
    printer.printMessageNoReturn('vision:acfObjectDetector:trainComputeLambda');
    printer.print('...');

    ds = size(positiveImageSet); 
    ds(1:end-1) = 1;
    siz = size(positiveImageSet);
    nd = ndims(positiveImageSet);
    bounds = cell(1, nd);
    for d = 1 : nd
        bounds{d} = repmat( siz(d)/ds(d), [1 ds(d)] ); 
    end
    ls = vision.internal.acf.scaleChannels(mat2cell(positiveImageSet, bounds{:}), params);
    params.Lambdas = round(ls*10^5)/10^5; 

    printer.printMessage('vision:acfObjectDetector:stepCompletion');
end

% Compute features for positives
printer.printMessageNoReturn('vision:acfObjectDetector:trainComputeFeature');
printer.print('...');

positiveInstances = vision.internal.acf.computeSingleScaleChannels(positiveImageSet, params);
positiveInstances = reshape(positiveInstances, [], size(positiveInstances,4))';
clear positiveImageSet;

printer.printMessage('vision:acfObjectDetector:stepCompletion');

accumNegativeInstances = [];

% Iterate bootstraping and training
for stage = 1 : params.NumStages
    printer.print('--------------------------------------------\n');
    printer.printMessage('vision:acfObjectDetector:trainStageStart', stage);

    % Sample negatives
    negativeImageSet = vision.internal.acf.sampleWindows(imds, ...
        trainingData{:, 2}, params, false, classifier, printer);
    
    if (stage == 1 && isempty(negativeImageSet))
        error(message('vision:acfObjectDetector:TooFewNegativeExamples')); 
    end
    
    if (stage > 1)
        printer.printMessage('vision:acfObjectDetector:ReportNewNegatives', size(negativeImageSet, 4));
    end
    
    printer.printMessageNoReturn('vision:acfObjectDetector:trainComputeFeature');
    printer.print('...');
    
    % Compute features of negative examples
    negativeInstances = vision.internal.acf.computeSingleScaleChannels(negativeImageSet, params);
    clear negativeImageSet;
    negativeInstances = reshape(negativeInstances, [], size(negativeInstances, 4))';
  
    printer.printMessage('vision:acfObjectDetector:stepCompletion');

    % Accumulate negatives from previous stages
    accumNegativeInstances = [accumNegativeInstances; negativeInstances];  %#ok<AGROW>

    total = size(accumNegativeInstances, 1);
    if (params.NumNegativeSamples < total)
        ind = vision.internal.samplingWithoutReplacement(total, params.NumNegativeSamples);
        accumNegativeInstances = accumNegativeInstances(ind, :); 
    end

    printer.printMessageNoReturn('vision:acfObjectDetector:trainAdaBoost', ...
        size(positiveInstances, 1), size(accumNegativeInstances, 1));
    printer.print('...');
    
    % Train boosted classifier. The number of weak learns can be less than
    % the specified number.
    classifier = vision.internal.acf.trainBoostTreeClassifier(...
        accumNegativeInstances, positiveInstances, ...
        params.MaxWeakLearners(stage), params.MaxTreeDepth, params.FracFeatures);
    classifier.hs = classifier.hs + params.CalibrationValue;          

    printer.printMessage('vision:acfObjectDetector:stepCompletion');
    printer.printMessage('vision:acfObjectDetector:reportNumLearners', size(classifier.child, 2));    
end

detector = constructDetector(classifier, params);
RandStream.setGlobalStream(prevStream);

tElapsed = toc(tStart);
printer.print('--------------------------------------------\n');
printer.printMessage('vision:acfObjectDetector:trainEnd', num2str(tElapsed));

function detector = constructDetector(classifier, params)
c = rmfield(classifier, {'errs', 'losses'});
% Parameters used by detector
p.ModelName         = params.ModelName;
p.ModelSize         = params.ModelSize;
p.ModelSizePadded   = params.ModelSizePadded;
p.ChannelPadding    = params.ChannelPadding;
p.NumApprox         = params.NumApprox;
p.Shrink            = params.Shrink;
p.SmoothChannels    = params.SmoothChannels;
p.PreSmoothColor    = params.PreSmoothColor;
p.NumUpscaledOctaves= params.NumUpscaledOctaves;
p.gradient          = params.gradient;
p.hog               = params.hog;
p.Lambdas           = params.Lambdas;
% Training parameters specified by user
p.NumStages         = params.NumStages;
p.NegativeSamplesFactor = params.NegativeSamplesFactor;
p.MaxWeakLearners   = params.MaxWeakLearners;

detector = acfObjectDetector(c, p);

%==========================================================================
function params = parseInputs(trainingData, varargin)

checkGroundTruth(trainingData);

p = inputParser;
p.addParameter('ObjectTrainingSize', 'Auto', @checkObjectTrainingSize);
p.addParameter('NumStages', 4, ...
    @(x)validateattributes(x,{'double'},{'scalar','positive','integer','nonsparse'},mfilename,'NumStages'));
p.addParameter('NegativeSamplesFactor', 5, ...
    @(x)validateattributes(x,{'double'},{'scalar','positive','nonsparse','finite'},mfilename,'NegativeSamplesFactor'));
p.addParameter('MaxWeakLearners', 2048);
p.addParameter('Verbose', true, ...
    @(x)validateattributes(x,{'logical'}, {'scalar','nonempty'},mfilename,'Verbose'));
% Undocumented option:
% Flip ground truth patch from left to right and increase the number of
% positive examples. It may introduce performance degeneration if the
% shape of the object is asymmetric. turn on this option only when
% available positive examples are not enough.
p.addParameter('FlipGroundTruth', false, ...
    @(x)validateattributes(x,{'logical'}, {'scalar','nonempty'},mfilename,'FlipGroundTruth'));
% Turn on/off parallel computing for training.
p.addParameter('UseParallel', vision.internal.useParallelPreference());

p.parse(varargin{:});

checkMaxWeakLearners(p.Results.MaxWeakLearners, p.Results.NumStages);

params.UseParallel = vision.internal.inputValidation.validateUseParallel(p.Results.UseParallel);

params.ModelName             = trainingData.Properties.VariableNames{2};
params.ModelSize             = p.Results.ObjectTrainingSize;   
params.NumStages             = p.Results.NumStages;
params.NegativeSamplesFactor = p.Results.NegativeSamplesFactor;
params.MaxWeakLearners       = p.Results.MaxWeakLearners;
params.Verbose               = p.Results.Verbose;

% Set internal parameters for detection
params.Threshold               = -1;
params.WindowStride            = 4;
params.NumScaleLevels          = 8;

% Set internal parameters for Adaboost
params.CalibrationValue = 0.005;
params.MaxTreeDepth     = 2;
params.FracFeatures     = 1;
params.MinWeight        = 0.01;
    
% Set internal parameters for jittering boxes
params.Flip       = p.Results.FlipGroundTruth; % flip along left-right
params.MaxJitters = 1000;
params.NumSteps   = 0;
params.Bound      = 0;
    
% Set fixed internal parameters for pyramid
params.NumApprox          = params.NumScaleLevels - 1;
params.Shrink             = 4;
params.SmoothChannels     = 1;
params.PreSmoothColor     = 1;
params.NumUpscaledOctaves = 0;

% Parameters for gradient computation
params.gradient.FullOrientation       = 0; % if true compute angles in [0,2*pi) else in [0,pi)
params.gradient.NormalizationRadius   = 5; % normalization radius for gradient
params.gradient.NormalizationConstant = 0.005; % normalization constant for gradient

% Parameters for HOG computation
params.hog.NumBins         = 6; % number of orientation channels
params.hog.Normalize       = 0; % if true perform 4-way hog normalization/clipping
params.hog.CellSize        = params.Shrink; % spatial bin size 
params.hog.Interpolation   = 'Orientation'; % 'Both' for spatial and orientation interpolation
params.hog.FullOrientation = params.gradient.FullOrientation;

% If filter size is provided as [w, n], filters are automatically computed.
params.Filters    = [];
params.FilterSize = [];
params.Lambdas    = [];

% Parameters for sampling windows
bboxes = cell2mat(trainingData{:, 2});
params.NumPositiveSamples  = size(bboxes, 1); % use all ground truth
if params.Flip
    params.NumPositiveSamples = params.NumPositiveSamples * 2;
end
params.NumNegativeSamples  = ceil(params.NegativeSamplesFactor * params.NumPositiveSamples);
params.NumNegativePerImage = 25;
% At most 10000 negative examples are used for one stage
params.NumNegativeAccumulation = max(10000, params.NumNegativeSamples*2);

% Set the size if it is given from the user
if (ischar(params.ModelSize) || isstring(params.ModelSize))
    params.ModelSize = computeModelSize(bboxes);
end
shrink = params.Shrink;
params.ModelSizePadded = ceil(params.ModelSize/shrink)*shrink;
params.ChannelPadding = ceil((params.ModelSizePadded-params.ModelSize)/shrink/2)*shrink;

% Set the bootstrap parameters
if isscalar(params.MaxWeakLearners)
    if params.MaxWeakLearners <= 1024
        params.MaxWeakLearners = repelem(params.MaxWeakLearners, params.NumStages);
    else
        numWeakLearners = zeros(1, params.NumStages);
        base = floor(log2(params.MaxWeakLearners));
        for i = params.NumStages-1:-1:1
            numWeakLearners(i) = max(256, 2^(base-(params.NumStages-i)));
        end
        numWeakLearners(end) = params.MaxWeakLearners;
        params.MaxWeakLearners = numWeakLearners;
    end
end

%==========================================================================
function modelSize = computeModelSize(bboxes)

aspectRatio = bboxes(:, 4)./bboxes(:, 3); % height / width
meanAspectRatio = median(aspectRatio);
minWidth = min(bboxes(:, 3));
minHeight = minWidth * meanAspectRatio;
modelSize = round([minHeight minWidth]);

%==========================================================================
function checkGroundTruth(gt)
validateattributes(gt, {'table'},{'nonempty'}, mfilename, 'trainingData',1);

if width(gt) < 2 
    error(message('vision:ObjectDetector:trainingDataTableWidthLessThanTwo'));
end

%==========================================================================
function tf = checkObjectTrainingSize(objectTrainingSize)
if (ischar(objectTrainingSize) || isstring(objectTrainingSize))
    validatestring(objectTrainingSize, {'Auto'}, mfilename, ...
        'ObjectTrainingSize');
else
    validateattributes(objectTrainingSize,...
        {'numeric'},...
        {'nonempty', 'real', 'nonsparse', 'vector', 'integer', ...
        'positive', 'numel', 2, '>', 3},...
        mfilename, 'ObjectTrainingSize');
end
tf = true;

%==========================================================================
function checkMaxWeakLearners(maxWeakLearners, numStages)
validateattributes(maxWeakLearners,{'double'},...
    {'real','positive','integer','nonsparse'},mfilename,'MaxWeakLearners');

if ~isscalar(maxWeakLearners)
    validateattributes(maxWeakLearners,{'double'},...
        {'real','positive','integer','vector','nonsparse','numel',numStages},...
        mfilename,'MaxWeakLearners');
end
