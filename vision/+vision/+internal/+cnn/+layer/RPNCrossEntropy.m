classdef RPNCrossEntropy < nnet.internal.cnn.layer.CrossEntropy
    % RPNCrossEntropy   Cross entropy loss output layer
    
    %   Copyright 2015-2016 The MathWorks, Inc.
     
    
    methods
        function this = RPNCrossEntropy(name, numClasses)
            % Output  Constructor for the layer
            % creates an output layer with the following parameters:
            %
            %   name                - Name for the layer
            %   numClasses          - Number of classes. [] if it has to be
            %                       determined later
            
            this = this@nnet.internal.cnn.layer.CrossEntropy(name, numClasses);
                        
        end
                
        function loss = forwardLoss( ~, Y, T )
            % forwardLoss    Return the cross entropy loss between estimate
            % and true responses averaged by the number of observations
            %
            % Syntax:
            %   loss = layer.forwardLoss( Y, T );
            %
            % Inputs:
            %   Y   Predictions made by network, M-by-N-by-numClasses-by-numAnchors
            %   T   Targets (actual values), M-by-N-by-numClasses-by-numAnchors    
            
            % Observations are encoded in T as non-zero values.
            numObservations = nnz(T);
            
            % sum along numClasses
            loss = sum( T .* log(nnet.internal.cnn.util.boundAwayFromZero(Y)), 3);
            
            % sum all observations and average. Here all the
            % non-observations are also summed, but the loss for those is
            % zero, so it does not contribute.
            loss = -1/numObservations * sum(loss(:));                        
        end
        function dX = backwardLoss( ~, Y, T )
            % backwardLoss    Back propagate the derivative of the loss
            % function
            %
            % Syntax:
            %   dX = layer.backwardLoss( Y, T );
            %
            % Image Inputs:
            %   Y   Predictions made by network, 1-by-1-by-numClasses-by-numObs
            %   T   Targets (actual values), 1-by-1-by-numClasses-by-numObs
            %
            % Vector Inputs:
            %   Y   Predictions made by network,  numClasses-by-numObs-by-seqLength
            %   T   Targets (actual values),  numClasses-by-numObs-by-seqLength
                        
            dX = -T./nnet.internal.cnn.util.boundAwayFromZero(Y);
        end
    end
end