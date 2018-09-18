function frcnn = fastRCNN(layers, varargin)
% frcnn = fastRCNN(network, N) returns a Fast R-CNN object detection
% network. The input network, a SeriesNetwork object, is modified by adding
% an ROI pooling layer and the required classification and regression
% output layers to support N object classes.
%
% frcnn = fastRCNN(layers) returns a Fast R-CNN object detection network
% by adding an ROI pooling layer and the required output layers to
% support classifying N object classes, where N equal the number of object
% classes in the final classification output layer minus 1. It is assumed
% that the classification layer already includes a background class.
%
% Notes
% -----
% * Average pooling layers are replaced by ROI average pooling layers.
% * Max pooling layers are replaced by ROI max pooling layers.
% * The last pooling layer in layers is replaced by an ROI Pooling
%   layer, if one exists. Alternatively, you may add the ROI pooling layer
%   to your input layers prior to calling fastRCNN. Do this to control
%   exactly where an ROI max pooling layer is inserted.

% Transform series network into fast r-cnn network as follows according to:
%
% Girshick, Ross. "Fast r-cnn." Proceedings of the IEEE International
% Conference on Computer Vision. 2015.
%
%
% The following describes the action taken based on the input:
% 
% Input          Action-(ROI Pool)  Action-(FC layer)   Action-(Reg layer)
% -----          -----------------  -----------------   ------------------
% SeriesNetwork     A1                   A2                    A3
% Layers            A4                   A5                    A6
%
% Actions
% -------
% A1 - replace last max or avg pooling layer with an roi max/avg pooling layer
% A2 - replace FC layer with on that can support N + 1 object classes.
% A3 - add regression layers at layer before last FC layer.
% A4 - replace last max or avg pooling layer, if required.
% A5 - no-op. Final FC layer left as-is.
% A6 - add regression layer at the layer before the last FC layer.

isNetwork = isa(layers, 'SeriesNetwork');
if isNetwork   
    narginchk(2,2);
else
    narginchk(1,1);
end

numClasses = iParseInputs(layers, varargin{:});

if isNetwork   
    layers = layers.Layers;
end

if isNetwork
    
    if iHasClassificationLayers(layers)
           
        newFCLayer = fullyConnectedLayer(numClasses + 1, 'Name', 'fc_detection');
        
        % Replace last 3 layers.
        layers = layers(1:end-3);
        layers(end+1) = newFCLayer;
        layers(end+1) = softmaxLayer();
        layers(end+1) = classificationLayer();
    else
        error(message('vision:rcnn:noClassificationLayers'));
    end
end

% Get the internal layers
internalLayers = nnet.internal.cnn.layer.util.ExternalInternalConverter.getInternalLayers(layers);

% Initialize layers so that the input size of all the layers is known. This
% information is required to set the GridSize of the ROI Pooling layer. The
% GridSize must match the size of the layer that follows the ROI Pooling
% layer.
internalLayers = nnet.internal.cnn.layer.util.inferParameters(internalLayers);

idx = vision.internal.cnn.layer.util.findROIPoolingLayer(internalLayers);
if isempty( idx )
    needsROIPoolingLayer = true;
else
    needsROIPoolingLayer = false;
end

if needsROIPoolingLayer
    
    roiIdx = iFindLastMaxPoolingLayer(internalLayers);
    
    if isempty(roiIdx)
        error(message('vision:rcnn:noMaxPoolingLayer'));
    end        
        
    % Get size of output size of the max pooling layer. The ROI pooling
    % layer's GridSize must be set to this value.
    outputSize = iOutputSize(internalLayers, roiIdx);
    gridSize   = outputSize(1:2);
    
    if isa(internalLayers{roiIdx}, 'nnet.internal.cnn.layer.MaxPooling2D')
        internalLayers{roiIdx} = vision.internal.cnn.layer.ROIMaxPooling2DLayer('roi pooling layer', gridSize);
    else
        internalLayers{roiIdx} = vision.internal.cnn.layer.ROIAveragePooling2DLayer('roi pooling layer', gridSize);
    end
            
    % Keep a memento of the replaced pooling layer. This is used to convert
    % FastRCNN back into a SeriesNetwork.
    internalLayers{roiIdx}.PoolingLayer = layers(roiIdx);
end

% Add regression layers
fc_reg = fullyConnectedLayer(4 * (numClasses), 'Name', 'fc_reg',...
    'WeightLearnRateFactor', 20, ...
    'BiasLearnRateFactor', 20, ...
    'WeightL2Factor', 1,...
    'BiasL2Factor', 1);

boxRegressionLayer = vision.cnn.layer.BoundingBoxRegressionOutputLayer(...
    vision.internal.cnn.layer.SmoothL1Loss('',[]));

regLayers = [
    fc_reg
    boxRegressionLayer];

% Initialize the reg layers from the branch point ( the output
% of layer(branchPoint) is the input to the first reg layer.
branchLayerIdx = numel(internalLayers)-3;

% create layer map to go from internal to external layers
layersMap = nnet.internal.cnn.layer.util.InternalExternalMap(...
    [layers; regLayers; ...
    iCreateDefaultROIMaxPoolingLayer(); iCreateDefaultROIAveragePoolingLayer] );

internalRegLayers = nnet.cnn.layer.Layer.getInternalLayers(regLayers);

% Get size of output size of the branching layer.
outputSize = iOutputSize(internalLayers, branchLayerIdx);

internalRegLayers = vision.internal.cnn.inferParametersGivenInputSize(...
    internalRegLayers, outputSize);

externalLayers    = layersMap.externalLayers(internalLayers);
externalRegLayers = layersMap.externalLayers(internalRegLayers);
frcnn = vision.cnn.FastRCNN(externalLayers, externalRegLayers, branchLayerIdx);

% 
function sz = iOutputSize(internalLayers, layerID)
% Return the size of a layers output.
sz = internalLayers{1}.InputSize;
for i = 2:layerID
    sz = internalLayers{i}.forwardPropagateSize(sz);
end

%
function numClasses = iParseInputs(layers, varargin)

if isa(layers, 'SeriesNetwork')    
    numClasses = iParseNetworkInput(layers, varargin{:});   
elseif isa(layers, 'nnet.cnn.layer.Layer')
    numClasses = iParseLayerInput(layers, varargin{:});    
end

%
function numClasses = iParseNetworkInput(network, varargin)
p = inputParser;
p.addRequired('network')
p.addRequired('numClasses');
p.parse(network, varargin{:});

numClasses = p.Results.numClasses;

validateattributes(numClasses, {'numeric'}, ...
    {'positive', '>=', 1, 'real', 'nonsparse', 'finite'}, ...
    mfilename, 'numClasses');
 
%
function numClasses = iParseLayerInput(layers, varargin)
p = inputParser;
p.addRequired('layers')
p.parse(layers, varargin{:});

if ~iHasClassificationLayers(layers)       
    error(message('vision:rcnn:noClassificationLayers'));      
end

numClasses = layers(end-2).OutputSize - 1; % assume one of the classes is the background class.

%--------------------------------------------------------------------------
function rp = iCreateDefaultROIMaxPoolingLayer()
% Create default roi pooling layer for creating layer map.
rp = vision.cnn.layer.ROIMaxPooling2DLayer(...
    vision.internal.cnn.layer.ROIMaxPooling2DLayer(''));

%--------------------------------------------------------------------------
function rp = iCreateDefaultROIAveragePoolingLayer()
% Create default roi pooling layer for creating layer map.
rp = vision.cnn.layer.ROIAveragePooling2DLayer(...
    vision.internal.cnn.layer.ROIAveragePooling2DLayer(''));

%--------------------------------------------------------------------------
function [idx] = iFindLastMaxPoolingLayer(internalLayers)
idx = find(...
    cellfun( @(x)isa(x,'nnet.internal.cnn.layer.MaxPooling2D')...
    || isa(x,'nnet.internal.cnn.layer.AveragePooling2D'), ...
    internalLayers), 1, 'last');

%--------------------------------------------------------------------------
function tf = iHasClassificationLayers(layers)
if numel(layers) >= 3 ...
        && isa(layers(end),   'nnet.cnn.layer.ClassificationOutputLayer')...
        && isa(layers(end-1), 'nnet.cnn.layer.SoftmaxLayer')...
        && isa(layers(end-2), 'nnet.cnn.layer.FullyConnectedLayer')
    
    tf = true;
else
    tf = false;
end

