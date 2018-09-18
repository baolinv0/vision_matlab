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
% - One full pass over the set of images is defined as one epoch.
%
% - Positive and negative regions are randomly sampled to fill mini-batches
% using the RandomSelector class. Random sampling ensures we select a
% different set of regions every epoch.

classdef RPNRegionReader < handle
    
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
        
        % GroundTruth
        GroundTruth
        
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
        
        % ImageSize The size of the images in the mini-batch.
        ImageSize
        
        % Anchor properties
        MinBoxSizes
        BoxPyramidScale
        NumBoxPyramidLevels
                
        ScaleImage
        ImageScale
        
        % Layers External layers used to compute the feature map size for
        % any sized image. Used to generate anchor boxes for training.
        Layers 
    end
    
    properties(Dependent)
        % NumPositiveSamplesPerBatch  The actual number of positive samples
        %                             in the mini-batch.
        NumPositiveSamplesPerBatch
                       
        NumAnchors
    end
    
    methods
        function v = get.NumAnchors(this)
            v = size(this.MinBoxSizes,1) * this.NumBoxPyramidLevels;
        end
        
        %------------------------------------------------------------------
        function this = RPNRegionReader(groundTruth, params)
            
            % Set the default background label.
            this.BackgroundLabel = params.BackgroundLabel;
            
            classNames = {'Foreground'};
            
            % Create class names from ground truth data. For object
            % detection add a "Background" class. The order of the class
            % labels is important because they are used to generate
            % response data for training.
            this.ClassNames = [classNames this.BackgroundLabel];
            
            this.PositiveOverlapRange = params.PositiveOverlapRange;
            this.NegativeOverlapRange = params.NegativeOverlapRange;
          
            % RPN training options
            this.MinBoxSizes         = params.MinBoxSizes;
            this.BoxPyramidScale     = params.BoxPyramidScale;
            this.NumBoxPyramidLevels = params.NumBoxPyramidLevels;                               
            
            this.ScaleImage = params.ScaleImage;
            this.ImageScale = params.ImageScale;                      
            
            this.Layers = params.Layers;
            this.RandomSelector = params.RandomSelector;            
           
            this.TrainingSamples = fillTrainingSamples(this, groundTruth, params.UseParallel);

            % Check for missing positives
            missing = rowfun(@(x)isempty(x{1}) || ~any(x{1}),this.TrainingSamples,...
                'InputVariables','Positive','OutputFormat','uniform');                       
                      
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
            
            if this.ScaleImage
                this.Datastore = imageDatastore(this.Table.Files, ...
                    'ReadFcn', @(filename)fastRCNNObjectDetector.scaleImage(filename, params.ImageScale));
            else
                this.Datastore = imageDatastore(this.Table.Files);  
            end
            this.PercentageOfPositiveSamples = 0.25;
            this.MiniBatchSize  = params.miniBatchSize;
            this.EndOfEpoch     = params.endOfEpoch;                                    
            this.ImageSize = params.ImageSize;           
            
            this.CurrentImageIndex = 1;
            this.Start = 1;
            this.NumMiniBatches = 0;
            this.IsEndOfEpoch = false;
            
           
        end
        
        function trainingSamples = fillTrainingSamples(this, groundTruth, useParallel)
            params.PositiveOverlapRange = this.PositiveOverlapRange;
            params.NegativeOverlapRange = this.NegativeOverlapRange;
            params.MinBoxSizes = this.MinBoxSizes;
            params.BoxPyramidScale = this.BoxPyramidScale;
            params.NumBoxPyramidLevels = this.NumBoxPyramidLevels;
            params.NumAnchors = this.NumAnchors;
            params.RandomSelector = this.RandomSelector;
            params.ScaleImage = this.ScaleImage;
            params.ImageScale = this.ImageScale;
            params.Layers = this.Layers;
            if useParallel
                
                gt = table2struct(groundTruth);
                parfor i = 1:numel(gt)
                   
                    c = struct2cell(gt(i));
                    s(i) = vision.internal.cnn.rpn.selectTrainingSamples(params, c{:});
                    
                end
                
                trainingSamples = struct2table(s, 'AsArray', true);
                
            else
                gt = table2struct(groundTruth);
                for i = 1:numel(gt)
                   
                    c = struct2cell(gt(i));
                    s(i) = vision.internal.cnn.rpn.selectTrainingSamples(params, c{:});
                    
                end
                
                trainingSamples = struct2table(s, 'AsArray', true);                
            end
        end
        %------------------------------------------------------------------
        function [data, miniBatchResponse, miniBatchIndices] = readNextBatch(this)
                                                                                             
            idx = this.CurrentImageIndex;
            
            I = this.Datastore.readimage(idx);                                               
                      
            % Use data range between [0 255] for training. During training,
            % image is cast to single but data range is preserved.
            I = im2uint8(I);
            
            I = localConvertImageToMatchNumberOfNetworkImageChannels(I, this.ImageSize);                                     
            
            samples = this.Table.RegionProposalBoxes{idx};
            
            posSamples = samples(this.TrainingSamples.Positive{idx},:);
            
            % 1:1 ratio between positive and negatives.
            numPos = floor(this.MiniBatchSize / 2);            
            numPos = min(numPos, size(posSamples,1));                                
            
            % Create target matrix MxNxK (K == 2*num_anchors)
            ids = this.TrainingSamples.AnchorIndices{idx};
            anchorIDs = this.TrainingSamples.AnchorIDs{idx};
            
            posAnchorIDs = anchorIDs(this.TrainingSamples.Positive{idx});
            negAnchorIDs = anchorIDs(this.TrainingSamples.Negative{idx});
            
            posxy = ids(this.TrainingSamples.Positive{idx}, :);
            negxy = ids(this.TrainingSamples.Negative{idx}, :);
            
            featureMapSize = this.TrainingSamples.FeatureMapSize{idx};
            
            clsResponse = false(featureMapSize);
            
            bb = samples(this.TrainingSamples.Positive{idx},:);
            N = size(bb,1);
            pid = this.RandomSelector.randperm(N, min(N, numPos));
            posSamples = posSamples(pid, :);
            posxy = posxy(pid,:);
            posAnchorIDs = posAnchorIDs(pid);
            % pos
            for i = 1:numel(posAnchorIDs)
                x = posxy(i,1);
                y = posxy(i,2);
                k = posAnchorIDs(i);                
                clsResponse(y, x, 2*(k-1) + 1) = true;                
            end
            
            bb = samples(this.TrainingSamples.Negative{idx},:);
            N = size(bb,1);           
            numNeg = min(N, this.MiniBatchSize - numPos);   
            id = this.RandomSelector.randperm(N, min(N, numNeg));
            
            negxy = negxy(id,:);
            negAnchorIDs = negAnchorIDs(id);
            % neg
            for i = 1:numel(negAnchorIDs)
                x = negxy(i,1);
                y = negxy(i,2);
                k = negAnchorIDs(i);                
                clsResponse(y, x, 2*k) = true;                
            end                                  
            
            % reshape cls response          
            clsResponse = reshape(clsResponse, featureMapSize(1), featureMapSize(2), 2, []);
                                                
            negSamples = bb(id,:);
                     
            % training rois
            roi = [posSamples; negSamples];                     
          
            % REG Response          
            posTargets = this.TrainingSamples.PositiveBoxRegressionTargets{idx};
            posTargets = posTargets(:, pid);
           
            % Regression layer output is [M N 4*NumAnchors], where the 4
            % box coordinates are consequitive elements. W is a weight
            % matrix that indicates which sample should contribute to the
            % loss. W(y,x,k) is 1 if T(y,x,k) should be used.
            W = zeros(featureMapSize(1), featureMapSize(2), this.NumAnchors * 4, 'single');
            T = zeros(featureMapSize(1), featureMapSize(2), this.NumAnchors * 4, 'single');                        
            
            % Put positive targets into appropriate location by anchor ID.
            % Only the positive anchors need to be included because they
            % are the only one that get regressed.
            for i = 1:numel(posAnchorIDs)
                x = posxy(i,1);
                y = posxy(i,2);
                k = posAnchorIDs(i);  
                start = 4*(k-1) + 1;
                stop = start+4-1;
                W(y,x,start:stop) = 1;
                T(y,x,start:stop) = posTargets(:,i);                           
            end                      
            
            clsSelection = this.TrainingSamples.AnchorIndices{idx};
            
            posSelection = clsSelection( this.TrainingSamples.Positive{idx}, :);
            negSelection = clsSelection( this.TrainingSamples.Negative{idx}, :);
           
            clsSelection = [posSelection(pid,:); negSelection(id,:)];
                      
            % pack output for training cls loss and reg loss
            miniBatchResponse = {{clsResponse, clsSelection}, {T, W}};                        
            miniBatchIndices = this.CurrentImageIndex;                        
                       
            % pack output data. return ROI as doubles.
            data = {I, double(roi)};
            
            % go to next image
            this.CurrentImageIndex = this.CurrentImageIndex + 1;
            
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
            val = this.ImageSize;
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
        function [positiveIndex, negativeIndex, labels, regionProposals, targets, anchorIDs, anchorIndices, featureMapSize] = selectTrainingSamples(this, classNames, varargin)
            
            % cat all multi-class bounding boxes into one M-by-4 matrix.
            groundTruth = vertcat(varargin{2:numel(varargin)});
             
            % scale image 
            if this.ScaleImage
                I = fastRCNNObjectDetector.scaleImage(varargin{1}, this.ImageScale);
            else
                I = imread(varargin{1});
            end
            
            imageSize = size(I);
            
            inputSize = imageSize;
            
            % find and remove reshape layer. 
            layers = nnet.cnn.layer.Layer.getInternalLayers(this.Layers);
            whichOne = cellfun(@(x)isa(x , 'vision.internal.cnn.layer.RPNReshape'), layers);             
            layers(whichOne) = [];
            for i = 2:numel(layers)
                inputSize = layers{i}.forwardPropagateSize(inputSize);
            end   
            
            featureMapSize = inputSize;           
            
            % generate box candidates     
            [regionProposals, anchorLocInFeatureMap] = vision.internal.cnn.generateAnchorBoxesInImage(...
                imageSize, featureMapSize, this.MinBoxSizes, this.BoxPyramidScale, this.NumBoxPyramidLevels);                                               
            
            % create anchor Ids for each anchor box. these are required to
            % assign each target to the correct box regressor.
            numAnchors = cellfun(@(x)size(x,1), regionProposals);                        
            anchorIDs = repelem(1:numel(regionProposals), numAnchors);
            
            % convert from k cells to M-by-2 format.
            regionProposals = (vertcat(regionProposals{:}));
            anchorIndices = (vertcat(anchorLocInFeatureMap{:}));
            
            % Compute the Intersection-over-Union (IoU) metric between the
            % ground truth boxes and the region proposal boxes. 
            if isempty(groundTruth)
                iou = zeros(0,size(regionProposals,1));
            elseif isempty(regionProposals)
                iou = zeros(size(groundTruth,1),0);
            else
              
                iou = bboxOverlapRatio(groundTruth, regionProposals, 'union');
            end
            
            % Find bboxes that have largest IoU w/ GT.
            [v,idx] = max(iou,[],1);              
           
            % Select regions to use as positive training samples
            lower = this.PositiveOverlapRange(1);
            upper = this.PositiveOverlapRange(2);
            positiveIndex =  {v >= lower & v <= upper};
            
            if ~any(positiveIndex{1})
                % select box with highest overlap, but not a negative
                 lower = this.NegativeOverlapRange(2);
                 positiveIndex =  {v >= lower & v <= upper};
            end
            
            % Select regions to use as negative training samples
            lower = this.NegativeOverlapRange(1);
            upper = this.NegativeOverlapRange(2);
            negativeIndex =  {v >= lower & v < upper};   
            
            % remove boxes that have already have positive anchors                      
            ind = sub2ind(featureMapSize(1:2), anchorIndices(:,2), anchorIndices(:,1));
            
            posind = ind(positiveIndex{1});
            invalid = false(size(ind));
            for i = 1:numel(posind)
                invalid = invalid | (ind == posind(i));          
            end
            % make sure negative indices don't contain any positives. This
            % can happen because anchor boxes are centered a 1 position.
            negativeIndex{1}(invalid) = false;                                                                                                                                     
                                   
            % Create an array that maps ground truth box to positive
            % proposal box. i.e. this is the closest grouth truth box to
            % each positive region proposal.  
            if isempty(groundTruth)
                targets = {[]};
            else
                G = groundTruth(idx(positiveIndex{1}), :);
                P = regionProposals(positiveIndex{1},:);
                
                % positive sample regression targets
                targets = vision.internal.rcnn.BoundingBoxRegressionModel.generateRegressionTargets(G, P);
                
                targets = {targets'}; % arrange as 4 by num_pos_samples
            end
            
            % foregound labels are located @ 1:k. bg labels are @ k+1:2k.           
            labels = anchorIDs;            
            labels(negativeIndex{1}) = labels(negativeIndex{1}) + this.NumAnchors;
            labels = categorical(labels, 1:(2*this.NumAnchors));
            
             % Sub-sample negative samples to avoid using too much memory.
            numPos = sum(positiveIndex{1});
            negIdx = find(negativeIndex{1});
            numNeg = numel(negIdx);
            nidx   = this.RandomSelector.randperm(numNeg, min(numNeg, 5000));
                                     
            % Pack data as int32 to save memory.
            regionProposals = int32([regionProposals(positiveIndex{1}, :); regionProposals(nidx, :)]);            
            anchorIDs       = {int32([anchorIDs(positiveIndex{1}) anchorIDs(nidx)])};            
            anchorIndices   = {int32([anchorIndices(positiveIndex{1},:); anchorIndices(nidx,:)])};
            
            labels = {[labels(positiveIndex{1}) labels(nidx)]};
                                    
            nr = size(regionProposals,1);
            positiveIndex = false(nr,1);
            negativeIndex = false(nr,1);
            
            positiveIndex(1:numPos) = true;
            negativeIndex(numPos+1:end) = true;
                                   
            positiveIndex = {positiveIndex};
            negativeIndex = {negativeIndex};
            
            % return the region proposals, which may have been augmented
            % with the ground truth data.
            regionProposals = {regionProposals};            
            
            featureMapSize = {featureMapSize};
        end
        
        function groundTruth = catAllBoxes(~, varargin)
            % cat all multi-class bounding boxes into one M-by-4 matrix.
            groundTruth = vertcat(varargin{2:numel(varargin)});
        end                
    end
    
end

%--------------------------------------------------------------------------
function I = localConvertImageToMatchNumberOfNetworkImageChannels(I, imageSize)

isNetImageRGB = numel(imageSize) == 3 && imageSize(end) == 3;
isImageRGB    = ~ismatrix(I);

if isImageRGB && ~isNetImageRGB
    I = rgb2gray(I);
    
elseif ~isImageRGB && isNetImageRGB
    I = repmat(I,1,1,3);
end
end