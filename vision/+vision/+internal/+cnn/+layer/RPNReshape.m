classdef RPNReshape < nnet.internal.cnn.layer.Layer
    % Softmax   Implementation of the softmax layer
    
    %   Copyright 2015-2017 The MathWorks, Inc.
    
    properties
        % LearnableParameters   Learnable parameters for the layer
        %   This layer has no learnable parameters.
        LearnableParameters = nnet.internal.cnn.layer.learnable.PredictionLearnableParameter.empty();

        % Name (char array)   A name for the layer
        Name
    end
    
    properties (Constant)
        % DefaultName   Default layer's name.
        DefaultName = 'reshape'
    end
            
    properties(SetAccess = private)
        % HasSizeDetermined   Specifies if all size parameters are set
        %   For a softmax layer, this is always true.
        HasSizeDetermined = true
    end
    
    properties(Access = private)
        % ExecutionStrategy   The execution strategy for this layer
        %   This object 
        ExecutionStrategy
    end
    
    methods
        function this = RPNReshape()
            this.Name = 'reshape';
            
            this.ExecutionStrategy = [];
        end
        
        function Z = predict(~, X)
            % permute & reshape X
            
            sz = size(X);
            
            Z = reshape(X, sz(1),sz(2), 2, []);
            
        end
        
        function [dX, dW] = backward(~, ~, ~, dZ, ~)
            sz = size(dZ);
            dX = reshape(dZ, sz(1), sz(2), []);
            
            dW = [];
        end               
        
        function outputSize = forwardPropagateSize(~, inputSize)
            numAnchors = inputSize(3)/2;
            outputSize = [inputSize(1) inputSize(2) 2 numAnchors];
        end
        
        function this = inferSize(this, ~)
        end
        
        function tf = isValidInputSize(~, inputSize)
            % isValidInputSize   Check if the layer can accept an input of
            % a certain size
            
            % A valid input size has 2 or 3 dimensions, with the first two
            % dimensions representing a vector
            tf = mod(inputSize(3),2) == 0;
        end
        
        function this = initializeLearnableParameters(this, ~)
        end
        
        function this = prepareForTraining(this)
            this.LearnableParameters = nnet.internal.cnn.layer.learnable.TrainingLearnableParameter.empty();
        end
        
        function this = prepareForPrediction(this)
            this.LearnableParameters = nnet.internal.cnn.layer.learnable.PredictionLearnableParameter.empty();
        end
        
        function this = setupForHostPrediction(this)
            % empty on design
        end
        
        function this = setupForGPUPrediction(this)
            % empty by design
        end

	function this = setupForHostTraining(this)
	end

	function this = setupForGPUTraining(this)
	end
    end
end
