classdef Crop2DCenterCropStrategy < nnet.internal.cnn.layer.util.Crop2DManualCropStrategy
    % Center crop.
    
    % Copyright 2017 The MathWorks, Inc.
    methods
       
        %------------------------------------------------------------------
        function [rows, cols] = cropWindow(~, sz, outputSize)
            % Position crop window in center of feature map of size sz.
            centerX = floor(sz(1:2)/2 + 1);
            centerWindow = floor(outputSize/2 + 1);
            
            offset = centerX - centerWindow + 1;
            
            R = offset(1);
            C = offset(2);
            
            H = outputSize(1);
            W = outputSize(2);
            
            rows = R:(R + H - 1);
            cols = C:(C + W - 1);
            
        end
    end
end