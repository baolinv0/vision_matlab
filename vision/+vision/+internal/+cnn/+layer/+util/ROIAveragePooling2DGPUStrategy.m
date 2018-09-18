classdef ROIAveragePooling2DGPUStrategy < nnet.internal.cnn.layer.util.ExecutionStrategy
    % ROIMaxPooling2DGPUStrategy  Execution strategy for running roi max pooling on the GPU
    
    %   Copyright 2016-2017 The MathWorks, Inc.
    
    methods
        function [Z, memory] = forward(~, X, roi, gridSize)
            % On the GPU the number of channels are limited to the CUDA max
            % grid dim size of 65535.
            if size(X,3) > 65535
                error(message('vision:rcnn:unsupportedNumChannelsForROIPooling'));
            end
            
            roiTransposed = roi'; % use 4xM to allow contigous access.
            
            Z = visiongpuROIAvgPoolingForward(X, double(roiTransposed), gridSize(1), gridSize(2));

            % Cache ROI input for use in backward function.  
            memory.roi = roi;
        end             

        function [dX, dW] = backward(~, X, Z, dZ, memory, gridSize)            
            % Input X should be the whole image
            
            % Input Z is the output of the forward, hence it's 4 dim is the
            % number of ROIs.
            numROIs = size(Z,4);
            
            % Pre-allocate dX to be zeros. Pixels that do not overlap an
            % ROI do not contribute to the gradients.
            dX = zeros(size(X), 'like', X);
            
            info = vision.internal.cnn.layer.ROIMaxPooling2DLayer.computeROIInfo(gridSize, memory.roi);
            
            % For each ROI compute the backprop and add it to the
            for i = 1:numROIs
                               
                poolSize = info.poolSize(i,:);
                padding  = info.padding;
                stride   = info.stride(i,:);
                range    = info.range(i,:);
                
                rowRange = range(1):range(2);
                colRange = range(3):range(4);
                Xpatch = X(rowRange, colRange, :, :);
                
                dXPatch = nnet.internal.cnngpu.poolingAverageBackward2D(...
                    Z(:,:,:,i) , dZ(:,:,:,i), Xpatch, ...
                    poolSize(1), poolSize(2), ...
                    padding(1), padding(2), ...
                    padding(1), padding(2), ...
                    stride(1), stride(2));
                
                % Accumulate derivatives because ROIs can overlap.
                dX(rowRange, colRange, : , :) = dX(rowRange, colRange, : , :) + dXPatch;
                
                dW = []; % no learnable params.
            end
        end
    end
end
