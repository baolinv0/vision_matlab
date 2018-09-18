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
        
        LayersUpToROIPooling
    end
    
    properties(Dependent)
        % NumPositiveSamplesPerBatch  The actual number of positive samples
        %                             in the mini-batch.
        NumPositiveSamplesPerBatch
                       
    end
    
    methods
        
        %------------------------------------------------------------------
        function this = RegionReader(groundTruth, regionProposals, params)
            
            % Set the default background label.
            this.BackgroundLabel = params.BackgroundLabel;
            this.Datastore = imageDatastore(groundTruth{:,1});
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
                'NumOutputs', 5, ...
                'ExtractCellContents', true, ...
                'OutputVariableNames',{'Positive','Negative','Labels', 'RegionProposals', 'PositiveBoxRegressionTargets'});
            
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
            
            if params.ScaleImage
                % all the ground truth boxes and region proposal boxes have
                % been scaled already. setup the imds to scale the image
                % too.
                this.Datastore = imageDatastore(this.Table.Files, ...
                    'ReadFcn', @(filename)fastRCNNObjectDetector.scaleImage(filename, params.ImageScale));
            else
                this.Datastore = imageDatastore(this.Table.Files);
            end
            
            this.PercentageOfPositiveSamples = 0.25;
            this.MiniBatchSize  = params.miniBatchSize;
            this.EndOfEpoch     = params.endOfEpoch;                        
            this.RandomSelector = params.RandomSelector;
            this.ImageSize      = params.ImageSize;     
            this.LayersUpToROIPooling = params.LayersUpToROIPooling;
            
            this.CurrentImageIndex = 1;
            this.Start = 1;
            this.NumMiniBatches = 0;
            this.IsEndOfEpoch = false;
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
            
            % TODO this coudl be a paramter, 1:1 ratio between positive and negatives.
            numPos = size(posSamples,1);
            numNeg = floor(4/3*numPos);
            
            bb = samples(this.TrainingSamples.Negative{idx},:);
            N = size(bb,1);
            id = this.RandomSelector.randperm(N, min(N, numNeg));
            negSamples = bb(id,:);
            
            % response
            labels = this.TrainingSamples.Labels{idx};
            posResponse = labels(this.TrainingSamples.Positive{idx});
            negResponse = labels(this.TrainingSamples.Negative{idx});
            
            % training rois
            roi = [posSamples; negSamples];
            
            % CLS response
            % data in mini-batch need not be shuffled. training responses
            % are averaged over all mini-batch samples so order does not
            % matter.
            
            dummifiedPosResponse = nnet.internal.cnn.util.dummify(posResponse);
            dummifiedNegResponse = nnet.internal.cnn.util.dummify(negResponse(id));
            
            clsResponse = cat(4, dummifiedPosResponse, dummifiedNegResponse);
            
            % REG Response
            numNeg = size(negSamples,1);
            numPos = size(posSamples,1);
            
            posTargets = this.TrainingSamples.PositiveBoxRegressionTargets{idx};
            negTargets = zeros([4 numNeg],'like',posTargets);
            
            targets = [posTargets negTargets];                                  
                            
            % expand targets array for K-1 classes, excluding the
            numClasses = numel(categories(labels));
           
            targets = repmat(targets, numClasses-1, 1);
            targets = reshape(targets, [1 1 (numClasses-1)*4 numNeg+numPos]);            
            
            % create a "class selection" array. This facilitates selecting
            % class specific targets when computing the regression loss.
            selection = cat(4, dummifiedPosResponse, zeros(size(dummifiedNegResponse),'like',dummifiedPosResponse));
            selection = squeeze(selection);
            
            % get the location of "background" label in selection and
            % remove it.
            bgIdx = strcmp(this.BackgroundLabel, categories(posResponse));                          
            selection(bgIdx,:) = [];
                        
            % duplicate selection entries 4 times for tx,ty,tw,th, and
            % reshape to 4D array
            selection = repelem(selection, 4, 1);
            selection = reshape(selection, [1 1 (numClasses-1)*4 numNeg+numPos]);                       
                                   
            % pack output for training cls loss and reg loss
            miniBatchResponse = {clsResponse, {targets, selection}};                    
            
            miniBatchIndices = this.CurrentImageIndex;                        
                                
            % go to next image
            this.CurrentImageIndex = this.CurrentImageIndex + 1;
            
            % scale roi for ROI Pooling layer
            roi = this.scaleROI(roi, size(I));
            
            % package data in cell
            data = {I, roi};
            
            this.nextBatch();
        end
        
        %------------------------------------------------------------------        
        function scaledROI = scaleROI(this, roi, inputSize)
                  
            [sx, sy] = vision.internal.cnn.roiScaleFactor(...
                this.LayersUpToROIPooling, inputSize);
                        
            scaledROI = vision.internal.cnn.scaleROI(roi, sx, sy);
            
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
        function [positiveIndex, negativeIndex, labels, regionProposals, targets] = selectTrainingSamples(this, classNames, varargin)
            
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

            % Create an array that maps ground truth box to positive
            % proposal box. i.e. this is the closest grouth truth box to
            % each positive region proposal.  
            if isempty(groundTruth)
                targets = {[]};
            else
                G = groundTruth(i(positiveIndex{1}), :);
                P = regionProposals(positiveIndex{1},:);
                
                % positive sample regression targets
                targets = vision.internal.rcnn.BoundingBoxRegressionModel.generateRegressionTargets(G, P);
                
                targets = {targets'}; % arrange as 4 by num_pos_samples
            end
            % return the region proposals, which may have been augmented
            % with the ground truth data.
            regionProposals = {regionProposals};            
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


function bboxes = applyReg(P,reg)
x = reg(:,1);
y = reg(:,2);
w = reg(:,3);
h = reg(:,4);

% center of proposals
px = P(:,1) + floor(P(:,3)/2);
py = P(:,2) + floor(P(:,4)/2);

% compute regression value of ground truth box
gx = P(:,3).*x + px; % center position
gy = P(:,4).*y + py;

gw = P(:,3) .* exp(w);
gh = P(:,4) .* exp(h);

% convert to [x y w h] format
bboxes = [ gx - floor(gw/2) gy - floor(gh/2) gw gh];

bboxes = round(bboxes);

end

function bboxes = applyBoxRegression(P, reg, labels)

% reg is 4D array [1 1 numClasses*4 numObs]. reshape to
% 4-by-numClasses-by-numObs
numObservations = size(reg,4);
reg = reshape(reg, 4, numel(categories(labels))-1, numObservations);

idx = int32(labels);
v = zeros(numObservations, 4, 'like', reg);
for i = 1:numObservations
   v(i,:) = reg(:, idx(i), i)';
end

bboxes = applyReg(P, v);

end