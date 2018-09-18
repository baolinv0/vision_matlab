% This class implements a mini-batch data dispatcher for training a bbox
% regression model.
classdef BBoxTrainingDataDispatcher < handle
    
    % This class is used to produce training mini-batches composed of image
    % sub-regions.
    %
    % Notes:
    % ------
    % - The training data is provided as a set of images and table of region
    % proposal boxes for each image in the set. During construction of this
    % reader, the PositiveOverlapRange and NegativeOverlapRange parameters are
    % used to create postive and negative training samples to place in the
    % mini-batch.
    %
    % - When creating the mini-batch, regions are cropped out of an image and
    % resized using the RegionResizer object.
    %
    % - One full pass over the set of images is defined as one epoch.
    %
    % - Positive and negative regions are randomly sampled to fill mini-batches
    % using the RandomSelector class. Random sampling ensures we select a
    % different set of regions every epoch.
    
    
    properties
        % PositiveOverlapRange Specify a range of overlap ratios
        PositiveOverlapRange             
        
        % RandomSelector Wrapper class for randperm.
        RandomSelector
        
        % ClassNames A set of class names to assign to each image region
        %            for training an object classifier.
        ClassNames
        
        % EndOfEpoch Strategy to use for partial mini-batches at the end of
        %            an epoch. This is either 'truncateLast', or
        %            'discardLast'.
        EndOfEpoch
        
        % IsEndOfEpoch Whether or not the reader is done w/ an epoch.
        IsEndOfEpoch
        
        % MiniBatchSize Size of the mini-batch.
        MiniBatchSize
    end
    
    properties (Dependent)
        NumObservations
    end
    
    properties (Access = protected)
        % Datastore The ImageDatastore we are going to read data and
        %           responses from.
        Datastore
        
        % Table A table containing the list of image files and region
        %       proposal boxes.
        Table
        
        % TrainingSamples A table containing indices to boxes to use as
        %                 positive and negative samples.
        TrainingSamples
        
        % NumMiniBatches The number of mini-batches that have been read.
        NumMiniBatches
        
        % CurrentImageIndex  Current index of image from which regions are being
        %                    read.
        CurrentImageIndex
        
        % Start/Stop The beginning and end indices defining the range of
        %            images from which regions will be sampled while
        %            filling the mini-batch.
        Start
        Stop
        
        % NumPos/NumNeg The number of positive and negative samples found
        %               in images within the range start:stop-1.
        NumPos
        NumNeg
        
        % RegionResizer An object used to crop and resize image regions.
        RegionResizer
    end
    
    properties(Dependent)              
        % ImageSize The size of the images in the mini-batch.
        ImageSize
        
        % 
        IsDone
    end
    
    methods
        function val = get.IsDone(this)
            val = this.IsEndOfEpoch;
        end
        
        %------------------------------------------------------------------
        function this = BBoxTrainingDataDispatcher(groundTruth, params)
                                                            
            this.PositiveOverlapRange = params.PositiveOverlapRange;           
            % Pull the object classnames from the variable names of the
            % ground truth table.
            classNames = groundTruth.Properties.VariableNames(2:end);
                                   
            % Select region proposal boxes to use as positive and negative
            % samples.           
            this.TrainingSamples = rowfun(...
                @(varargin)selectTrainingSamples(this, classNames, varargin{:}), groundTruth,...
                'InputVariables',1:width(groundTruth),...
                'OutputFormat','table',...
                'NumOutputs', 3, ...
                'ExtractCellContents', true, ...
                'OutputVariableNames',{'Targets','Boxes', 'Labels'});
            
            % Check for missing data            
            missing = rowfun(@(x)isempty(x{1}),this.TrainingSamples,...
                'InputVariables','Targets','OutputFormat','uniform') ;
            
            % Remove images that have no positive samples.
            this.TrainingSamples(missing,:) = [];
            
            if isempty(this.TrainingSamples)               
                warning(message('vision:rcnn:noTrainingSamples'));
            end
            
            keep = ~missing;
            
            % Standardize the column names
            groundTruth.Properties.VariableNames{1} = 'Files';
           
            this.Table = groundTruth(keep,1);
            
            this.Datastore      = imageDatastore(this.Table.Files);            
            this.MiniBatchSize  = params.miniBatchSize;
            this.EndOfEpoch     = params.endOfEpoch;
            this.RegionResizer  = params.resizer;
            this.RandomSelector = params.RandomSelector;
        end
        
        %------------------------------------------------------------------
        function [miniBatchData, miniBatchResponse, miniBatchLabels] = readNextBatch(this)
            
            [miniBatchData, miniBatchResponse, miniBatchLabels] = ...
                vision.internal.rcnn.batchReadAndCropForBBoxRegression(...
                this.Datastore, this.TrainingSamples, this.RegionResizer, this.RandomSelector, ...
                this.Start, this.Stop, this.MiniBatchSize, this.NumPos);
            
            this.CurrentImageIndex = this.CurrentImageIndex + this.Stop - this.Start;
                                 
            this.NumMiniBatches = this.NumMiniBatches + 1;
            
            this.nextBatch();
        end
        
        %------------------------------------------------------------------
        function [miniBatchData, miniBatchResponse, miniBatchIndices] = next(this)
             [miniBatchData, miniBatchResponse, miniBatchIndices] = readNextBatch(this);
        end

        %------------------------------------------------------------------
        function start(this)
            reset( this.Datastore );
            this.CurrentImageIndex = 1;
            this.NumMiniBatches = 0;
            this.IsEndOfEpoch = false;
            
            this.nextBatch();
        end
        
        %------------------------------------------------------------------
        function shuffle(this)
            idx = this.RandomSelector.randperm(height(this.Table));
            this.Table = this.Table(idx, :);
            this.TrainingSamples = this.TrainingSamples(idx, :);
            this.Datastore.Files = this.Datastore.Files(idx);
        end
        
        %------------------------------------------------------------------
        % Return true when one epoch is complete.
        %------------------------------------------------------------------
        function tf = isDone(this)
            tf = this.IsEndOfEpoch;
        end
        
        %------------------------------------------------------------------
        function n = get.NumObservations( this )
            if isempty(this.TrainingSamples)
                n = 0;
            else
                allObservations = vertcat(this.TrainingSamples.Targets{:});
                n = size(allObservations, 1);
            end
        end
        
        %------------------------------------------------------------------
        function val = get.ImageSize(this)
            val = this.RegionResizer.ImageSize;
        end
               
    end
    
    %----------------------------------------------------------------------
    methods(Access = protected)
        
        %------------------------------------------------------------------
        % Scan the training data for the next batch of images to process.
        % This method populates the Start and Stop properties, which
        % defines the range of images from which regions are extracted.
        %------------------------------------------------------------------
        function nextBatch(this)
            
            if this.CurrentImageIndex > height(this.Table)
                this.IsEndOfEpoch = true;
                return;
            end
            
            [start, stop, numPosSamples] = selectImagesForMiniBatch(this);
            
            this.NumPos = numPosSamples;            
            this.Start  = start;
            this.Stop   = stop;
            
            if stop > height(this.Table)
                % not enough positive samples to fill the mini-batch.
                
                % This indicates an end of an epoch.
                if strcmpi(this.EndOfEpoch, 'discardLast')
                    % do not output a partial mini-batch
                    this.IsEndOfEpoch = true;
                    
                elseif strcmpi(this.EndOfEpoch, 'truncateLast')
                    % allow partial mini-batch.
                    this.Stop = height(this.Table) + 1;
                else
                    % unknown option
                    assert(false);
                end
            end
            
        end
        
        %------------------------------------------------------------------
        % Select images to use to fill mini-batch.
        %------------------------------------------------------------------
        function [start, stop, numPosSamples] = selectImagesForMiniBatch(this)
            
            numPos = this.MiniBatchSize;
            
            % figure out how many images need to be fill mini-batch with
            % enough positive samples.
            numPosSamples = 0;           
            start = this.CurrentImageIndex;
            stop  = start;
            
            while numPosSamples < numPos
                if stop > height(this.Table)
                    break;
                end
                                
                numPosSamples = numPosSamples + size(this.TrainingSamples.Boxes{stop},1);
               
                stop = stop + 1;
            end
        end
        
        %------------------------------------------------------------------
        % Returns indices to boxes that should be used as positive training
        % samples and those that should be used as negative training
        % samples.
        %
        % Uses the strategy described in:
        %
        %    Girshick, Ross, et al. "Rich feature hierarchies for accurate
        %    object detection and semantic segmentation." Proceedings of
        %    the IEEE conference on computer vision and pattern
        %    recognition. 2014.
        %
        %    Girshick, Ross. "Fast r-cnn." Proceedings of the IEEE
        %    International Conference on Computer Vision. 2015.
        %
        %------------------------------------------------------------------
        function [Y, P, L] = selectTrainingSamples(this, classNames, varargin)
            
            filename = varargin{1};
            varargin(1) = [];
            
            % cat all multi-class bounding boxes into one M-by-4 matrix.
            groundTruth = vertcat(varargin{1:numel(varargin)});
             
            % create list of class names corresponding to each ground truth
            % box.
            cls = cell(1, numel(classNames));
            for i = 1:numel(varargin)
                cls{i} = repelem(classNames(i), size(varargin{i},1),1);
            end
            cls = vertcat(cls{:});
                        
            alpha = 0.65;
            I = imread(filename);
            bboxes = [];
            for j = 1:size(groundTruth, 1)
                bboxes = [bboxes; visionGenerateBoxesAroundAnchorBox(I, groundTruth(j,:), alpha)];
            end
                                  
            if isempty(groundTruth) || isempty(bboxes)
                Y = {[]};                
                P = {[]};
                L = {[]};
            else
                
                [G, P, L] = vision.internal.rcnn.BoundingBoxRegressionModel.selectBBoxesForTraining(groundTruth, bboxes, cls, this.PositiveOverlapRange);
                
                Y = vision.internal.rcnn.BoundingBoxRegressionModel.generateRegressionTargets(G, P);
                                
                Y = {Y};
                P = {P};
                L = {L};
            end
            
            
        end
        
    end
    
end