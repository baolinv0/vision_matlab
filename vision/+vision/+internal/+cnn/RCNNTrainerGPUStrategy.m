classdef RCNNTrainerGPUStrategy < nnet.internal.cnn.TrainerExecutionStrategy
   % TrainerGPUStrategy   Execution stategy for running the Trainer on the
   % GPU
   
   %   Copyright 2016 The Mathworks, Inc.
   
    methods
       
        function Y = environment(~, X)
            Y = gpuArray(X);
        end        
        
        function [avgI, numImages] = computeAccumImage(~, data, augmentations)
            data.start();
            avgI = gpuArray(0);
            numImages = 0;
            while ~data.IsDone
                X = data.next();
                X = X{1};
                X = apply(augmentations, X);
                X = gpuArray(double(X));
                avgI = avgI + sum(X, 4);
                numImages = numImages + size(X,4);
            end
        end
        
    end
    
end