function [network, idx] = regionProposalNetwork(layers, varargin)
% Input is an array of layers or SeriesNetwork

[layers, params] = iParseInputs(layers, varargin{:});

% Get the internal layers   
internalLayers = nnet.cnn.layer.Layer.getInternalLayers(layers);

% Infer layer parameters.
internalLayers = nnet.internal.cnn.layer.util.inferParameters(internalLayers);         

% Transform network into fast r-cnn network
%   1) find conv layer pooling layer
%   2) replace w/ 3x3 conv layer, 1x1 conv layer, softmax
idx = iFindLastConvolutionLayer(internalLayers);

if isempty(idx)
    error('vision:cnn:unableToFindConvLayer',...
        'Creating a region proposal network requires a convolution layer');
end

lastConvLayerOutputSize = iOutputSize(internalLayers, idx);

numFilters = lastConvLayerOutputSize(3);
numAnchors = size(params.MinBoxSizes,1) * params.NumBoxPyramidLevels;

% Add CLS layers
layersToAdd = [convolution2dLayer(3, numFilters,'padding',[1 1],'Name','conv3x3')
    reluLayer()
    convolution2dLayer(1, numAnchors*2,'Name', 'conv1x1')
    ];

layersToAdd = [layersToAdd
    vision.cnn.layer.RPNReshape(vision.internal.cnn.layer.RPNReshape());
    softmaxLayer
    vision.cnn.layer.RPNClassificationLayer(vision.internal.cnn.layer.RPNCrossEntropy('RPN Classification Output', 2))];


internalLayersToAdd =  nnet.cnn.layer.Layer.getInternalLayers(layersToAdd);

% only infer up to softmax. softmax doesn't allow arbitrary outputs.
internalLayersToAdd(1:end-2) = vision.internal.cnn.inferParametersGivenInputSize(internalLayersToAdd(1:end-2), lastConvLayerOutputSize);

internalLayers = [internalLayers(1:idx); internalLayersToAdd];

% branch layer is the relu after conv3x3
branchLayerIdx = numel(internalLayers) - 4;

% Add regression layers
smoothL1 = vision.internal.cnn.layer.SmoothL1Loss('smooth-l1',[]);

regLayers = [ convolution2dLayer(1, numAnchors*4, 'Name', 'conv1x1 box regression (RPN)')
    vision.cnn.layer.BoundingBoxRegressionOutputLayer(smoothL1)];

% create layer map to go from internal to external layers
layersMap = nnet.internal.cnn.layer.util.InternalExternalMap([layers; layersToAdd; regLayers]);

internalRegLayers = nnet.cnn.layer.Layer.getInternalLayers(regLayers);

internalRegLayers = vision.internal.cnn.inferParametersGivenInputSize(internalRegLayers, lastConvLayerOutputSize);

externalLayers    = layersMap.externalLayers(internalLayers);
externalRegLayers = layersMap.externalLayers(internalRegLayers);
network = vision.cnn.RegionProposalNetwork(externalLayers, externalRegLayers, branchLayerIdx);

%--------------------------------------------------------------------------
function idx = iFindLastConvolutionLayer(layers)
idx = find(...
    cellfun( @(x)isa(x,'nnet.internal.cnn.layer.Convolution2D'), ...   
    layers), 1, 'last');

if isa(layers{idx+1}, 'nnet.internal.cnn.layer.ReLU')
    idx = idx + 1;
end

%--------------------------------------------------------------------------
function sz = iOutputSize(internalLayers, layerID)
% Return the size of a layers output.
sz = internalLayers{1}.InputSize;
for i = 2:layerID
    sz = internalLayers{i}.forwardPropagateSize(sz);
end

%--------------------------------------------------------------------------
function [layers, params] = iParseInputs(layers, varargin)

validateattributes(layers,{'SeriesNetwork','nnet.cnn.layer.Layer'}, ...
    {'nonempty'}, mfilename);

isNetwork = isa(layers, 'SeriesNetwork');
if isNetwork   
    layers = layers.Layers;
end

p = inputParser;
p.addParameter('MinBoxSizes', []);
p.addParameter('NumBoxPyramidLevels', 3);

p.parse(varargin{:});

params = p.Results;

