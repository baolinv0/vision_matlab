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

classdef RegionReader < handle
    
    properties
        % PositiveOverlapRange Specify a range of overlap ratios
        PositiveOverlapRange
        
        % NegativeOverlapRange The range of overlap ratios to use as
        % negative training samples.
        NegativeOverlapRange
        
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
    
    properties (Access = protected, Dependent)        
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
        
        % PercentageOfPositiveSamples The percentage of positive samples
        %                             in a mini-batch.
        PercentageOfPositiveSamples
        
        % BackgroundLabel The label to use for the background class. By
        %                 default this is "Background".
        BackgroundLabel
        
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
        % NumPositiveSamplesPerBatch  The actual number of positive samples
        %                             in the mini-batch.
        NumPositiveSamplesPerBatch
                
        % ImageSize The size of the images in the mini-batch.
        ImageSize
    end
    
    methods
        
        %------------------------------------------------------------------
        function this = RegionReader(groundTruth, regionProposals, params)
            
            % Set the default background label.
            this.BackgroundLabel = params.BackgroundLabel;
            
            classNames = groundTruth.Properties.VariableNames(2:end);
            
            % Create class names from ground truth data. For object
            % detection add a "Background" class. The order of the class
            % labels is important because they are used to generate
            % response data for training.
            this.ClassNames = [classNames this.BackgroundLabel];
            
            this.PositiveOverlapRange = params.PositiveOverlapRange;
            this.NegativeOverlapRange = params.NegativeOverlapRange;
            
            % Select region proposal boxes to use as positive and negative
            % samples.
            tbl = [groundTruth(:,2:end) regionProposals(:,1)];
            this.TrainingSamples = rowfun(...
                @(varargin)selectTrainingSamples(this, classNames, varargin{:}), tbl,...
                'InputVariables',1:width(tbl),...
                'OutputFormat','table',...
                'NumOutputs', 4, ...
                'ExtractCellContents', true, ...
                'OutputVariableNames',{'Positive','Negative','Labels', 'RegionProposals'});
            
            % Check for missing positives
            missing = rowfun(@(x)isempty(x{1}) || ~any(x{1}),this.TrainingSamples,...
                'InputVariables','Positive','OutputFormat','uniform');                       
            
            if any(missing)
                files = groundTruth{missing,1};
                warning(message('vision:rcnn:noPositiveSamples',...
                    sprintf('%s\n', files{:})));
            end
            
            % Check for missing negatives
            missingNeg = rowfun(@(x)isempty(x{1}) || ~any(x{1}),this.TrainingSamples,...
                'InputVariables','Negative','OutputFormat','uniform');
            
            if any(missingNeg)
                files = groundTruth{missingNeg,1};
                warning(message('vision:rcnn:noNegativeSamples',...
                    sprintf('%s\n', files{:})));
            end
            
            % Remove images that have no positive samples. There are
            % usually many more negatives than positives, which is why do
            % not remove images that do not have any negatives.
            this.TrainingSamples(missing,:) = [];
            
            if isempty(this.TrainingSamples)
                error(message('vision:rcnn:noTrainingSamples'));
            end
            
            keep = ~missing;
            
            
                      
            this.Table = [groundTruth(keep,1) this.TrainingSamples.RegionProposals];
            
            % Standardize the column names
            this.Table.Properties.VariableNames{1} = 'Files';
            this.Table.Properties.VariableNames{2} = 'RegionProposalBoxes';
                        
            this.Datastore = imageDatastore(this.Table.Files);
            this.PercentageOfPositiveSamples = 0.25;
            this.MiniBatchSize  = params.miniBatchSize;
            this.EndOfEpoch     = params.endOfEpoch;            
            this.RegionResizer  = params.resizer;
            this.RandomSelector = params.RandomSelector;
                       
            this.CurrentImageIndex = 1;
            this.Start = 1;
            this.NumMiniBatches = 0;
            this.IsEndOfEpoch = false;
        end
        
        %------------------------------------------------------------------
        function [miniBatchData, miniBatchResponse, miniBatchIndices] = readNextBatch(this)
                                                            
            [miniBatchData, miniBatchResponse] = ...
                vision.internal.rcnn.batchReadAndCrop(...
                this.Datastore, this.Table, this.TrainingSamples, ...
                this.RegionResizer, this.RandomSelector, ...
                this.Start, this.Stop, this.NumPositiveSamplesPerBatch, ...
                this.NumPos, this.MiniBatchSize);
            
            this.CurrentImageIndex = this.CurrentImageIndex + this.Stop - this.Start;
            
            n = size(miniBatchData,4);
            miniBatchIndices = (1:n)' + n*(this.NumMiniBatches);
            this.NumMiniBatches = this.NumMiniBatches + 1;
            
            this.nextBatch();
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
            n = height(this.Table);
        end
        
        %------------------------------------------------------------------
        function val = get.ImageSize(this)
            val = this.RegionResizer.ImageSize;
        end
        
        %------------------------------------------------------------------
        function val = get.NumPositiveSamplesPerBatch(this)
            val = floor( this.PercentageOfPositiveSamples * this.MiniBatchSize );
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
            
            [start, stop, numPosSamples, numNegSamples] = selectImagesForMiniBatch(this);
            
            this.NumPos = numPosSamples;
            this.NumNeg = numNegSamples;
            this.Start = start;
            this.Stop  = stop;
            
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
        function [start, stop, numPosSamples, numNegSamples] = selectImagesForMiniBatch(this)
            
            numPos = this.NumPositiveSamplesPerBatch;
            
            % figure out how many images need to be fill mini-batch with
            % enough positive samples.
            numPosSamples = 0;
            numNegSamples = 0;
            start = this.CurrentImageIndex;
            stop  = start;
            
            while numPosSamples < numPos
                if stop > height(this.Table)
                    break;
                end
                
                pos = this.TrainingSamples.Positive{stop};
                neg = this.TrainingSamples.Negative{stop};
                
                numPosSamples = numPosSamples + sum(pos);
                numNegSamples = numNegSamples + sum(neg);
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
        function [positiveIndex, negativeIndex, labels, regionProposals] = selectTrainingSamples(this, classNames, varargin)
            
            % cat all multi-class bounding boxes into one M-by-4 matrix.
            groundTruth = vertcat(varargin{1:numel(varargin)-1});
            
            % create list of class names corresponding to each ground truth
            % box.
            cls = cell(1, numel(classNames));
            for i = 1:numel(varargin)-1
                cls{i} = repelem(classNames(i), size(varargin{i},1),1);
            end
            cls = vertcat(cls{:});
            
            regionProposals = varargin{end};
            
            % Compute the Intersection-over-Union (IoU) metric between the
            % ground truth boxes and the region proposal boxes. 
            if isempty(groundTruth)
                iou = zeros(0,size(regionProposals,1));
            elseif isempty(regionProposals)
                iou = zeros(size(groundTruth,1),0);
            else
                
                % The region proposal algorithm may miss objects in the
                % image. To make sure we use all available training data
                % append the groundTruth boxes to the region proposals. 
                regionProposals = [regionProposals; groundTruth];
                
                iou = bboxOverlapRatio(groundTruth, regionProposals, 'union');
            end
            
            % Find bboxes that have largest IoU w/ GT.
            [v,i] = max(iou,[],1);
            
            % Select regions to use as positive training samples
            lower = this.PositiveOverlapRange(1);
            upper = this.PositiveOverlapRange(2);
            positiveIndex =  {v >= lower & v <= upper};
           
            % Select regions to use as negative training samples
            lower = this.NegativeOverlapRange(1);
            upper = this.NegativeOverlapRange(2);
            negativeIndex =  {v >= lower & v < upper};
            
            labels = cls(i,:);
            labels(negativeIndex{1},:) = {this.BackgroundLabel};              
            labels = {categorical(labels, this.ClassNames)};
            
            % return the region proposals, which may have been augmented
            % with the ground truth data.
            regionProposals = {regionProposals};
        end
        
    end
    
end