function network = trainNetwork(dispatcher, layers, opts, checkpointSaver)

assert( isa(layers, 'vision.cnn.FastRCNN') ...
    || isa(layers, 'vision.cnn.RegionProposalNetwork'));

layerMap = iLayersMap(layers);

internalNetwork = iCreateInternalNetwork(layers);

% Add classnames to last layer
internalNetwork.Layers{end}.ClassNames = dispatcher.ClassNames;

% Initialize learnable parameters
precision = nnet.internal.cnn.util.Precision('single');

internalNetwork = iInitializeLearnableParameters(internalNetwork, precision);

% Create custom trainer
reporter = nnet.internal.cnn.util.VectorReporter();
pd = nnet.internal.cnn.util.ProgressDisplayer(nnet.internal.cnn.util.ClassificationColumns);
pd.Frequency = opts.VerboseFrequency;
reporter.add( pd );

% Add checkpoint saver
if ~isempty(opts.CheckpointPath) 
    checkpointSaver.ConvertorFcn = @(net)iInternalNetworkToExternal(net, layerMap);
    reporter.add( checkpointSaver );
end

% Set desired precision
precision = nnet.internal.cnn.util.Precision('single');

% Set up and validate parallel training
executionSettings = iSetupExecutionEnvironment( opts );

% Create the trainer
trainer = vision.internal.cnn.FastRCNNTrainer(opts, precision, reporter, executionSettings);

% Convert learnable parameters to the correct format
internalNetwork = internalNetwork.prepareNetworkForTraining( executionSettings );

% Train using custom trainer
internalNetwork = trainer.train(internalNetwork, dispatcher);

% Do post-processing work (if any)
internalNetwork = trainer.finalizeNetwork(internalNetwork, dispatcher);

% Convert learnable parameters to the correct format
internalNetwork  = internalNetwork.prepareNetworkForPrediction();
internalNetwork  = internalNetwork.setupNetworkForHostPrediction();

externalLayers   = iExternalLayers(internalNetwork.Layers, layerMap);
externalRegLayers = iExternalLayers(internalNetwork.RegLayers, layerMap);

if isa(layers,'vision.cnn.RegionProposalNetwork')
    network = vision.cnn.RegionProposalNetwork(externalLayers, externalRegLayers, internalNetwork.BranchLayerIdx);
else
    network = vision.cnn.FastRCNN(externalLayers, externalRegLayers, internalNetwork.BranchLayerIdx);
end

end

%-------------------------------------------------------------------------------
function externalNetwork = iInternalNetworkToExternal(internalNetwork, layerMap)
internalNetwork   = internalNetwork.prepareNetworkForPrediction();
externalLayers    = iExternalLayers(internalNetwork.Layers, layerMap);
externalRegLayers = iExternalLayers(internalNetwork.RegLayers, layerMap);

if isa(internalNetwork,'vision.internal.cnn.internalRPNSeriesNetwork')
    externalNetwork = vision.cnn.RegionProposalNetwork(externalLayers, externalRegLayers, internalNetwork.BranchLayerIdx);
else
    externalNetwork = vision.cnn.FastRCNN(externalLayers, externalRegLayers, internalNetwork.BranchLayerIdx);
end

end

%--------------------------------------------------------------------------
function externalLayers = iExternalLayers(internalLayers, layersMap)
externalLayers = layersMap.externalLayers( internalLayers );
end

%--------------------------------------------------------------------------
function layersMap = iLayersMap( layers )
layersMap = nnet.internal.cnn.layer.util.InternalExternalMap( [layers.Layers;layers.RegLayers] );
end

%
function internalNetwork = iCreateInternalNetwork(layers)
internalLayers = nnet.cnn.layer.Layer.getInternalLayers(layers.Layers);
internalRegLayers = nnet.cnn.layer.Layer.getInternalLayers(layers.RegLayers);
if isa(layers, 'vision.cnn.RegionProposalNetwork')
    internalNetwork = vision.internal.cnn.internalRPNSeriesNetwork(internalLayers, internalRegLayers, layers.BranchLayerIdx);
else
    internalNetwork = vision.internal.cnn.internalFastRCNNSeriesNetwork(internalLayers, internalRegLayers, layers.BranchLayerIdx);
end
end

function internalNetwork = iInitializeLearnableParameters(internalNetwork, precision)

for i = 1:numel(internalNetwork.Layers)
    internalNetwork.Layers{i} = internalNetwork.Layers{i}.initializeLearnableParameters(precision);
end

% initialize params in the reg layers
for i = 1:numel(internalNetwork.RegLayers)
    internalNetwork.RegLayers{i} = internalNetwork.RegLayers{i}.initializeLearnableParameters(precision);
end

end

function executionSettings = iSetupExecutionEnvironment( opts )
% Detect CPU/GPU/multiGPU/parallel training, and set up environment
% appropriately
executionSettings = struct( ...
    'executionEnvironment', 'cpu', ...
    'useParallel', false, ...
    'workPerWorker', 1 );
if ismember( opts.ExecutionEnvironment, {'multi-gpu', 'parallel'} )
    [executionSettings.useParallel, executionSettings.workPerWorker] = ...
        iSetupAndValidateParallel( opts.ExecutionEnvironment, opts.WorkPerWorker );
end

GPUShouldBeUsed = nnet.internal.cnn.util.GPUShouldBeUsed( ...
    opts.ExecutionEnvironment );
if GPUShouldBeUsed
    executionSettings.executionEnvironment = 'gpu';
end
end
