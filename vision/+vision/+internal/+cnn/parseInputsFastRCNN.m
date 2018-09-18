% input parser for fast r-cnn training.
function [trainingData, frcnn, params] = parseInputsFastRCNN(trainingData, network, options, fname, varargin)

vision.internal.cnn.validation.checkGroundTruth(trainingData, fname);
vision.internal.cnn.validation.checkNetwork(network, fname, 'fastRCNNObjectDetector');
vision.internal.cnn.validation.checkTrainingOptions(options, fname);

env = options.ExecutionEnvironment;
if strcmp(env,'multi-gpu') || strcmp(env,'parallel') 
    error(message('vision:rcnn:unsupportedExeEnv'));
end

nnet.internal.cnn.util.GPUShouldBeUsed(options.ExecutionEnvironment, []);

p = inputParser;
p.addParameter('RegionProposalFcn', @rcnnObjectDetector.proposeRegions);
p.addParameter('UseParallel', vision.internal.useParallelPreference());
p.addParameter('PositiveOverlapRange', [0.5 1]);
p.addParameter('NegativeOverlapRange', [0.1 0.5]); 
p.addParameter('NumStrongestRegions', 2000);
p.addParameter('SmallestImageDimension', []);
p.parse(varargin{:});

userInput = p.Results;

rcnnObjectDetector.checkRegionProposalFcn(userInput.RegionProposalFcn);

useParallel = vision.internal.inputValidation.validateUseParallel(userInput.UseParallel);

vision.internal.cnn.validation.checkOverlapRatio(userInput.PositiveOverlapRange, fname, 'PositiveOverlapRange');
vision.internal.cnn.validation.checkOverlapRatio(userInput.NegativeOverlapRange, fname, 'NegativeOverlapRange');

vision.internal.cnn.validation.checkStrongestRegions(userInput.NumStrongestRegions, fname);

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
    
elseif isa(network, 'fastRCNNObjectDetector')
    params.IsNetwork = false;    
    networkInputSize = network.Network.Layers(1).InputSize;
    
    % Already initialized in trained detector.
    needsZeroCenterNormalization = false;    
end

vision.internal.cnn.validation.checkImageScale(userInput.SmallestImageDimension, networkInputSize, fname);

params.NumClasses = width(trainingData) - 1;
params.PositiveOverlapRange          = double(userInput.PositiveOverlapRange);
params.NegativeOverlapRange          = double(userInput.NegativeOverlapRange);
params.RegionProposalFcn             = userInput.RegionProposalFcn;
params.UsingDefaultRegionProposalFcn = ismember('RegionProposalFcn', p.UsingDefaults);
params.NumStrongestRegions           = double(userInput.NumStrongestRegions);
params.UseParallel                   = useParallel;
params.BackgroundLabel               = vision.internal.cnn.uniqueBackgroundLabel(trainingData);
params.ImageScale                    = double(userInput.SmallestImageDimension);
params.ScaleImage                    = ~isempty(params.ImageScale);
params.ModelName                     = trainingData.Properties.VariableNames{2};

vision.internal.cnn.validation.checkPositiveAndNegativeOverlapRatioDoNotOverlap(params);

numClasses = width(trainingData) - 1;

if isa(network, 'fastRCNNObjectDetector')
    vision.internal.cnn.validation.checkClassNamesMatchGroundTruth(network.ClassNames, trainingData, params.BackgroundLabel);
    frcnn = network.Network;
else
    % Transform input network into Fast R-CNN network.
    if params.IsNetwork
        layers = vision.internal.rcnn.removeAugmentationIfNeeded(network.Layers,{'randcrop','randfliplr'});
        frcnn = vision.internal.cnn.fastRCNN(SeriesNetwork(layers), numClasses);
    else
        % network is an array of layers
        layers = vision.internal.rcnn.removeAugmentationIfNeeded(network, {'randcrop','randfliplr'});
        frcnn = vision.internal.cnn.fastRCNN(layers);
    end
end

if params.ScaleImage || needsZeroCenterNormalization
    imageInfo = vision.internal.cnn.imageInformation(trainingData, networkInputSize, params.UseParallel);
end

% Scale groundtruth if required.
if params.ScaleImage
    % scale ground truth boxes. Images are scaled on-the-fly in the
    % data dispatchers.
     trainingData = vision.internal.cnn.scaleGroundTruthBoxes(...
         trainingData, imageInfo.sizes, params.ImageScale, params.UseParallel);    
end

% set default MinObjectSize if required. This defaults to network min size
params.MinObjectSize = fastRCNNObjectDetector.determineMinBoxSize(frcnn);

% Initialize network normalizations
if needsZeroCenterNormalization
       
    % duplicate per-channel mean into size used by network.
    avgI = repelem(single(imageInfo.avg), ...
        networkInputSize(1), networkInputSize(2), 1);
    
    frcnn = setAverageImage(frcnn, avgI);
    
end
