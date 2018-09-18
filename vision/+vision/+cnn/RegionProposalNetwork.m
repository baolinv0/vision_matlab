%RegionProposalNetwork Object for storing a region proposal network (RPN).
% 
% A RegionProposalNetwork object stores the layers that define a Region
% Proposal Network (RPN). A RPN is a convolutional neural network with a
% classification and regression output. The connectivity of a RPN is as
% follows:
%
% Region Proposal Network Connectivity
% ------------------------------------
%
%   [Layers(1) ... Layers(LayerIndex) ... Layers(end)]
%                         \                        
%                          \
%                           [RegressionLayers(1) ... RegressionLayers(end)]
%
%
% RegionProposalNetwork properties:
%   Layers           - Convolutional neural network layers.
%   RegressionLayers - Layers used for regression.
%   LayerIndex       - Index that specifies which element of Layers
%                      connects to the beginning of the RegressionLayers.
%
% RegionProposalNetwork methods:
%   toSeriesNetwork - Convert RPN network into a SeriesNetwork.
%  
% See also fastRCNNObjectDetector, fasterRCNNObjectDetector, 
%          trainFastRCNNObjectDetector, trainFasterRCNNObjectDetector,
%          SeriesNetwork.

% Copyright 2016 The MathWorks, Inc.
classdef RegionProposalNetwork
    
    properties(Dependent, SetAccess = private)
        %Layers Network layers that make up convolutional neural network
        %       used within the region proposal network (RPN).
        Layers               
    end
        
    properties(Transient, Dependent, GetAccess = public, SetAccess = protected)
       
        %RegressionLayers Network layers that make up the regression branch
        %                 within the region proposal network.
        RegressionLayers
        
        %LayerIndex Index that specifies which Layer is connected
        %           to the regression layers of the region proposal network.
        LayerIndex
    end
    
    properties(Hidden, Dependent, SetAccess = private)      
        
        RegLayers
    end
    
    properties(Hidden, Dependent)        
        BranchLayerIdx
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
            %toSeriesNetwork Convert a RegionProposalNetwork into a SeriesNetwork.
            %
            % net = toSeriesNetwork(rpn) returns a SeriesNetwork containing
            % the layers in rpn.Layers. This conversion discards the
            % regression layers. 
            %
            % This method is useful for using functions such as
            % deepDreamImage from the Neural Network Toolbox to
            % visualize network features.
            %
            % See also SeriesNetwork, maximumLikelihoodImage.
            
            net = SeriesNetwork(this.Layers);
                        
        end
        
        function layers = get.RegressionLayers(this)
            layers = this.RegLayers;
        end
        
        function idx = get.LayerIndex(this)
            idx = this.BranchLayerIdx;
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
    end
    
    methods(Access = public, Hidden)
        function this = RegionProposalNetwork(layers, regLayers, branchLayerIdx)
                             
            this.LayerMap = nnet.internal.cnn.layer.util.InternalExternalMap( [layers;regLayers] );
            % Retrieve the internal layers
            internalLayers = nnet.cnn.layer.Layer.getInternalLayers(layers);
            
            internalRegLayers = nnet.cnn.layer.Layer.getInternalLayers(regLayers);            
            
            % Create the network
            this.PrivateNetwork = vision.internal.cnn.internalRPNSeriesNetwork(internalLayers, internalRegLayers, branchLayerIdx);
        end
        
        % methods to avoid converting to external layers. That kills
        % performance.
        function n = numelLayers(this)
            n = numel(this.PrivateNetwork.Layers);
        end
        
        function n = numelRegLayers(this)
            n = numel(this.PrivateNetwork.RegLayers);
        end
        
        function inputSize = computeFeatureMapSize(this, imageSize)
         
            layers = this.PrivateNetwork.Layers;
            whichOne = cellfun(@(x)isa(x , 'nnet.internal.cnn.layer.RPNReshape'), layers);
            layers(whichOne) = [];
            
            inputSize = imageSize;
            for i = 2:numel(layers)
                inputSize = layers{i}.forwardPropagateSize(inputSize);
            end   
            
        end
    end
    
    methods(Hidden, Access = public)        
        
        function this = setAverageImage(this, avgI)
            this.PrivateNetwork.Layers{1}.AverageImage = single(avgI);
        end
        
        function Y = internalActivations(this, X, layerID, inputLayerID, varargin)
            
            % Set desired precision
            precision = nnet.internal.cnn.util.Precision('single');
            
            if nargin==4
                inputLayerID = 1;
            end
            
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
                       
            [sz, indexFcn, reshapeFcn] = iGetOutputSizeAndIndices(...
                outputAs, dispatcher.NumObservations, outputSize);
            
            % pre-allocate output buffer
            Y = precision.cast( zeros(sz) );
            
            % Use the dispatcher to run the network on the data
            dispatcher.start();
            while ~dispatcher.IsDone
                
                [X, ~, i] = dispatcher.next();
                
                if(GPUShouldBeUsed)
                    X = gpuArray(X);
                end
                
                indices = indexFcn(i);
                
                YChannelFormat = predictNetwork.activations(X, layerID, inputLayerID);
                
                if iscell(YChannelFormat)
                    
                    for n = 1:numel(YChannelFormat)
                        YChannelFormat{n} = {gather(YChannelFormat{n})};
                        
                    end
                    
                    Y = table( YChannelFormat{:}, ...
                        'VariableNames', {'Classification', 'Regression'} );

                else
                    YChannelFormat{i} = gather(YChannelFormat{i});
                                       
                    Y(indices{:}) = reshapeFcn(YChannelFormat, size(roi,1));
                end
                                               
                
            end
            
        end                
        
        function out = saveobj(this)
            out.Version = 1.0;
            out.Layers = this.Layers; % User visible layers
            out.RegLayers = this.RegLayers;
            out.BranchLayerIdx = this.BranchLayerIdx;            
        end
    end
    
    methods(Static)
        function this = loadobj(in)
            this = vision.cnn.RegionProposalNetwork( in.Layers, in.RegLayers, in.BranchLayerIdx );
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
