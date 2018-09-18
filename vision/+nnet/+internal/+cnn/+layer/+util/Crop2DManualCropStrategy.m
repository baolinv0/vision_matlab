classdef Crop2DManualCropStrategy < nnet.internal.cnn.layer.util.ExecutionStrategy
    % Crop using [X Y] location.
    
    % Copyright 2017 The MathWorks, Inc.
    properties
        Location
    end
    
    methods
        
        %------------------------------------------------------------------
        function [Z,memory] = forward(this, inputs)
            % unpack inputs
            X         = inputs{1};
            [H, W, ~] = size(inputs{2});
            
            [rows, cols] = cropWindow(this, size(X), [H, W]);
            
            Z = X(rows, cols, :, :);
            memory = [];
        end
        
        %------------------------------------------------------------------
        function [outputGrad, dW] = backward(this, inputs, dZ)
            % route dZ to uncropped regions of X.
            X = inputs{1};
            [H, W, ~] = size(inputs{2});
            
            [rows, cols] = cropWindow(this, size(X), [H, W]);
            
            dX = zeros(size(X), 'like', X);
            dX(rows, cols, :, :) = dZ;
            
            % pack output gradients. There is no gradient w.r.t to second
            % input.
            outputGrad = {dX, 0};
            
            dW = [];
        end
        
        %------------------------------------------------------------------
        function [rows, cols] = cropWindow(this, ~, outputSize)
            % upper-left corner of cropping window.
            R = this.Location(2);
            C = this.Location(1);
            
            rows = R:(R + outputSize(1) - 1);
            cols = C:(C + outputSize(2) - 1);
            
        end
    end
end