
% This class defines a custom data dispatcher for training an R-CNN object
% detector.
%
% Copyright 2016 The MathWorks, Inc.
classdef TrainingRegionDispatcher < nnet.internal.cnn.DataDispatcher
    
    properties(SetAccess = private, Dependent)
        % IsDone Is true when the dispatcher has completed one pass over
        %        the dataset.
        IsDone
        
        % NumObservations The number of observations in the dataset.
        NumObservations
        
        % ClassNames Array of class names corresponding to
        %            training data labels.
        ClassNames
        
        % ImageSize  Size of each image to be dispatched.
        ImageSize
        
       
    end
    
    properties(SetAccess = private)
        % ResponseSize   (1x3 int) Size of each response to be dispatched.
        % Not used by this dipatcher as Fast R-CNN is a DAG.
        ResponseSize
        
        % ResponseNames (cellstr) Array of response names. Not used by 
        % by this dispatcher.
        ResponseNames = {};
    end
    
    properties (Dependent)
        % EndOfEpoch    End of epoch strategy
        %
        % Strategy for how to cope with the last mini-batch when the number
        % of observations is not divisible by the number of mini batches.
        %
        % Allowed values: 'truncateLast', 'discardLast'
        EndOfEpoch
        
        % MiniBatchSize Number of elements in a mini batch.
        MiniBatchSize
    end
    
    properties
        % Precision Precision used for dispatched data
        Precision
        
        % RegionReader Object for reading regions from images.
        RegionReader
    end
    
    methods
        
        %------------------------------------------------------------------
        function this = TrainingRegionDispatcher(groundTruth, regionProposals, params)
            
            this.RegionReader = ...
                vision.internal.cnn.fastrcnn.RegionReader(...
                groundTruth, regionProposals, params);
            
            this.Precision = params.precision;
        end
        
        %------------------------------------------------------------------
        function [miniBatchData, miniBatchResponse, miniBatchIndices] = next(this)
            
            [miniBatchData, miniBatchResponse, miniBatchIndices] = ...
                this.RegionReader.readNextBatch();
            
            miniBatchData{1} = this.Precision.cast( miniBatchData{1} );
        end
        
        %------------------------------------------------------------------
        function start(this)                        
            this.RegionReader.start();            
        end
        
        %------------------------------------------------------------------
        function shuffle(this)           
            this.RegionReader.shuffle();
        end
        
        %------------------------------------------------------------------
        function val = get.NumObservations(this)
            val = this.RegionReader.NumObservations;
        end
        
        %------------------------------------------------------------------
        function val = get.ClassNames(this)
            val = this.RegionReader.ClassNames;
        end
        
        %------------------------------------------------------------------
        function val = get.IsDone(this)
            val = this.RegionReader.isDone();
        end
        
        %------------------------------------------------------------------
        function val = get.ImageSize(this)
            val = this.RegionReader.ImageSize;
        end
        
        %------------------------------------------------------------------
        function val = get.EndOfEpoch(this)
            val = this.RegionReader.EndOfEpoch;
        end
        
        %------------------------------------------------------------------
        function val = get.MiniBatchSize(this)
            val = this.RegionReader.MiniBatchSize;
        end
        
        %------------------------------------------------------------------
        function set.MiniBatchSize(this, val)
            this.RegionReader.MiniBatchSize = val;
        end
        
        %------------------------------------------------------------------
        function set.EndOfEpoch(this, val)
            this.RegionReader.EndOfEpoch = val;
        end               
             
    end
end
