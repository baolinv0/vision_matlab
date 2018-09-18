classdef ROIMaxPooling2DLayer < nnet.internal.cnn.layer.Layer
    
    %   Copyright 2016-2017 The MathWorks, Inc.
    
    properties
        % LearnableParameters   Learnable parameters for the layer
        %   This layer has no learnable parameters.
        LearnableParameters = nnet.internal.cnn.layer.learnable.PredictionLearnableParameter.empty();
        
        % Name (char array)   A name for the layer
        Name      
        
        % PoolingLayer Copy of the pooling layer that was replaced.
        PoolingLayer
    end
    
    properties (Constant)
        % DefaultName   Default layer's name.
        DefaultName = 'ROI Pooling'
    end
    
    properties (SetAccess = private)
        % HasSizeDetermined   Specifies if all size parameters are set
        HasSizeDetermined = true;
                
        % GridSize The height and width to divide each ROI. Each grid cell
        % is then max pooled.
        GridSize
    end
    
    properties(Access = protected)
        ExecutionStrategy        
    end              
    
    methods
        function this = ROIMaxPooling2DLayer(name, varargin)
            this.Name = name;                        
            
            if numel(varargin) == 1                
                this.GridSize = varargin{1};
            end
            
            this.ExecutionStrategy = vision.internal.cnn.layer.util.ROIMaxPooling2DHostStrategy();
        end
        
        function Z = predict(this, X, roi)
         
           Z = this.ExecutionStrategy.forward(X, roi, this.GridSize);
           
        end
        
        function [Z, memory] = forward(this, X, roi)
         
           [Z, memory] = this.ExecutionStrategy.forward(X, roi, this.GridSize);
           
        end
        
        function [dX, dW] = backward(this, X, Z, dZ, memory)
            
            [dX, dW] = this.ExecutionStrategy.backward(X, Z, dZ, memory, this.GridSize);           
            
        end       
        
        function outputSize = forwardPropagateSize(this, inputSize)
            % Output size is the grid size by number-of-maps in input.
            outputMaps = inputSize(3);
            outputSize = [this.GridSize outputMaps];
        end
        
        function this = inferSize(this, ~)
            % no-op
        end
        
        function tf = isValidInputSize(this, inputSize)
            % isValidInputSize Check if the layer can accept an input of
            % a certain size.
                                    
            % Input must be at least the size of the grid.
            tf = all(inputSize(1:2) >= this.GridSize);
            
            % TODO once second input is available, check if it is M-by-4.                        
        end
        
        function this = initializeLearnableParameters(this, ~)
            % no-op
        end
        
        function this = prepareForTraining(this)
            this.LearnableParameters = nnet.internal.cnn.layer.learnable.TrainingLearnableParameter.empty();
        end
        
        function this = prepareForPrediction(this)
            this.LearnableParameters = nnet.internal.cnn.layer.learnable.PredictionLearnableParameter.empty();
        end
        
        function this = setupForHostPrediction(this)
            this.ExecutionStrategy = vision.internal.cnn.layer.util.ROIMaxPooling2DHostStrategy();
        end
        
        function this = setupForGPUPrediction(this)
            this.ExecutionStrategy = vision.internal.cnn.layer.util.ROIMaxPooling2DGPUStrategy();
        end
        
        function this = setupForHostTraining(this)
            this.ExecutionStrategy = vision.internal.cnn.layer.util.ROIMaxPooling2DHostStrategy();
        end
        
        function this = setupForGPUTraining(this)
            this.ExecutionStrategy = vision.internal.cnn.layer.util.ROIMaxPooling2DGPUStrategy();
        end
    end
    
    methods(Hidden, Static)
        %--------------------------------------------------------------------------
        function info = computeROIInfo(gridSize, roi)
            width  = roi(:, 3) - roi(:, 1) + 1;
            height = roi(:, 4) - roi(:, 2) + 1;
            
            info = struct('range', [], 'poolSize', [], 'padding', [], 'stride', []);
            
            poolSize = [height width] ./ gridSize;
            poolSize = floor(poolSize);
            poolSize = max(1, poolSize);
            
            w = poolSize(:,2) .* gridSize(2);
            h = poolSize(:,1) .* gridSize(1);
            
            c1 = roi(:, 1);
            c2 = c1 + w - 1;
            
            r1 = roi(:, 2);
            r2 = r1 + h - 1;
            
            info.stride = poolSize; % regions do not overlap.
            info.poolSize = poolSize;
            info.padding = [0 0];
            info.range = [r1 r2 c1 c2];
        end
    end
end

