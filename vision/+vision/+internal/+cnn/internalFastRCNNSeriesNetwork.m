classdef internalFastRCNNSeriesNetwork < nnet.internal.cnn.TrainableNetwork
    % SeriesNetwork   Class for a series convolutional neural network
    %
    %   A series network is always composed by an input layer, some middle
    %   layers, an output layer and a loss layer.
    %   Consistency of the layers and their conformity to this scheme has
    %   to be checked outside the network.
    
    %   Copyright 2015-2017 The MathWorks, Inc.
    
    properties
        % Layers    Layers of the networks
        %           (cell array of nnet.internal.cnn.layer.Layer)
        Layers = cell.empty;
        
        RegLayers = cell.empty;
        
        Scale
        
        BranchLayerIdx
    end
    
    properties (Dependent, SetAccess = private)
        % LearnableParameters    Learnable parameters of the networks
        %                        (vector of nnet.internal.cnn.layer.LearnableParameter)
        LearnableParameters
        
        RegLearnableParameters
    end
    
    methods
        function this = internalFastRCNNSeriesNetwork(layers, regLayers, branchLayerIdx)
            % SeriesNetwork     Constructor for SeriesNetwork class
            %
            %   Create a series network with a cell array of
            %   nnet.internal.cnn.layer.Layer
            if nargin > 0
                this.Layers = layers;
                
                this.RegLayers = regLayers;
                
                this.BranchLayerIdx = branchLayerIdx;
            end
        end
        
        function output = predict(this, data)
            % predict   Predict a response based on the input data
            indexOutputLayer = this.indexOutputLayer();
            output = activations(this, data, indexOutputLayer);
        end
        
        function output = activations(this, data, roi, outputLayer, inputLayer)
            
            % Apply transforms to input. These transforms are applied on
            % the CPU prior to moving data to GPU.
            if inputLayer == 1 && iInputLayerHasTransforms(this.Layers{1})
                data = apply(this.Layers{1}.Transforms, data);
            end
            
            if nargin==4
                inputLayer = 1;
            end
            
            output = data;
            
            roiPoolingLayer = vision.internal.cnn.layer.util.findROIPoolingLayer(this.Layers);
            
            if roiPoolingLayer > outputLayer
                % normal series network forward
                for currentLayer = 1:outputLayer
                    output = this.Layers{currentLayer}.predict( output );
                end
            else
                
                % run up to roi pooling layer.
                for currentLayer = inputLayer:roiPoolingLayer-1
                    output = this.Layers{currentLayer}.predict( output );
                end
                
                % execute roi pooling layer
                roioutput = this.Layers{roiPoolingLayer}.predict( output, roi);
                
                % remainder of cls leg up to branch point
                clsOutput = roioutput;
                for currentLayer = roiPoolingLayer+1:this.BranchLayerIdx
                    clsOutput = this.Layers{currentLayer}.predict( clsOutput );
                end
                
                % capture branch point output
                branchPointOutput = clsOutput;
                
                % remainder from branch point till end.
                for currentLayer = this.BranchLayerIdx+1:outputLayer
                    clsOutput = this.Layers{currentLayer}.predict( clsOutput );
                end
                
                if numel(this.RegLayers) > 0
                    % remainder of reg leg from branch point
                    regOutput = branchPointOutput;
                    for currentLayer = 1:numel(this.RegLayers)
                        regOutput = this.RegLayers{currentLayer}.predict( regOutput );
                    end
                    
                    % output as cell
                    output = {clsOutput, regOutput};
                else
                    output = clsOutput;
                end
                
            end
            
        end
        
        
        function [outputs, mem] = forwardPropagation(this, data, roi)
            % forwardPropagation    Forward input data and returns a cell
            % array containing the output of each layer.
            %
            % Inputs
            %   data - a gpuArray containing the data
            % Outputs
            %   layerOutputs - a cell array containing the output of the
            %                  forward function on each layer
            %   memory       - a cell array containing the memory output of
            %                  the forward function on each layer
            indexOutputLayer = this.indexOutputLayer();
            layerOutputs = cell(indexOutputLayer-1,1);
            memory = cell(indexOutputLayer-1,1);
            
            % We can recover GPU memory by gathering the activations and
            % memory cell arrays back to the host.
            function gatherLayerOutputsAndMemory()
                layerOutputs = iGatherGPUCell(layerOutputs);
                memory = iGatherGPUCell(memory);
            end
            
            roiPoolingLayer = vision.internal.cnn.layer.util.findROIPoolingLayer(this.Layers);
            
            
            [layerOutputs{1}, memory{1}] = iExecuteWithStagedGPUOOMRecovery( ...
                @() this.Layers{1}.forward( data ), 2, {@gatherLayerOutputsAndMemory} );
            for currentLayer = 2:roiPoolingLayer-1
                [layerOutputs{currentLayer}, memory{currentLayer}] = ...
                    iExecuteWithStagedGPUOOMRecovery( ...
                    @() this.Layers{currentLayer}.forward( layerOutputs{currentLayer-1} ), ...
                    2, {@gatherLayerOutputsAndMemory} );
            end
            
            % execute roi pooling layer
            [layerOutputs{roiPoolingLayer}, memory{roiPoolingLayer}] = this.Layers{roiPoolingLayer}.forward( layerOutputs{roiPoolingLayer-1}, roi);
            
            % finish remainder
            for currentLayer = roiPoolingLayer+1:indexOutputLayer
                [layerOutputs{currentLayer}, memory{currentLayer}] = ...
                    iExecuteWithStagedGPUOOMRecovery( ...
                    @() this.Layers{currentLayer}.forward( layerOutputs{currentLayer-1} ), ...
                    2, {@gatherLayerOutputsAndMemory} );
            end
            
            % do reg layer, starting from roi pooling layer
            regLayerOutputs = cell(numel(this.RegLayers),1);
            regMemory = cell(numel(this.RegLayers),1);
            
            [regLayerOutputs{1}, regMemory{1}] = this.RegLayers{1}.forward( layerOutputs{this.BranchLayerIdx} );
            for currentLayer =  2:numel(this.RegLayers)
                [regLayerOutputs{currentLayer}, regMemory{currentLayer}] =  this.RegLayers{currentLayer}.forward( regLayerOutputs{currentLayer-1} );
            end
            
            
            % pack data for all layers
            outputs{1} = layerOutputs;
            outputs{2} = regLayerOutputs;
            
            mem{1} = memory;
            mem{2} = regMemory;
        end
        
        function [dxLayers, dwLayers] = backwardPropagation(this, layerOutputs, response, mem)
            % backPropagation   Propagate the response from the last layer
            % to the first returning diffs between outputs and inputs
            %
            % Inputs
            %   layerOutputs - a cell array containing the output of the
            %                  forward function on each layer
            %   response     - expected responses
            %   memory       - a cell array containing the memory output of
            %                  the forward function on each layer
            % Outputs
            %   dxLayers     - cell array containing the derivatives of
            %                  the loss function with respect to the input
            %                  for each layer
            %   dwLayers     - cell array containing the derivatives of
            %                  the loss function with respect to the
            %                  weights for each layer
            
            
            % unpack outputs
            
            % unpack layerOutputs
            clsLayerOutputs = layerOutputs{1};
            regLayerOutputs = layerOutputs{2};
            
            clsResponse = response{1};
            regResponse = response{2};
            
            clsMemory = mem{1};
            regMemory = mem{2};
            
            indexOutputLayer = this.indexOutputLayer();
            
            dxLayers = cell(indexOutputLayer, 1);
            dwLayers = {}; % this will be appended to as we go
            
            % Call backward loss on the output layer
            dxLayers{indexOutputLayer} = ...
                this.Layers{indexOutputLayer}.backwardLoss(clsLayerOutputs{end}, clsResponse);
            
            % Cross entropy normalizes by the size of the fourth dimension.
            % This is prevents Fast R-CNN from training correctly. Undo the
            % normalization here.
            dxLayers{indexOutputLayer} = size(clsLayerOutputs{end},4) * dxLayers{indexOutputLayer};
            
            % CLS back prop up till ROI pooling
            % Call backward on every other layer, except the first since
            % its delta will be empty
            for el = indexOutputLayer-1:-1:this.BranchLayerIdx+1
                [dxLayers{el}, thisDw] = this.Layers{el}.backward(...
                    clsLayerOutputs{el-1}, clsLayerOutputs{el}, dxLayers{el+1}, clsMemory{el});
                % Note that we are building up the gradients backwards
                dwLayers = [thisDw dwLayers]; %#ok<AGROW>
            end
            
            % REG back prop up till ROI pooling
            dxRegLayers = cell(numel(this.RegLayers), 1);
            dwRegLayers = {}; % this will be appended to as we go
            
            % Call backward loss on the output layer
            dxRegLayers{end} = ...
                this.RegLayers{end}.backwardLoss(regLayerOutputs{end}, regResponse{:});
            
            % Call backward on every other layer, except the first since
            % its delta will be empty
            for el = numel(this.RegLayers)-1:-1:2
                [dxRegLayers{el}, thisDw] = this.RegLayers{el}.backward(...
                    regLayerOutputs{el-1}, regLayerOutputs{el}, dxRegLayers{el+1}, regMemory{el});
                % Note that we are building up the gradients backwards
                dwRegLayers = [thisDw dwRegLayers]; %#ok<AGROW>
            end
            
            % do the first reg layer after branch point
            [dxRegLayers{1}, thisDw] = this.RegLayers{1}.backward(...
                clsLayerOutputs{this.BranchLayerIdx}, regLayerOutputs{1}, dxRegLayers{2}, regMemory{1});
            dwRegLayers = [thisDw dwRegLayers];
            
            % sum gradients at branch
            dxLayers{this.BranchLayerIdx+1} = dxRegLayers{1} + dxLayers{this.BranchLayerIdx+1};
            
            % Finish remainder of the CLS
            % Call backward on every other layer, starting at branch layer,
            % except the first since its delta will be empty
            for el = this.BranchLayerIdx:-1:2
                [dxLayers{el}, thisDw] = this.Layers{el}.backward(...
                    clsLayerOutputs{el-1}, clsLayerOutputs{el}, dxLayers{el+1}, clsMemory{el});
                dwLayers = [thisDw dwLayers]; %#ok<AGROW>
            end
            
            % package dx for cls and reg layers
            dxLayers = {dxLayers, dxRegLayers};
            dwLayers = {dwLayers, dwRegLayers};
            
        end
        
        function [gradients, predictions, states, this] = computeGradientsForTraining(this, X, Y, ~, ~)
            % computeGradientsForTraining    Computes the gradients of the
            % loss with respect to the learnable parameters, from the
            % network input and response. This is used during training to
            % avoid the need to store intermediate activations and
            % derivatives any longer than is necessary.
            %
            % Inputs
            %   X                      - an array containing the data
            %   Y                      - expected responses
            %   needsStatefulTraining  - logical scalar for each layer
            %                            marking whether the layer needs
            %                            stateful training or not
            %   propagateState         - logical scalar marking whether
            %                            state needs to be propagated or
            %                            not
            %
            % Output
            %   gradients   - cell array of gradients with one element for
            %                 each learnable parameter array
            %   predictions - the output from the last layer, needs to be
            %                 preserved during training to report progress
            %   states      - cell array of state information needed to
            %                 update layer states after gradient computation
            %   this        - A copy of the network with some or all
            %                 weights potentially gathered back to the host
            
            [outputs,mem] = this.forwardPropagation(X{1},X{2});
            predictions = outputs{1}{end};
            
            states = [];
            [~, gradients] = this.backwardPropagation(outputs, Y, mem);
            
        end
        
        function net = finalizeNetwork(net, data)
            % finalizeNetwork
            X = data{1};
            roi = data{2};
            
            % Work out how far through the network we need to propagate
            needsFinalize = cellfun(@(x) isa(x,'nnet.internal.cnn.layer.Finalizable'), net.Layers);
            lastLayer = find(needsFinalize, 1, 'last');
            assert(~isempty(lastLayer)); % Should never be called if no finalization required
            
            roiPoolingLayer = vision.internal.cnn.layer.util.findROIPoolingLayer(net.Layers);
            
            % Go forward through each layer, calling finalize if required.
            % First layer is input and never needs finalization.
            [Z, ~] = net.Layers{1}.forward( X );
            for currentLayer = 2:roiPoolingLayer-1
                % This layer's input is last layer's output
                X = Z;
                [Z, memory] = net.Layers{currentLayer}.forward(X);
                
                if currentLayer == net.BranchLayerIdx
                    regLayerInput = Z;
                end
                
                if needsFinalize(currentLayer)
                    net.Layers{currentLayer} = finalize(net.Layers{currentLayer}, X, Z, memory);
                end
            end
            
            % do roi pooling layer
            [Z, ~] = net.Layers{roiPoolingLayer}.forward(X,roi);
            
            
            for currentLayer = roiPoolingLayer+1:numel(net.Layers)
                % This layer's input is last layer's output
                X = Z;
                [Z, memory] = net.Layers{currentLayer}.forward(X);
                
                if currentLayer == net.BranchLayerIdx
                    regLayerInput = Z;
                end
                
                if needsFinalize(currentLayer)
                    net.Layers{currentLayer} = finalize(net.Layers{currentLayer}, X, Z, memory);
                end
            end
            
            % reg branches
            X = regLayerInput;
            
            % Work out how far thr;ough the network we need to propagate
            needsFinalize = cellfun(@(x) isa(x,'nnet.internal.cnn.layer.Finalizable'), net.RegLayers);
            if ~any(needsFinalize)
                return
            end
            lastLayer = find(needsFinalize, 1, 'last');
            assert(~isempty(lastLayer)); % Should never be called if no finalization required
            
            % Go forward through each layer, calling finalize if required.
            % First layer is input and never needs finalization.
            [Z, ~] = net.RegLayers{1}.forward( X );
            for currentLayer = 2:lastLayer
                % This layer's input is last layer's output
                X = Z;
                [Z, memory] = net.RegLayers{currentLayer}.forward(X);
                
                if needsFinalize(currentLayer)
                    net.RegLayers{currentLayer} = finalize(net.RegLayers{currentLayer}, X, Z, memory);
                end
            end
            
        end
        
        function loss = loss(this, predictions, response)
            % loss   Calculate the network loss
            loss = this.Layers{this.indexOutputLayer}.forwardLoss(predictions, response{1});
        end
        
        function this = updateLearnableParameters(this, deltas)
            % updateLearnableParameters   Update each learnable parameter
            % by subtracting a delta from it
            currentDelta = 1;
            for el = 1:this.indexOutputLayer
                for param = 1:numel(this.Layers{el}.LearnableParameters)
                    this.Layers{el}.LearnableParameters(param).Value = this.Layers{el}.LearnableParameters(param).Value + deltas{1}{currentDelta};
                    currentDelta = currentDelta + 1;
                end
            end
            
            currentDelta = 1;
            for el = 1:numel(this.RegLayers)
                for param = 1:numel(this.RegLayers{el}.LearnableParameters)
                    this.RegLayers{el}.LearnableParameters(param).Value = this.RegLayers{el}.LearnableParameters(param).Value + deltas{2}{currentDelta};
                    currentDelta = currentDelta + 1;
                end
            end
            
        end
        
        function this = updateNetworkState(this, states, statefulLayers)
            % updateNetworkState   Update network using state information
            % computed during gradient computation
            %
            % Inputs
            %   states                - cell array of state information
            %                           needed to update layer states after
            %                           gradient computation
            %   statefulLayers        - logical scalar for each layer
            %                           marking whether the layer needs
            %                           stateful training or not
            % Output
            %   this                  - network with updated state
            assert(0,'Not supported');
            indexOutputLayer = this.indexOutputLayer();
            for currentLayer = 2:indexOutputLayer-1
                if statefulLayers(currentLayer)
                    this.Layers{currentLayer} = this.Layers{currentLayer}.updateState( states{currentLayer} );
                end
            end
        end
        
        function this = resetNetworkState(this, statefulLayers)
            % resetNetworkState   Reset the stateful layers of the network
            % to their initial states
            %
            % Inputs
            %   statefulLayers        - logical scalar for each layer
            %                           marking whether the layer needs
            %                           stateful training or not
            % Output
            %   this                  - network in initial state
            assert(0,'Not supported');
            indexOutputLayer = this.indexOutputLayer();
            for currentLayer = 2:indexOutputLayer-1
                if statefulLayers(currentLayer)
                    initialState = this.Layers{currentLayer}.computeState([], [], [], false);
                    this.Layers{currentLayer} = this.Layers{currentLayer}.updateState( initialState );
                end
            end
        end
        
        function this = prepareNetworkForTraining(this, executionSettings)
            % prepareNetworkForTraining   Convert the network into a format
            % suitable for training
            for el = 1:this.indexOutputLayer
                this.Layers{el} = this.Layers{el}.prepareForTraining();
            end
            
            for el = 1:numel(this.RegLayers)
                this.RegLayers{el} = this.RegLayers{el}.prepareForTraining();
            end
            
            % Determine whether training should occur on host or GPU
            if ismember( executionSettings.executionEnvironment, {'gpu'} )
                % Don't move data if training in parallel, allow this to
                % happen as training progresses. This ensures we can
                % support clients without GPUs when the cluster has GPUs.
                delayMove = executionSettings.useParallel;
                this = this.setupNetworkForGPUTraining(delayMove);
            else
                this = this.setupNetworkForHostTraining();
            end
        end
        
        function this = prepareNetworkForPrediction(this)
            % prepareNetworkForPrediction   Convert the network into a
            % format suitable for prediction
            for el = 1:this.indexOutputLayer
                this.Layers{el} = this.Layers{el}.prepareForPrediction();
            end
            
            for el = 1:numel(this.RegLayers)
                this.RegLayers{el} = this.RegLayers{el}.prepareForPrediction();
            end
        end
        
        function this = setupNetworkForHostPrediction(this)
            % setupNetworkForHostPrediction   Setup the network to perform
            % prediction on the host
            for el = 1:this.indexOutputLayer
                this.Layers{el} = this.Layers{el}.setupForHostPrediction();
            end
            for el = 1:numel(this.RegLayers)
                this.RegLayers{el} = this.RegLayers{el}.setupForHostPrediction();
            end
        end
        
        function this = setupNetworkForGPUPrediction(this)
            % setupNetworkForGPUPrediction   Setup the network to perform
            % prediction on the GPU
            for el = 1:this.indexOutputLayer
                this.Layers{el} = this.Layers{el}.setupForGPUPrediction();
            end
            for el = 1:numel(this.RegLayers)
                this.RegLayers{el} = this.RegLayers{el}.setupForGPUPrediction();
            end
        end
        
        function this = setupNetworkForHostTraining(this)
            % setupNetworkForHostTraining   Setup the network to train on
            % the host
            for el = 1:this.indexOutputLayer
                this.Layers{el} = this.Layers{el}.setupForHostTraining();
                this.Layers{el} = this.Layers{el}.moveToHost();
            end
            for el = 1:numel(this.RegLayers)
                this.RegLayers{el} = this.RegLayers{el}.setupForHostTraining();
                this.RegLayers{el} = this.RegLayers{el}.moveToHost();
            end
        end
        
        function this = setupNetworkForGPUTraining(this, deferMove)
            % setupNetworkForGPUTraining   Setup the network to train on
            % the GPU. deferMove allows the actual move of data to the GPU
            % to be deferred to happen as training progresses instead of in
            % advance.
            for el = 1:this.indexOutputLayer
                this.Layers{el} = this.Layers{el}.setupForGPUTraining();
                if ~deferMove
                    this.Layers{el} = this.Layers{el}.moveToGPU();
                end
            end
            
            for el = 1:numel(this.RegLayers)
                this.RegLayers{el} = this.RegLayers{el}.setupForGPUTraining();
                if ~deferMove
                    this.RegLayers{el} = this.RegLayers{el}.moveToGPU();
                end
            end
        end
        
        function learnableParameters = get.LearnableParameters(this)
            learnableParameters = [];
            for el = 1:this.indexOutputLayer
                thisParam = this.Layers{el}.LearnableParameters;
                if ~isempty( thisParam )
                    learnableParameters = [learnableParameters thisParam]; %#ok<AGROW>
                end
            end
        end
        
        function learnableParameters = get.RegLearnableParameters(this)
            learnableParameters = [];
            
            for el = 1:numel(this.RegLayers)
                thisParam = this.RegLayers{el}.LearnableParameters;
                if ~isempty( thisParam )
                    learnableParameters = [learnableParameters thisParam]; %#ok<AGROW>
                end
            end
        end
    end
    
    methods (Access = private)
        function indexOutputLayer = indexOutputLayer(this)
            % indexOutputLayer    Return what number is the output layer
            indexOutputLayer = numel(this.Layers);
        end
    end
end

function tf = iInputLayerHasTransforms(layer)
% only input layers have transforms.
tf = isa(layer, 'nnet.internal.cnn.layer.ImageInput');
end

function cellsOnHost = iGatherGPUCell(cellsOnGpu)
cellsOnHost = cellfun(@gather, cellsOnGpu, 'UniformOutput', false);
end

function varargout = iExecuteWithStagedGPUOOMRecovery(computeFun, nOutputs, recoverFuns, layer) %#ok<INUSD>
% iExecuteWithStagedGPUOOMRecovery   Generic utility to execute a function
% in a loop, catching GPU out-of-memory errors and making attempts to
% release GPU memory in a sequence.
nAttempts = numel(recoverFuns) + 1;
for attempt = 1:nAttempts
    try
        [ varargout{1:nOutputs} ] = computeFun();
        % Success - no need to loop
        break;
    catch me
        if attempt < nAttempts && ...
                me.identifier == "parallel:gpu:array:OOM"
            
            % Warn that we are incurring data transfer cost
            nnet.internal.cnn.util.gpuLowMemoryOneTimeWarning();
            
            % Uncomment this line to debug memory management
            %fprintf('Trying memory recovery strategy %d in layer %d\n', attempt, layer);
            recoverFuns{attempt}();
        else
            rethrow(me);
        end
    end
end
end