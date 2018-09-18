%FastRCNN Object for storing a Fast R-CNN network. 
%
% A FastRCNN object stores the layers that define a convolutional neural
% network with a classification and regression output. The connectivity of
% the Fast R-CNN network is as follows:
%
% Fast R-CNN Network Connectivity
% -------------------------------
%
%   [Layers(1) ... Layers(LayerIndex) ... Layers(end)]
%                         \                        
%                          \
%                           [RegressionLayers(1) ... RegressionLayers(end)]
%
%
% FastRCNN properties:
%   Layers           - Convolutional neural network layers.
%   RegressionLayers - Layers used for regression.
%   LayerIndex       - Index that specifies which element of Layers
%                      connects to the beginning of the RegressionLayers.
%
% FastRCNN methods:
%   toSeriesNetwork - Convert Fast R-CNN network into a SeriesNetwork.
%
% See also fastRCNNObjectDetector, fasterRCNNObjectDetector, 
%          trainFastRCNNObjectDetector, trainFasterRCNNObjectDetector, 
%          SeriesNetwork.

% Copyright 2016 The MathWorks, Inc.
classdef FastRCNN      
    
    properties(Dependent, GetAccess = public, SetAccess = protected)
        %Layers Network layers that make up convolutional neural network
        %       used within the Fast R-CNN network.
        Layers
    end
    
    properties(Transient, Dependent, GetAccess = public, SetAccess = protected)
        %RegressionLayers Network layers that make up the regression branch
        %                 within the Fast R-CNN network.
        RegressionLayers
        
        %LayerIndex Index that specifies which Layer is connected
        %           to the regression layers of the Fast R-CNN Network.
        LayerIndex
    end
    
    properties(Hidden, Dependent, SetAccess = private)                               
        RegLayers                
    end
    
    properties(Hidden, Dependent)
        Scale        
        BranchLayerIdx
        ClassNames
    end
    
    properties(Hidden, Access = private)
        PrivateNetwork        
        LayerMap
    end
    
    properties(Hidden, Access = public, Dependent)
        % InputSize    Size of the network input as stored in the input
        % layer
        InputSize
        
        % Outputsize    Size of the network output as stored in the output
        % layer
        OutputSize
    end
    
    methods        
        function net = toSeriesNetwork(this)
            %toSeriesNetwork Convert a FastRCNN network into a SeriesNetwork.
            %
            % net = toSeriesNetwork(fastRCNN) returns a SeriesNetwork
            % containing the layers in fastRCNN.Layers. This conversion
            % discards the regression layers.
            %
            % This method is useful for using functions such as
            % deepDreamImage from the Neural Network Toolbox to
            % visualize network features.
            %
            % See also SeriesNetwork, deepDreamImage.
            
            internalLayers = nnet.cnn.layer.Layer.getInternalLayers(this.Layers);
            roiPoolingLayerIdx = vision.internal.cnn.layer.util.findROIPoolingLayer(internalLayers);
                              
            layers = this.Layers;
            
            % Used the cached pooling layer to replace roi pooling layer.
            layers(roiPoolingLayerIdx) = internalLayers{roiPoolingLayerIdx}.PoolingLayer;
            
            net = SeriesNetwork(layers);
                        
        end
        
        function layers = get.RegressionLayers(this)
            layers = this.RegLayers;
        end
        
        function idx = get.LayerIndex(this)
            idx = this.BranchLayerIdx;
        end
        
        function val = get.Scale(this)
            val = this.PrivateNetwork.Scale;
        end
        
        function this = set.Scale(this, val)
            this.PrivateNetwork.Scale = val;
        end
        
        function val = get.InputSize(this)
            val = this.PrivateNetwork.Layers{1}.InputSize;
        end
        
        function val = get.OutputSize(this)
            val = this.PrivateNetwork.Layers{end}.NumClasses;
        end
        
        function layers = get.Layers(this)
            layers = this.LayerMap.externalLayers(this.PrivateNetwork.Layers);
        end
        
        function layers = get.RegLayers(this)
            layers = this.LayerMap.externalLayers(this.PrivateNetwork.RegLayers);
        end
        
        function idx = get.BranchLayerIdx(this)
            idx = this.PrivateNetwork.BranchLayerIdx;
        end
        
        function cls = get.ClassNames(this)
            if ~isempty(this.PrivateNetwork)
                cls = this.PrivateNetwork.Layers{end}.ClassNames(:);
            else
                cls = {};
            end
        end
    end
    
    methods(Access = public, Hidden)
        function this = FastRCNN(layers, regLayers, branchLayerIdx)
            
            this.LayerMap = nnet.internal.cnn.layer.util.InternalExternalMap( [layers;regLayers] );
            
            % Retrieve the internal layers
            internalLayers = nnet.cnn.layer.Layer.getInternalLayers(layers);
            
            internalRegLayers = nnet.cnn.layer.Layer.getInternalLayers(regLayers);            
            
            % Create the network
            this.PrivateNetwork = vision.internal.cnn.internalFastRCNNSeriesNetwork(internalLayers, internalRegLayers, branchLayerIdx);                        
        end
        
        % methods to avoid conversion to external layers.
        function n = numelLayers(this)
            n = numel(this.PrivateNetwork.Layers);
        end
        
        function n = numelRegLayers(this)
            n = numel(this.PrivateNetwork.RegLayers);
        end
        
        function scaledBBoxes = scaleBoxes(this, bboxes, imageSize)
            internalLayers = this.PrivateNetwork.Layers;
            idx = vision.internal.cnn.layer.util.findROIPoolingLayer(internalLayers);
            [sx, sy] = vision.internal.cnn.roiScaleFactor(internalLayers(1:idx-1), imageSize);
            scaledBBoxes = vision.internal.cnn.scaleROI(bboxes, sx, sy); 
        end
        
        function this = setScale(this, scale)
            this.PrivateNetwork.Scale = scale;
        end
        
        function featureMapSize = computeFeatureMapSize(this, imageSize)
            internalLayers = this.PrivateNetwork.Layers;
            idx = vision.internal.cnn.layer.util.findROIPoolingLayer(internalLayers);
            
            featureMapSize = imageSize;
            for i = 2:numel(internalLayers(1:idx-1)) % start from 2 to exclude image layer
                featureMapSize = internalLayers{i}.forwardPropagateSize(featureMapSize);
            end

        end
    end
    
    methods(Hidden, Access = public)     
        
        function this = setAverageImage(this, avgI)
            this.PrivateNetwork.Layers{1}.AverageImage = single(avgI);
        end
        
        function Y = internalActivations(this, X, roi, layerID, inputLayerID, varargin)
                      
            % Set desired precision
            precision = nnet.internal.cnn.util.Precision('single');
            
            internalLayers = this.PrivateNetwork.Layers;
            
            layerID = iValidateAndParseLayerID( layerID, internalLayers );
            
            [miniBatchSize, outputAs, executionEnvironment] = iParseAndValidateActivationsInputs( varargin{:} );
            
            dispatcher = iDataDispatcher( X, miniBatchSize, precision );
         
            % Prepare the network for the correct prediction mode
            GPUShouldBeUsed = nnet.internal.cnn.util.GPUShouldBeUsed( executionEnvironment );
            if(GPUShouldBeUsed)
                predictNetwork = this.PrivateNetwork.setupNetworkForGPUPrediction();
            else
                predictNetwork = this.PrivateNetwork.setupNetworkForHostPrediction();
            end
            
            inputSize = iImageSize( dispatcher );
            outputSize = iDetermineLayerOutputSize( internalLayers, layerID, inputSize );
            
            % roi pooling layer's fowardPropagateSizes needs num roi
            outputSize = [outputSize size(roi,1)];
            
            [sz, ~, ~] = iGetOutputSizeAndIndices(...
                outputAs, dispatcher.NumObservations, outputSize);
            
            % pre-allocate output buffer
            Y = precision.cast( zeros(sz) );
            
            if nargin==4
                inputLayerID = 1;
            end
            
            % Use the dispatcher to run the network on the data
            dispatcher.start();
            while ~dispatcher.IsDone
                
                [X, ~, ~] = dispatcher.next();
                
                if(GPUShouldBeUsed)
                    X = gpuArray(X);
                end                
                                
                YChannelFormat = predictNetwork.activations(X, roi, layerID, inputLayerID);
                
                if iscell(YChannelFormat)
                    
                    for n = 1:numel(YChannelFormat)
                        YChannelFormat{n} = gather(YChannelFormat{n});
                        
                    end
                    
                    Y = table( YChannelFormat{:}, ...
                        'VariableNames', {'Classification', 'Regression'} );

                else
                   Y = gather(YChannelFormat);                                                            
                end
                                               
                
            end
            
        end
        
        function out = saveobj(this)            
            out.Layers         = this.Layers;
            out.RegLayers      = this.RegLayers;
            out.BranchLayerIdx = this.BranchLayerIdx;
            out.Version        = 1.0;
        end
    end
    
    methods(Static)
        function this = loadobj(in)
            this = vision.cnn.FastRCNN( in.Layers, in.RegLayers, in.BranchLayerIdx );
        end
    end
end

function layerIdx = iValidateAndParseLayerID(layerIdx, layers)
if ischar(layerIdx)
    name = layerIdx;
    
    [layerIdx, layerNames] = nnet.internal.cnn.layer.Layer.findLayerByName(layers, name);
    
    try
        % pretty print error message. will print available layer names in
        % case of a mismatch.
        validatestring(name, layerNames, 'activations','layer');
    catch Ex
        throwAsCaller(Ex);
    end
    
    % Only 1 match allowed. This is guaranteed during construction of SeriesNetwork.
    assert(numel(layerIdx) == 1);
else
    validateattributes(layerIdx, {'numeric'},...
        {'positive', 'integer', 'real', 'scalar', '<=', numel(layers)}, ...
        'activations', 'layer');
end
end

function outputSize = iDetermineLayerOutputSize(layers, layerIdx, inputSize)
% Determine output size of output layer.
if nargin<3
    inputSize = layers{1}.InputSize;
end
for i = 2:layerIdx
    inputSize = layers{i}.forwardPropagateSize(inputSize);
end
outputSize = inputSize;
end

function iAssertMiniBatchSizeIsValid(x)
if(iIsPositiveIntegerScalar(x))
else
    exception = iCreateExceptionFromErrorID('nnet_cnn:SeriesNetwork:InvalidMiniBatchSize');
    throwAsCaller(exception);
end
end

function sz = iImageSize( x )
% iImageSize   Return the size of x as [H W C] where C is 1 when x is a
% grayscale image.
if iIsDataDispatcher( x )
    sz = x.ImageSize;
else
    sz = [size(x,1) size(x,2) size(x,3)];
end
end


function tf = iIsDataDispatcher(x)
tf = isa(x,'nnet.internal.cnn.DataDispatcher');
end

function tf = iIsPositiveIntegerScalar(x)
tf = all(x > 0) && iIsInteger(x) && isscalar(x);
end

function tf = iIsInteger(x)
tf = isreal(x) && isnumeric(x) && all(mod(x,1)==0);
end

function exception = iCreateExceptionFromErrorID(errorID, varargin)
exception = MException(errorID, getString(message(errorID, varargin{:})));
end

function dispatcher = iDataDispatcher(data, miniBatchSize, precision)
% iDataDispatcher   Use the factory to create a dispatcher.
try
    dispatcher = nnet.internal.cnn.DataDispatcherFactory.createDataDispatcher( ...
        data, [], miniBatchSize, 'truncateLast', precision);
catch 
    dispatcher = nnet.internal.cnn.FourDArrayDispatcher( data, [], miniBatchSize, 'truncateLast', precision );           
end
end

function [miniBatchSize, outputAs, executionEnvironment] = iParseAndValidateActivationsInputs(varargin)
p = inputParser;

defaultMiniBatchSize = iGetDefaultMiniBatchSize();
defaultOutputAs = 'rows';
defaultExecutionEnvironment = 'auto';

addParameter(p, 'MiniBatchSize', defaultMiniBatchSize);
addParameter(p, 'OutputAs', defaultOutputAs);
addParameter(p, 'ExecutionEnvironment', defaultExecutionEnvironment);

parse(p, varargin{:});

iAssertMiniBatchSizeIsValid(p.Results.MiniBatchSize);

miniBatchSize = p.Results.MiniBatchSize;
outputAs = iValidateOutputAs(p.Results.OutputAs);
executionEnvironment = iValidateExecutionEnvironment(p.Results.ExecutionEnvironment, 'activations');
end

function [outputBatchSize, indexFcn, reshapeFcn] = iGetOutputSizeAndIndices(outputAs, numObs, outputSize)
% Returns the output batch size, indexing function, and reshaping function.
% The indexing function provides the right set of indices based on the
% 'OutputAs' setting. The reshaping function reshapes channel
% formatted output to the shape required for the 'OutputAs' setting.
switch outputAs
    case 'rows'
        outputBatchSize = [numObs prod(outputSize)];
        indexFcn = @(i){i 1:prod(outputSize)};
        reshapeFcn = @(y,n)transpose(reshape(y, [], n));
    case 'columns'
        outputBatchSize = [prod(outputSize) numObs];
        indexFcn = @(i){1:prod(outputSize) i};
        reshapeFcn = @(y,n)reshape(y, [], n);
    case 'channels'
        outputBatchSize = [outputSize numObs];
        indices = arrayfun(@(x)1:x, outputSize, 'UniformOutput', false);
        indexFcn = @(i)[indices i];
        reshapeFcn = @(y,~)y;
end
end

function val = iGetDefaultMiniBatchSize
val = 128;
end

function valid = iValidateOutputAs(str)
validChoices = {'rows', 'columns', 'channels'};
valid = validatestring(str, validChoices, 'activations', 'OutputAs');
end

function validString = iValidateExecutionEnvironment(inputString, caller)
validExecutionEnvironments = {'auto', 'gpu', 'cpu'};
validString = validatestring(inputString, validExecutionEnvironments, caller, 'ExecutionEnvironment');
end
