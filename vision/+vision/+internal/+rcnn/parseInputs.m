% Shared function to parse input for R-CNN family of training functions.
function params = parseInputs(trainingData, network, options, fname, varargin)

vision.internal.cnn.validation.checkGroundTruth(trainingData, fname);
vision.internal.cnn.validation.checkNetwork(network, fname);
vision.internal.cnn.validation.checkTrainingOptions(options, fname);

iCheckExecutionEnvironment(options);

p = inputParser;
p.addParameter('RegionProposalFcn', @rcnnObjectDetector.proposeRegions);
p.addParameter('UseParallel', vision.internal.useParallelPreference());
p.addParameter('PositiveOverlapRange', [0.5 1]);
p.addParameter('NegativeOverlapRange', [0.1 0.5]); 
p.addParameter('NumStrongestRegions', 2000);
p.parse(varargin{:});

userInput = p.Results;

rcnnObjectDetector.checkRegionProposalFcn(userInput.RegionProposalFcn);

useParallel = vision.internal.inputValidation.validateUseParallel(userInput.UseParallel);

vision.internal.cnn.validation.checkOverlapRatio(userInput.PositiveOverlapRange, fname, 'PositiveOverlapRange');
vision.internal.cnn.validation.checkOverlapRatio(userInput.NegativeOverlapRange, fname, 'NegativeOverlapRange');

vision.internal.cnn.validation.checkStrongestRegions(p.Results.NumStrongestRegions, fname);

if isa(network, 'SeriesNetwork')
    params.IsNetwork = true;       
    vision.internal.cnn.validation.checkNetworkLayers(network.Layers);
elseif isa(network, 'nnet.cnn.layer.Layer')    
    params.IsNetwork = false;    
    vision.internal.cnn.validation.checkNetworkLayers(network);
    vision.internal.cnn.validation.checkNetworkClassificationLayer(network, trainingData);    
end

params.NumClasses = width(trainingData) - 1;
params.PositiveOverlapRange          = double(userInput.PositiveOverlapRange);
params.NegativeOverlapRange          = double(userInput.NegativeOverlapRange);
params.RegionProposalFcn             = userInput.RegionProposalFcn;
params.UsingDefaultRegionProposalFcn = ismember('RegionProposalFcn', p.UsingDefaults);
params.NumStrongestRegions           = double(userInput.NumStrongestRegions);
params.UseParallel                   = useParallel;
params.BackgroundLabel               = vision.internal.cnn.uniqueBackgroundLabel(trainingData);

vision.internal.cnn.validation.checkPositiveAndNegativeOverlapRatioDoNotOverlap(params);

%--------------------------------------------------------------------------
function iCheckExecutionEnvironment(options)

env = options.ExecutionEnvironment;

if strcmp(env,'multi-gpu') || strcmp(env,'parallel') 
    error(message('vision:rcnn:unsupportedExeEnv'));
end

nnet.internal.cnn.util.GPUShouldBeUsed(env, []);

