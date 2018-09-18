classdef SpatialCrossEntropy < nnet.internal.cnn.layer.ClassificationLayer
    
    properties
        % LearnableParameters   Learnable parameters for the layer
        %   This layer has no learnable parameters.
        LearnableParameters = nnet.internal.cnn.layer.learnable.PredictionLearnableParameter.empty();
        
        % Name (char array)   A name for the layer
        Name
        
        % ClassNames   The names of the classes
        ClassNames
    end
    
    properties (Constant)
        % DefaultName   Default layer's name.
        DefaultName = 'classoutput'
    end
    
    properties (SetAccess = private)
        % HasSizeDetermined   True for layers with size determined.
        HasSizeDetermined
        
        % NumClasses (scalar int)   Number of classes
        NumClasses
    end
    
    
    properties(SetAccess = private, GetAccess = public)
        
        % ClassWeights A vector of weights. Either [] or the same size as
        %              number of class names.
        ClassWeights
        
        % OutputSize A 3 element vector of [H W C] defining the size of the
        %            output.
        OutputSize
        
        % NormalizedClassWeights A vector of weights. Either [] or the same
        %                        size as number of class names.
        NormalizedClassWeights
    end
    
    
    methods
        function this = SpatialCrossEntropy(name, classes, weights, outputSize)
            
            if numel(classes) == 0
                this.NumClasses = [];
            else
                this.NumClasses = numel(classes);
            end   
            
            this.ClassNames = classes;
            
            % Store normalized weights
            this.NormalizedClassWeights = iNormalizeWeights(weights);
            
            this.ClassWeights = weights;
            
            this.OutputSize = outputSize;
            
            this.Name = name;
            
            if isempty(this.OutputSize)
                this.HasSizeDetermined = false;
            else
                this.HasSizeDetermined = true;
            end
            
        end
        
        function outputSize = forwardPropagateSize(~, inputSize)
            % forwardPropagateSize  Output the size of the layer based on
            % the input size
            outputSize = inputSize;
        end
        
        function tf = isValidInputSize(this, inputSize)
            % isValidInputSize   Check if the layer can accept an input of
            % a certain size.
            tf = this.HasSizeDetermined;
            tf = tf && numel(inputSize)==3 && isequal(inputSize(3), this.OutputSize(3));
        end
        
        function this = inferSize(this, inputSize)
            % inferSize    Infer the number of classes based on the input
            this.NumClasses = inputSize(3);
            this.OutputSize = inputSize(1:3);
            this.HasSizeDetermined = true;
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
        
        function loss = forwardLoss(this, Y, T )
            % forwardLoss    Return the cross entropy loss between estimate
            % and true responses averaged by the number of observations.
            % Here the observations include the spatial dimensions.
            %
            % When ClassWeights is not empty, observations are weighted by
            % values specified in ClassWeights. ClassWeights are normalized
            % to sum to 1.
            %
            % Syntax:
            %   loss = layer.forwardLoss( Y, T );
            %
            % Inputs:
            %   Y   Predictions made by network, H-by-W-by-numClasses-by-numObs
            %   T   Targets (actual values), H-by-W-by-numClasses-by-numObs
            
            numObservations = size(Y, 4) * size(Y, 1) * size(Y, 2);
            if ~isempty(this.ClassWeights)
                W = this.classWeights(T);
                loss_i = W .* log(nnet.internal.cnn.util.boundAwayFromZero(Y));
                loss = -sum( sum( sum( sum(loss_i, 3), 1), 2));
            else
                
                loss_i = T .* log(nnet.internal.cnn.util.boundAwayFromZero(Y));
                loss = -sum( sum( sum( sum(loss_i, 3).*(1./numObservations), 1), 2));
            end
            
        end
        
        function dX = backwardLoss( this, Y, T )
            % backwardLoss    Back propagate the derivative of the loss
            % function
            %
            % Syntax:
            %   dX = layer.backwardLoss( Y, T );
            %
            % Inputs:
            %   Y   Predictions made by network, H-by-W-by-numClasses-by-numObs
            %   T   Targets (actual values), H-by-W-by-numClasses-by-numObs
            numObservations = size(Y, 4) * size(Y, 1) * size(Y, 2);
            
            if ~isempty(this.ClassWeights)
                W = this.classWeights(T);
                dX = (-W./nnet.internal.cnn.util.boundAwayFromZero(Y));
            else
                dX = (-T./nnet.internal.cnn.util.boundAwayFromZero(Y)).*(1./numObservations);
            end
            
        end
        
        function W = classWeights(this, T)
            % Assign weight, W(c) to each observation that belongs to
            % class(c). Then normalize all weights to sum to 1.           
            W = T .* this.NormalizedClassWeights;
            W = W ./ (sum(W(:)) + eps(class(W)));
        end
    end
    
end

%--------------------------------------------------------------------------
function wn = iNormalizeWeights(weights)
wn = weights ./  (sum(weights(:)) + eps(class(weights)));
wn = reshape(wn, 1, 1, []);
end