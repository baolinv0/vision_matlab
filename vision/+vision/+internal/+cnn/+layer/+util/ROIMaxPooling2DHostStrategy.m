classdef ROIMaxPooling2DHostStrategy < nnet.internal.cnn.layer.util.ExecutionStrategy
    % ROIMaxPooling2DHostStrategy  Execution strategy for running roi max
    % pooling on the Host.
    
    %   Copyright 2016-2017 The MathWorks, Inc.
    
    methods
        function [Z, memory] = forward(~, X, roi, gridSize)
            
            % Input ROIs are in [xmin ymin xmax ymax] format.
            
            [~, ~, numChannels, numInBatch] = size(X);
            
            % "image-centric" scheme. Only supports 1 image per
            % batch as M-by-4 input ROI are associated with single image.
            % An item for future expansion is to allow multiple image in a
            % batch (assuming all the images are the same size) and having
            % an association input to specify which ROI belong to which
            % image.
            assert(numInBatch == 1);
            
            numROI = size(roi,1);
            
            width  = roi(:, 3) - roi(:, 1) + 1;
            height = roi(:, 4) - roi(:, 2) + 1;
          
            % allocate output buffer.
            Z = zeros([gridSize numChannels numROI], 'like', X);
            for i = 1:numROI
                
                % set pool size to divide region into blocks
                poolSize(1) = height(i) / gridSize(1);
                poolSize(2) = width(i)  / gridSize(2);
                
                % Discard pixels that do not fit in grid block.
                poolSize = floor(poolSize);
                
                % Can't have pool size less than 1.
                poolSize = max(1, poolSize);
                
                % set stride to have zero overlap between pooling regions
                stride = poolSize;
                
                % crop out enough to compute fixed sized pooling result
                w = poolSize(2) * gridSize(2);
                h = poolSize(1) * gridSize(1);
                
                c1 = roi(i, 1);
                c2 = c1 + w - 1;
                
                r1 = roi(i, 2);
                r2 = r1 + h - 1;
                
                patch = X(r1:r2,c1:c2,:,:);
                
                padding = [0 0];
                
                Z(:,:,:,i) = nnet.internal.cnnhost.poolingMaxForward2D(...
                    patch, ...
                    poolSize(1), poolSize(2), ...
                    padding(1), padding(2), ...
                    padding(1), padding(2), ...
                    stride(1), stride(2));
                              
            end
           
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
                
                dXPatch = nnet.internal.cnnhost.poolingMaxBackward2D(...
                    Z(:,:,:,i) , dZ(:,:,:,i), Xpatch, ...
                    poolSize(1), poolSize(2), ...
                    padding(1), padding(2), ...
                    padding(1), padding(2), ...
                    stride(1), stride(2));
                
                % Accumulate derivatives because ROIs can overlap.
                dX(rowRange, colRange, : , :) = dX(rowRange, colRange, : , :) + dXPatch;
            end
            
            dW = []; % no learnable params.
        end
    end
end
