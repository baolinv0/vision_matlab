classdef RCNNTrainerHostStrategy < nnet.internal.cnn.TrainerExecutionStrategy
   % TrainerHostStrategy   Execution stategy for running the Trainer on the
   % host
   
   %   Copyright 2016 The Mathworks, Inc.
   
    methods
       
        function Y = environment(~, X)
            Y = X;
        end        
        
        function [avgI, numImages] = computeAccumImage(~, data, augmentations)
            data.start();
            avgI = 0;
            numImages = 0;
            while ~data.IsDone
                X = data.next();
                X = X{1};
                X = apply(augmentations, X);
                X = double(X);
                avgI = avgI + sum(X, 4);
                numImages = numImages + size(X,4);
            end
        end
        
    end
    
end