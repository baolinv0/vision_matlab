classdef SmoothL1Loss < nnet.internal.cnn.layer.OutputLayer
    % Implements the Smooth L1 Regression loss defined in:
    %
    % Girshick, Ross. "Fast r-cnn." Proceedings of the IEEE International
    % Conference on Computer Vision. 2015.
    
    % Copyright 2016-2017 The MathWorks, Inc.
    
    properties
        % LearnableParameters   Learnable parameters for the layer
        %   This layer has no learnable parameters.
        LearnableParameters = nnet.internal.cnn.layer.learnable.PredictionLearnableParameter.empty();
        
        % Name (char array)   A name for the layer
        Name
        
        % NumResponses
        NumResponses
    end
    
    properties (Constant)
        % DefaultName   Default layer's name.
        DefaultName = 'boxRegression'
    end
    
    properties (SetAccess = private)
        % HasSizeDetermined   True for layers with size determined.
        HasSizeDetermined = true;
    end
    
    methods
        
        function this = SmoothL1Loss(name, numResponses)
            this.Name = name;
            this.NumResponses = numResponses;
            if isempty(numResponses)
                this.HasSizeDetermined = false;
            else
                this.HasSizeDetermined = true;
            end
        end
        
        function this = inferSize(this, inputSize)
            % inferSize    Infer the number of classes based on the input
            
            if ~isValidInputSize(this, inputSize)
                error(message('vision:rcnn:invalidSizeSmoothL1'));
            end
            
            this.NumResponses = inputSize(3);
            this.HasSizeDetermined = true;
        end
        
        function tf = isValidInputSize(~, inputSize)
            % isValidInputSize   Check if the layer can accept an input of
            % a certain size.
            if numel(inputSize) < 3
                tf = false;
            else
                v = inputSize(3);
                
                if v >= 4 || mod(v, 4) == 0
                    tf = true;
                else
                    tf = false;
                    % inputSize must be divisible by 4. num responses is 4 *
                    % numClasses.
                end
            end
        end
        
        function this = initializeLearnableParameters(this, ~)
            % initializeLearnableParameters     no-op since there are no
            % learnable parameters
        end
        
        function this = prepareForTraining(this)
            this.LearnableParameters = nnet.internal.cnn.layer.learnable.TrainingLearnableParameter.empty();
        end
        
        function this = prepareForPrediction(this)
            this.LearnableParameters = nnet.internal.cnn.layer.learnable.PredictionLearnableParameter.empty();
        end
        
        function this = setupForHostPrediction(this)
        end
        
        function this = setupForGPUPrediction(this)
        end
        
        function this = setupForHostTraining(this)
        end
        
        function this = setupForGPUTraining(this)
        end
        
        function outputSize = forwardPropagateSize(~, inputSize)
            % forwardPropagateSize  Output the size of the layer based on
            % the input size
            outputSize = inputSize;
        end
        
        % forwardLoss    Return the loss between the output obtained from
        % the network and the expected output
        %
        % Inputs
        %   anOutputLayer - the output layer to forward the loss thru
        %   Y - the output from forward propagation thru the layer
        %   T - the expected output
        %   C - expected class target (one-hot encoded)
        %
        % Outputs
        %   loss - the loss between Z and T
        function loss = forwardLoss(this, Y, T, C)
            
            numObservations = sum(any(C));
            
            if numObservations == 0
                % no positive samples.
                loss = 0;
                return;
            end
            
            loss = forwardLossPerSample(this, Y, T, C);
            
            % return average loss over observations
            loss = (1/numObservations) * sum(sum(loss));
        end
        
        
        % backwardLoss    Back propagate the derivative of the loss function
        %
        % Inputs
        %   anOutputLayer - the output layer to backprop the loss thru
        %   Y - the output from forward propagation thru the layer
        %   T - the expected output
        %   C - expected class target (one-hot encoded)
        %
        % Outputs
        %   dX - the derivative of the loss function with respect to Y
        function dX = backwardLoss( ~, Y, T, C )
            
            dX = zeros(size(Y),'like',Y);
                        
            X = C .* (Y - T);
            
            one = ones(1.0,'like',X);
            
            % abs(x) < 1
            idx = (X > -one) & (X < one) & C;
            dX(idx) = X(idx);
            
            %
            idx = X >= one;
            dX(idx) = one;
            
            %
            idx = X <= -one;
            dX(idx) = -one;
            
        end
        
        
        function loss = forwardLossPerSample(~, Y, T, C)
            % Return the loss for each sample.
            X = C .* (Y - T);
            
            loss = zeros(size(X), 'like', X);
            
            one     = ones(1.0,'like',X);
            onehalf = cast(0.5,'like',X);
            
            % abs(x) < 1
            idx = (X > -one) & (X < one) & C;
            loss(idx) = 0.5 * X(idx).^2;
            
            % x >= 1 || x <= 1
            idx = ~idx & C;
            loss(idx) = abs(X(idx)) - onehalf;
        end
        
    end
end
