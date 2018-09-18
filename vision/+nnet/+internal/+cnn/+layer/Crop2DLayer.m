classdef Crop2DLayer < nnet.internal.cnn.layer.Layer
    % Internal 2D Crop layer.
    
    % Copyright 2017 The MathWorks, Inc.
    properties
        LearnableParameters = [];
        
        % Name
        Name
    end
    
    properties (Constant)
        % DefaultName Default layer's name
        DefaultName = 'crop'
    end
    
    properties(SetAccess = private)
        % HasSizeDetermined True for layers with size determined.
        HasSizeDetermined = true;
        
        % Mode Either 'centercrop' or 'manual'
        Mode
        
        % Location [X Y] location of cropping window. 'auto' when mode is
        %          'centercrop'.
        Location
        
    end
    
    properties
        ExecutionStrategy
    end
    
    methods
        function this = Crop2DLayer(name, location, mode)
            this.Name = name;
            this.Location = location;
            this.Mode = mode;
            
            if strcmp(this.Mode, 'centercrop')
                this.ExecutionStrategy = nnet.internal.cnn.layer.util.Crop2DCenterCropStrategy();
            else
                this.ExecutionStrategy = nnet.internal.cnn.layer.util.Crop2DManualCropStrategy();
                this.ExecutionStrategy.Location = location;
            end
        end
        
        %------------------------------------------------------------------
        function Z = predict(this, inputs)
            Z = this.ExecutionStrategy.forward(inputs);
        end
        
        %------------------------------------------------------------------
        function  [dX, dW] = backward(this, inputs, ~, dZ, ~)
            [dX, dW] = this.ExecutionStrategy.backward(inputs, dZ);
        end
        
        %------------------------------------------------------------------
        function outputSize = forwardPropagateSize(~, inputSizeInCell)
            
            firstInputSize = inputSizeInCell{1};
            secondInputSize = inputSizeInCell{2};
            
            H = secondInputSize(1);
            W = secondInputSize(2);
            C = firstInputSize(3);
            
            outputSize = [H W C];
        end
        
        %------------------------------------------------------------------
        function this = inferSize(this, varargin)            
        end
        
        %------------------------------------------------------------------
        function TF = isValidInputSize(this, inputSizeInCell)
            % cropping window should be within bounds of first input
            % feature map.
            
            firstInputSize = inputSizeInCell{1};
            secondInputSize = inputSizeInCell{2};
            
            H = secondInputSize(1);
            W = secondInputSize(2);
            
            [rows, cols] = this.ExecutionStrategy.cropWindow(firstInputSize, [H, W]);

            TF = iIsValidInputSize(firstInputSize, H, W, rows, cols);
            
        end              
       
        %------------------------------------------------------------------
        % initializeLearnableParameters    Initialize learnable parameters
        % using their initializer
        function this = initializeLearnableParameters(this, ~)
            % no-op: crop has no learnable parameters.
        end
        
        %------------------------------------------------------------------
        % prepareForTraining   Prepare the layer for training
        function this = prepareForTraining(this)
            % no-op: crop has no learnable parameters.
        end
        
        %------------------------------------------------------------------
        % prepareForPrediction   Prepare the layer for prediction
        function this = prepareForPrediction(this)
            % no-op: crop has no learnable parameters.
        end
        
        %------------------------------------------------------------------
        % setupForHostPrediction   Prepare this layer for host prediction
        function this = setupForHostPrediction(this)
            % empty on purpose.
        end
        
        %------------------------------------------------------------------
        % setupForGPUPrediction   Prepare this layer for GPU prediction
        function this = setupForGPUPrediction(this)
            % empty on purpose.
        end
        
        %------------------------------------------------------------------
        % setupForHostTraining   Prepare this layer for host training
        function this = setupForHostTraining(this)
            % empty on purpose.
        end
        
        %------------------------------------------------------------------
        % setupForGPUTraining   Prepare this layer for GPU training
        function this = setupForGPUTraining(this)
            % empty on purpose.
        end
    end
end

%--------------------------------------------------------------------------
function TF = iIsNotNullWindow(H,W)
TF = H ~= 0 && W ~= 0;
end

%--------------------------------------------------------------------------
function TF = iIsValidInputSize(sz, H, W, rows, cols)

TF = iIsNotNullWindow(H,W) && iIsWithinInputBounds(sz, rows, cols);
end

%--------------------------------------------------------------------------
function TF = iIsWithinInputBounds(inputSize, rows,cols)
TF = (rows(1) >= 1 && rows(end) <= inputSize(1)) ...
    && cols(1) >= 1 && cols(end) <= inputSize(2);
end