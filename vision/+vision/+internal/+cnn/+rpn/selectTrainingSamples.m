function samples = selectTrainingSamples(params, varargin)

% varargin is 1 row of the ground truth table.

% cat all multi-class bounding boxes into one M-by-4 matrix.
groundTruth = vertcat(varargin{2:numel(varargin)});

% scale image
if params.ScaleImage
    I = fastRCNNObjectDetector.scaleImage(varargin{1}, params.ImageScale);
else
    I = imread(varargin{1});
end

imageSize = size(I);

inputSize = imageSize;

% find and remove reshape layer.
layers = nnet.cnn.layer.Layer.getInternalLayers(params.Layers);
whichOne = cellfun(@(x)isa(x , 'vision.internal.cnn.layer.RPNReshape'), layers);
layers(whichOne) = [];
for i = 2:numel(layers)
    inputSize = layers{i}.forwardPropagateSize(inputSize);
end

featureMapSize = inputSize;

% generate box candidates
[regionProposals, anchorLocInFeatureMap] = vision.internal.cnn.generateAnchorBoxesInImage(...
    imageSize, featureMapSize, params.MinBoxSizes, params.BoxPyramidScale, params.NumBoxPyramidLevels);

% create anchor Ids for each anchor box. these are required to
% assign each target to the correct box regressor.
numAnchors = cellfun(@(x)size(x,1), regionProposals);
anchorIDs = repelem(1:numel(regionProposals), numAnchors);

% convert from k cells to M-by-2 format.
regionProposals = (vertcat(regionProposals{:}));
anchorIndices = (vertcat(anchorLocInFeatureMap{:}));

% Compute the Intersection-over-Union (IoU) metric between the
% ground truth boxes and the region proposal boxes.
if isempty(groundTruth)
    iou = zeros(0,size(regionProposals,1));
elseif isempty(regionProposals)
    iou = zeros(size(groundTruth,1),0);
else
    
    iou = bboxOverlapRatio(groundTruth, regionProposals, 'union');
end

% Find bboxes that have largest IoU w/ GT.
[v,idx] = max(iou,[],1);

% Select regions to use as positive training samples
lower = params.PositiveOverlapRange(1);
upper = params.PositiveOverlapRange(2);
positiveIndex =  {v >= lower & v <= upper};

if ~any(positiveIndex{1})
    % select box with highest overlap, but not a negative
    lower = params.NegativeOverlapRange(2);
    positiveIndex =  {v >= lower & v <= upper};
end

% Select regions to use as negative training samples
lower = params.NegativeOverlapRange(1);
upper = params.NegativeOverlapRange(2);
negativeIndex =  {v >= lower & v < upper};

% remove boxes that have already have positive anchors
ind = sub2ind(featureMapSize(1:2), anchorIndices(:,2), anchorIndices(:,1));

posind = ind(positiveIndex{1});
invalid = false(size(ind));
for i = 1:numel(posind)
    invalid = invalid | (ind == posind(i));
end
% make sure negative indices don't contain any positives. This
% can happen because anchor boxes are centered a 1 position.
negativeIndex{1}(invalid) = false;

% Create an array that maps ground truth box to positive
% proposal box. i.e. params is the closest grouth truth box to
% each positive region proposal.
if isempty(groundTruth)
    targets = {[]};
else
    G = groundTruth(idx(positiveIndex{1}), :);
    P = regionProposals(positiveIndex{1},:);
    
    % positive sample regression targets
    targets = vision.internal.rcnn.BoundingBoxRegressionModel.generateRegressionTargets(G, P);
    
    targets = {targets'}; % arrange as 4 by num_pos_samples
end

% foregound labels are located @ 1:k. bg labels are @ k+1:2k.
labels = anchorIDs;
labels(negativeIndex{1}) = labels(negativeIndex{1}) + params.NumAnchors;
labels = categorical(labels, 1:(2*params.NumAnchors));

% Sub-sample negative samples to avoid using too much memory.
numPos = sum(positiveIndex{1});
negIdx = find(negativeIndex{1});
numNeg = numel(negIdx);
nidx   = params.RandomSelector.randperm(numNeg, min(numNeg, 5000));

% Pack data as int32 to save memory.
regionProposals = int32([regionProposals(positiveIndex{1}, :); regionProposals(nidx, :)]);
anchorIDs       = {int32([anchorIDs(positiveIndex{1}) anchorIDs(nidx)])};
anchorIndices   = {int32([anchorIndices(positiveIndex{1},:); anchorIndices(nidx,:)])};

labels = {[labels(positiveIndex{1}) labels(nidx)]};

nr = size(regionProposals,1);
positiveIndex = false(nr,1);
negativeIndex = false(nr,1);

positiveIndex(1:numPos) = true;
negativeIndex(numPos+1:end) = true;

positiveIndex = {positiveIndex};
negativeIndex = {negativeIndex};

% return the region proposals, which may have been augmented
% with the ground truth data.
regionProposals = {regionProposals};

featureMapSize = {featureMapSize};

samples = struct('Positive', {positiveIndex}, ...
    'Negative',{negativeIndex}, ...
    'Labels', {labels}, ...
    'RegionProposals', {regionProposals}, ...
    'PositiveBoxRegressionTargets', {targets}, ...
    'AnchorIDs',{anchorIDs}, ...
    'AnchorIndices',{anchorIndices}, ...
    'FeatureMapSize', {featureMapSize});

end
