function [trainingData, frcnn, rpn, options, params] = parseInputsFasterRCNN(trainingData, network, options, fname, varargin)

vision.internal.cnn.validation.checkGroundTruth(trainingData, fname);
vision.internal.cnn.validation.checkNetwork(network, fname, 'fasterRCNNObjectDetector');

if ~isscalar(options)
    validateattributes(options, {'nnet.cnn.TrainingOptionsSGDM'}, {'numel',4}, fname);
end



for i = 1:numel(options)
    vision.internal.cnn.validation.checkTrainingOptions(options(i), fname);     
end

iCheckExecutionEnvironment(options);

if isscalar(options)
    options = repelem(options, 4, 1);
end

% Train from network or existing detector.
isDetector = false;  

if isa(network, 'SeriesNetwork')
    
    params.IsNetwork = true;
    vision.internal.cnn.validation.checkNetworkLayers(network.Layers);
    networkInputSize = network.Layers(1).InputSize;
    needsZeroCenterNormalization = vision.internal.cnn.needsZeroCenterNormalization(network);
    
elseif isa(network, 'nnet.cnn.layer.Layer')
    
    params.IsNetwork = false;
    vision.internal.cnn.validation.checkNetworkLayers(network);
    vision.internal.cnn.validation.checkNetworkClassificationLayer(network, trainingData);
    networkInputSize = network(1).InputSize;    
    needsZeroCenterNormalization = vision.internal.cnn.needsZeroCenterNormalization(SeriesNetwork(network));
    
elseif isa(network, 'fasterRCNNObjectDetector')
    params.IsNetwork = false; 
    isDetector = true;
    if isempty(network.Network)
        % try RPN network for partial detector checkpoints from training
        % stage 1.
        if isempty(network.RegionProposalNetwork)
            assert(false);
        else
            networkInputSize = network.RegionProposalNetwork.Layers(1).InputSize;            
        end
    else
        networkInputSize = network.Network.Layers(1).InputSize;
    end
    
    % Already initialized in trained detector.
    needsZeroCenterNormalization = false;
end

p = inputParser;
p.addParameter('UseParallel', vision.internal.useParallelPreference());
p.addParameter('PositiveOverlapRange', [0.5 1]);
p.addParameter('NegativeOverlapRange', [0.1 0.5]);
p.addParameter('NumStrongestRegions', 2000);
p.addParameter('BoxPyramidScale', 2);
p.addParameter('NumBoxPyramidLevels', 'auto');
p.addParameter('MinBoxSizes', 'auto');
p.addParameter('SmallestImageDimension', []);

p.parse(varargin{:});

userInput = p.Results;

useParallel = vision.internal.inputValidation.validateUseParallel(userInput.UseParallel);

vision.internal.cnn.validation.checkOverlapRatio(userInput.PositiveOverlapRange, fname, 'PositiveOverlapRange');
vision.internal.cnn.validation.checkOverlapRatio(userInput.NegativeOverlapRange, fname, 'NegativeOverlapRange');

vision.internal.cnn.validation.checkStrongestRegions(userInput.NumStrongestRegions, fname);

vision.internal.cnn.validation.checkImageScale(userInput.SmallestImageDimension, networkInputSize, fname);

userInput.MinBoxSizes = iCheckBoxSizes(userInput.MinBoxSizes, fname);

iCheckPyramidScale(userInput.BoxPyramidScale, fname);

userInput.NumBoxPyramidLevels = iCheckNumPyramidLevels(userInput.NumBoxPyramidLevels, fname);

params.NumClasses = width(trainingData) - 1;
params.PositiveOverlapRange = double(userInput.PositiveOverlapRange);
params.NegativeOverlapRange = double(userInput.NegativeOverlapRange);
params.BoxPyramidScale      = userInput.BoxPyramidScale;
params.NumBoxPyramidLevels  = double(userInput.NumBoxPyramidLevels);
params.MinBoxSizes          = userInput.MinBoxSizes;
params.NumStrongestRegions  = double(userInput.NumStrongestRegions);
params.UseParallel          = useParallel;
params.BackgroundLabel      = vision.internal.cnn.uniqueBackgroundLabel(trainingData);
params.ImageScale           = double(userInput.SmallestImageDimension);
params.ScaleImage           = ~isempty(params.ImageScale);
params.ModelName            = trainingData.Properties.VariableNames{2};

vision.internal.cnn.validation.checkPositiveAndNegativeOverlapRatioDoNotOverlap(params);

if params.ScaleImage || needsZeroCenterNormalization
    imageInfo = vision.internal.cnn.imageInformation(trainingData, networkInputSize, params.UseParallel);        
end

if params.ScaleImage
    trainingData = iScaleGroundTruth(trainingData, imageInfo, params.ImageScale, params.UseParallel);
end

%Create Fast R-CNN networks. Set training stage. 
numClasses = width(trainingData) - 1;

if isa(network, 'fasterRCNNObjectDetector')
            
    frcnn = network.Network;
  
    params.TrainingStage = network.TrainingStage;
    
    if ~isempty(network.ClassNames)
        % checkpointed detector has not gotten to stage 2. skip class name check.    
        vision.internal.cnn.validation.checkClassNamesMatchGroundTruth(...
        network.ClassNames, trainingData, params.BackgroundLabel);    
    end
    
else
    if params.IsNetwork
        layers = vision.internal.rcnn.removeAugmentationIfNeeded(...
            network.Layers,{'randcrop','randfliplr'});
        
        network = SeriesNetwork(layers);
        frcnn = vision.internal.cnn.fastRCNN(network, numClasses);
       
    else
        % input is layer array. Assumes already setup for object detection.
        
        layers = vision.internal.rcnn.removeAugmentationIfNeeded(...
            network,{'randcrop','randfliplr'});
        network = SeriesNetwork(layers);
        frcnn = vision.internal.cnn.fastRCNN(layers);
        
    end
    
    % Start training from beginning.
    params.TrainingStage = 0;
    
end

% Configure the training stages that must be executed. If resuming training
% this will effect from which stage the training resumes.
if params.TrainingStage == 0 || params.TrainingStage > 4
    params.DoTrainingStage = true(1,4);
else
    params.DoTrainingStage = false(1,4);
    params.DoTrainingStage(params.TrainingStage:end) = true;
end


% Set model size based on fast r-cnn network.
params.ModelSize = fastRCNNObjectDetector.determineMinBoxSize(frcnn);

% Pyramid Scale
if isDetector
        
    % Verify the user input matches those set in detector.
    if ~isequal(network.BoxPyramidScale, params.BoxPyramidScale)
        error(message('vision:rcnn:mismatchDetectorPyramidScale'));
    end

end

allBoxes = iAllGroundTruthBoxes(trainingData);

% MinBoxSizes 
if isDetector
    
    if iAutoSelectParameter(userInput.MinBoxSizes)
        
        params.MinBoxSizes = network.MinBoxSizes;
        
    else
           
        params.MinBoxSizes = double(userInput.MinBoxSizes);
        
        if ~isequal(params.MinBoxSizes, network.MinBoxSizes)
            error(message('vision:rcnn:mismatchDetectorBoxSizes'));
        end

    end
else
    
    if iAutoSelectParameter(userInput.MinBoxSizes)
      
        allBoxesPerClass = iGetBoxSizesPerClass(trainingData, params);
        
        params.MinBoxSizes = iRemoveSimilarBoxesBasedOnIoU(allBoxesPerClass);
   
    else      
        
        params.MinBoxSizes = double(userInput.MinBoxSizes);
        
        % check box sizes against model size. box sizes already set above.
        if ~all(all( params.MinBoxSizes >= params.ModelSize ))
            error(message('vision:rcnn:minBoxSizeTooSmall'));
        end

    end
end

% Number of levels in anchor box pyramid
if isDetector
    if iAutoSelectParameter(userInput.NumBoxPyramidLevels)     
            
        params.NumBoxPyramidLevels = network.NumBoxPyramidLevels;
        
    else
        
        params.NumBoxPyramidLevels = double(userInput.NumBoxPyramidLevels);
        
        if ~isequal(params.NumBoxPyramidLevels, network.NumBoxPyramidLevels)
            error(message('vision:rcnn:mismatchDetectorNumPyramidLevels'));
        end
    end
    
    
else
    
    if iAutoSelectParameter(userInput.NumBoxPyramidLevels)
        
        maxSize = max( max( allBoxes(:, [4 3]) ) );
        minSize = min( min( params.MinBoxSizes ) );
        scaleRequired = maxSize ./ minSize;
        
        params.NumBoxPyramidLevels = ceil( log(scaleRequired) / log(params.BoxPyramidScale) ) + 1;
        
    else
        
        params.NumBoxPyramidLevels = double(userInput.NumBoxPyramidLevels);
   
    end
end

% Create RPN network - it requires the box sizes and num pyramid levels
if isa(network, 'fasterRCNNObjectDetector')
            
    rpn = network.RegionProposalNetwork;
    params.LastConvLayerIdx = network.LastSharedLayerIndex;
    
else
    % network should already be a series network.
    assert( isa(network, 'SeriesNetwork'), 'Expected SeriesNetwork');
    
    [rpn, params.LastConvLayerIdx] = vision.internal.cnn.regionProposalNetwork(network, ...
        'MinBoxSizes', params.MinBoxSizes, ...
        'NumBoxPyramidLevels', params.NumBoxPyramidLevels  );
    
end

% Initialize network normalizations
if needsZeroCenterNormalization
       
    % duplicate per-channel mean into size used by network.
    avgI = repelem(single(imageInfo.avg), ...
        networkInputSize(1), networkInputSize(2), 1);
    
    frcnn = setAverageImage(frcnn, avgI);
    rpn   = setAverageImage(rpn, avgI);
end

%--------------------------------------------------------------------------
function sz = iCheckBoxSizes(sz, fname)
if iIsString(sz)
    sz = validatestring(sz, {'auto'}, fname, 'MinBoxSizes');
else
    validateattributes(sz, {'numeric'}, ...
        {'size',[NaN 2], 'real', 'positive', 'nonsparse'}, ...
        fname, 'MinBoxSizes');     
end

%--------------------------------------------------------------------------
function iCheckPyramidScale(scales, fname)
validateattributes(scales, {'numeric'}, ...
    {'scalar', '>=', 1, 'nonempty', 'real', 'nonsparse'}, ...
    fname, 'BoxPyramidScale');

%--------------------------------------------------------------------------
function num = iCheckNumPyramidLevels(num, fname)
if iIsString(num)
    num = validatestring(num, {'auto'}, fname, 'NumBoxPyramidLevels');
else
    validateattributes(num, {'numeric'},...
        {'scalar', '>=', 1, 'real', 'nonsparse', 'nonempty'},...
        fname, 'NumBoxPyramidLevels');
end

%--------------------------------------------------------------------------
function tf = iAutoSelectParameter(val)
tf = iIsString(val) && strcmpi(val, 'auto');

%--------------------------------------------------------------------------
function tf = iIsString(s)
tf = ischar(s) || isstring(s);

%--------------------------------------------------------------------------
function allBoxes = iAllGroundTruthBoxes(groundTruth)
gt = groundTruth{:,2:end};
if iscell(gt)
    allBoxes = vertcat( groundTruth{:,2:end}{:} );
else
    allBoxes = vertcat( groundTruth{:,2:end});
end

%--------------------------------------------------------------------------
function boxesPerClass = iGetAllBoxesPerClass(groundTruth)
boxesPerClass = cell(1,width(groundTruth)-1);
for i = 2:width(groundTruth)
    gt = groundTruth{:,i};
    if iscell(gt)
        boxes = vertcat( gt{:} );
    else
        boxes = vertcat( gt );
    end
    boxesPerClass{i-1} = boxes;
end

%--------------------------------------------------------------------------
function boxSizesPerClass = iGetBoxSizesPerClass(groundTruth, params)

boxesPerClass = iGetAllBoxesPerClass(groundTruth);

boxSizesPerClass = zeros(width(groundTruth)-1,2);
n = width(groundTruth)-1;
for i = 1:numel(boxesPerClass)
    allBoxes = boxesPerClass{i};
    
    % min size based
    minLength = min( min(allBoxes(:,[3 4])) );
    
    % aspect ratio
    ar = allBoxes(:, 3) ./ allBoxes(:, 4);
    medAspectRatio = median(ar);
    
    % box size must also be >= model size
    minModelLength = min(params.ModelSize);
    
    if medAspectRatio < 1
        % height > weight
        w = max(minLength, minModelLength);
        h = w / medAspectRatio;
    else
        % width >= height
        h = max(minLength, minModelLength);
        w = h * medAspectRatio;
    end
    
    boxSizesPerClass(i,:) = round([h w]);
end

% Make all the boxes have the same min length. 
ar = boxSizesPerClass(:,2) ./ boxSizesPerClass(:,1);

% scale class specific boxes so they have the same size
minLength = min( min(boxSizesPerClass) );

% height > width
w = zeros(n,1);
h = zeros(n,1);
idx = ar < 1;

w(idx) = max(minLength, minModelLength);
h(idx) = w(idx) ./ ar(idx);

% width > height
idx = ar >= 1;
h(idx) = max(minLength, minModelLength);
w(idx) = h(idx) .* ar(idx);

boxSizesPerClass = round([h w]);

%--------------------------------------------------------------------------
function out = iRemoveSimilarBoxesBasedOnIoU(boxSizes)
% Only keep box sizes that have IoU <= 0.5. This ensures that the number of
% anchors is as small as possible.

n = size(boxSizes,1);

bboxes = [ones(n,2) fliplr(boxSizes)];

iou = bboxOverlapRatio(bboxes,bboxes);
keep = iou <= 0.5;

keep(eye(n,'like',true)) = true;

% greedily remove boxes
for i = 1:n
    if keep(i,i) 
        % remove box by setting row and column to 0
        keep(~keep(i,:), :) = false;
        keep(:, ~keep(i,:)) = false;
    end
end

out = boxSizes(diag(keep), :);

%--------------------------------------------------------------------------
function groundTruth = iScaleGroundTruth(groundTruth, imageInfo,  imageScale, useParallel)
% Scale groundtruth if required.

% scale ground truth boxes. Images are scaled on-the-fly in the
% data dispatchers.
[groundTruth, ~, boxesRemoved] = vision.internal.cnn.scaleGroundTruthBoxes(...
    groundTruth, imageInfo.sizes, imageScale, useParallel);

% Report which images had boxes removed because of scaling
if any(boxesRemoved)
    files = groundTruth{boxesRemoved,1};
    files = sprintf('%s\n', files{:});
    warning(message('vision:rcnn:boxesRemovedByScaling', files));
end

%--------------------------------------------------------------------------
function iCheckExecutionEnvironment(options)

env = options(1).ExecutionEnvironment;

for i = 2:numel(options)
    if ~strcmp(options(i).ExecutionEnvironment, env)
        error(message('vision:rcnn:inconsistentExeEnv'));
    end
end

if strcmp(env,'multi-gpu') || strcmp(env,'parallel') 
    error(message('vision:rcnn:unsupportedExeEnv'));
end

nnet.internal.cnn.util.GPUShouldBeUsed(env, []);

