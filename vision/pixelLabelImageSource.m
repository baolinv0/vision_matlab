%pixelLabelImageSource Data source for semantic segmentation networks.
%   datasource = pixelLabelImageSource(gTruth) creates a data source
%   for training a semantic segmentation network using deep learning. The
%   input gTruth is an array of groundTruth objects. The output is a
%   pixelLabelImageSource object. Use this output with trainNetwork
%   from Neural Network Toolbox to train convolutional neural networks for
%   semantic segmentation.
%
%   datasource = pixelLabelImageSource(imds, pxds) creates a data
%   source for training a semantic segmentation network using deep
%   learning. The input imds is an imageDatastore that specifies the ground
%   truth images. The input pxds is a pixelLabelDatastore that specifies
%   the pixel label data. imds represents the training input to the network
%   and pxds represents the desired network output.
%
%   [...] = pixelLabelImageSource(..., Name, Value) specifies
%   additional name-value pair arguments described below:
%
%      'DataAugmentation'      Specify image data augmentation using an
%                              imageDataAugmenter object or 'none'.
%                              Training data is augmented in real-time
%                              while training.
%
%                              Default: 'none'
%
%      'ColorPreprocessing'    A scalar string or character vector
%                              specifying color channel pre-processing.
%                              This option can be used when you have a
%                              training set that contains both color and
%                              grayscale image data and you need data
%                              created by the datasource to be strictly
%                              color or grayscale. Valid values are
%                              'gray2rgb', 'rgb2gray', and 'none'. For
%                              example, if you need to train a  network
%                              that expects color images but some of the
%                              images in your training set are grayscale,
%                              then specifying the option 'gray2rgb' will
%                              replicate the color channels of the
%                              grayscale images in the input image set to
%                              create M-by-N-by-3 output images.
%
%                              Default: 'none'
%
%      'OutputSize'            A two element vector specifying the number
%                              of rows and columns in images produced by
%                              the datasource. When specified, image sizes
%                              are adjusted as necessary to achieve output
%                              of images of the specified size. By default,
%                              'OutputSize' is empty and the ouput size is
%                              not adjusted.
%
%                              Default: []
%
%      'OutputSizeMode'        A scalar string or character vector
%                              specifying the technique used to adjust
%                              image sizes to the specified 'OutputSize'.
%                              Valid values are 'resize', 'centercrop' and
%                              'randcrop'. This option only applies when
%                              'OutputSize' is not empty.
%
%                              Default: 'resize'
%
%      'BackgroundExecution'   Accelerate image augmentation by
%                              asyncronously reading, augmenting, and
%                              queueing augmented images for use in
%                              training. Requires Parallel Computing
%                              Toolbox.
%
%                              Default: false
%
%   pixelLabelImageSource Properties:
%
%      Images             - A list of image filenames.
%      PixelLabelData     - A list of pixel label data filenames.
%      ClassNames         - A cell array of pixel label class names.
%      DataAugmentation   - Selected data augmentations.
%      ColorPreprocessing - Selected color channel processing.
%      OutputSize         - Output size of output images.
%      OutputSizeMode     - Output size adjustment mode.
%
%   pixelLabelImageSource Methods:
%
%      countEachLabel - Counts the number of pixel labels for each class.
%
%   Example 1
%   ---------
%   % Train a semantic segmentation network using data provided by the
%   % pixelLabelImageSource.
%
%   % Load training images and pixel labels.
%   dataSetDir = fullfile(toolboxdir('vision'),'visiondata','triangleImages');
%   imageDir = fullfile(dataSetDir, 'trainingImages');
%   labelDir = fullfile(dataSetDir, 'trainingLabels');
%
%   % Create an imageDatastore holding the training images.
%   imds = imageDatastore(imageDir);
%
%   % Define the class names and their associated label IDs.
%   classNames = ["triangle", "background"];
%   labelIDs   = [255 0];
%
%   % Create a pixelLabelDatastore holding the ground truth pixel labels for
%   % the training images.
%   pxds = pixelLabelDatastore(labelDir, classNames, labelIDs);
%
%   % Create network for semantic segmentation.
%   layers = [
%       imageInputLayer([32 32 1])
%       convolution2dLayer(3, 64, 'Padding', 1)
%       reluLayer()
%       maxPooling2dLayer(2, 'Stride', 2)
%       convolution2dLayer(3, 64, 'Padding', 1)
%       reluLayer()
%       transposedConv2dLayer(4, 64, 'Stride', 2, 'Cropping', 1);
%       convolution2dLayer(1, 2);
%       softmaxLayer()
%       pixelClassificationLayer()
%       ]
%
%   % Create data source for training a semantic segmentation network.
%   datasource = pixelLabelImageSource(imds,pxds);
%
%   % Setup training options. Note MaxEpochs is set to 5 to reduce example
%   % run-time.
%   options = trainingOptions('sgdm', 'InitialLearnRate', 1e-3, ...
%       'MaxEpochs', 5, 'VerboseFrequency', 10);
%
%   % Train network.
%   net = trainNetwork(datasource, layers, options)
%
%   Example 2
%   ---------
%   % Configure the pixelLabelImageSource to augment data while training.
%
%   % Load training images and pixel labels.
%   dataSetDir = fullfile(toolboxdir('vision'),'visiondata','triangleImages');
%   imageDir = fullfile(dataSetDir, 'trainingImages');
%   labelDir = fullfile(dataSetDir, 'trainingLabels');
%
%   % Create an imageDatastore holding the training images.
%   imds = imageDatastore(imageDir);
%
%   % Define the class names and their associated label IDs.
%   classNames = ["triangle", "background"];
%   labelIDs   = [255 0];
%
%   % Create a pixelLabelDatastore holding the ground truth pixel labels for
%   % the training images.
%   pxds = pixelLabelDatastore(labelDir, classNames, labelIDs);
%
%   % Create an imageDataAugmenter. For example, randomly roate and mirror
%   % image data.
%   augmenter = imageDataAugmenter('RandRotation', [-10 10], 'RandXReflection', true);
%
%   % Create a datasource for training network with augmented data.
%   datasource = pixelLabelImageSource(imds,pxds,'DataAugmentation',augmenter);
%
%   datasource.DataAugmentation
%
% See also trainNetwork, groundTruth, imageDataAugmenter, semanticseg,
%          pixelClassificationLayer, pixelLabelDatastore, imageDatastore.

% Copyright 2017 The MathWorks, Inc.
classdef pixelLabelImageSource < ...
        nnet.internal.cnn.MiniBatchDatasource & ...
        vision.internal.cnn.DistributablePixelLabelImageSource &...
        nnet.internal.cnn.BackgroundDispatchableDatasource
    
    properties(Dependent, SetAccess = private)
        %Images Source of ground truth images.
        Images
        
        %PixelLabelData Source of ground truth label images.
        %Pixel labels are stored as label matrices in uint8 images.
        PixelLabelData
        
    end
    
    properties(Dependent, SetAccess = private)
        %ClassNames A cell array of class names.
        ClassNames
        
    end
    
    properties(SetAccess = private)
        %DataAugmentation
        %Specify image data augmentation using an imageDataAugmenter object
        %or 'none'. Training data is augmented in real-time while training.
        DataAugmentation
        
        %ColorPreprocessing
        %A scalar string or character vector specifying color channel
        %pre-processing. This option can be used when you have a training
        %set that contains both color and grayscale image data and you need
        %data created by the datasource to be strictly color or grayscale.
        %Options are: 'gray2rgb','rgb2gray','none'. For example, if you
        %need to train a  network that expects color images but some of the
        %images in your training set are grayscale, then specifying the
        %option 'gray2rgb' will replicate the color channels of the
        %grayscale images in the input image set to create MxNx3 output
        %images. The default is 'none'.
        ColorPreprocessing
        
        %OutputSize
        %A two element vector specifying the number of rows and columns in
        %images produced by the datasource. When specified, image sizes are
        %adjusted as necessary to achieve output of images of the specified
        %size. By default, 'OutputSize' is empty and the ouput size is not
        %adjusted.
        OutputSize
        
        %OutputSizeMode
        % A scalar string or character vector specifying the technique used
        % to adjust image sizes to the specified 'OutputSize'. Valid values
        % are 'resize', 'centercrop' and 'randcrop'. This option only
        % applies when 'OutputSize' is not empty. The default is 'resize'.
        OutputSizeMode
        
        %BackgroundExecution
        % Accelerate image augmentation by asyncronously reading,
        % augmenting, and queueing augmented images for use in training.
        % Requires Parallel Computing Toolbox.
        BackgroundExecution logical
    end
    
    properties(Hidden, Dependent)
        MiniBatchSize
        NumberOfObservations
    end
    
    properties(Hidden, Access = ?nnet.internal.cnn.DistributableMiniBatchDatasource)
        ImageDatastore
        PixelLabelDatastore
    end
    
    methods
        
        function this = pixelLabelImageSource(varargin)
            narginchk(1,inf);
            if isa(varargin{1}, 'groundTruth')
                
                [gTruth, params] = iParseGroundTruthInput(varargin{:});
                
                % Create internal datastores
                opts.IncludeSubfolders = false;
                opts.ReadSize = 1;
                [this.PixelLabelDatastore, this.ImageDatastore] = ...
                    matlab.io.datastore.PixelLabelDatastore.createFromGroundTruth(gTruth, opts);
            else
                
                [imds, pxds, params] = iParseImdsPxdsInput(varargin{:});
                
                % Make copy of user datastores.
                this.ImageDatastore      = copy(imds);
                this.PixelLabelDatastore = copy(pxds);
                
                if numel(this.ImageDatastore.Files) ~= numel(this.PixelLabelDatastore.Files)
                    error(message('vision:semanticseg:unequalNumelFiles'));
                end
                
            end
            
            this.ColorPreprocessing  = params.ColorPreprocessing;
            this.DataAugmentation    = params.DataAugmentation;
            this.OutputSize          = params.OutputSize;
            this.OutputSizeMode      = params.OutputSizeMode;
            this.BackgroundExecution = params.BackgroundExecution;
            this.UseParallel         = this.BackgroundExecution;

            this.reset();
        end
        
        %------------------------------------------------------------------
        function batchSize = get.MiniBatchSize(this)
            batchSize = this.ImageDatastore.ReadSize;
        end
        
        %------------------------------------------------------------------
        function set.MiniBatchSize(this,batchSize)
            this.ImageDatastore.ReadSize = batchSize;
        end
        
        %------------------------------------------------------------------
        function val = get.ClassNames(this)
            val = this.PixelLabelDatastore.ClassNames;
        end
        
        %------------------------------------------------------------------
        function val = get.NumberOfObservations(this)
            val = length(this.ImageDatastore.Files);
        end
        
        %------------------------------------------------------------------
        function s = saveobj(this)
            s.Version = 1.0;
            s.imds = this.ImageDatastore;
            s.pxds = this.PixelLabelDatastore;
            s.ColorPreprocessing = this.ColorPreprocessing;
            s.DataAugmentation = this.DataAugmentation;
        end
        
    end
    
    methods(Hidden)
        
        %------------------------------------------------------------------
        function [X,Y] = getObservations(this,indices)
            % Create datastore partition via a copy and index. This is
            % faster than constructing a new datastore with the new
            % files.
            subds = copy(this.ImageDatastore);
            subds.Files = this.ImageDatastore.Files(indices);
            X = readall(subds);
            
            [Y, info] = readNumeric(this.PixelLabelDatastore, indices);
            [X, Y] = preprocess(this, X, Y, info);
        end
        
        %------------------------------------------------------------------
        function [X,Y] = nextBatch(this)
            % sync imds and pxds read size.  %TODO move this to set method
            this.PixelLabelDatastore.ReadSize = this.MiniBatchSize;
            
            % Read image and pixel label data. Return pixel data as numeric
            % to avoid double converting from numeric to/from categorical.
            X = read(this.ImageDatastore);
            [Y, info] = readNumeric(this.PixelLabelDatastore);
            
            [X, Y] = preprocess(this, X, Y, info);

        end
        
        %------------------------------------------------------------------
        function reset(this)
            reset(this.ImageDatastore);
            reset(this.PixelLabelDatastore);
        end
        
        %------------------------------------------------------------------
        function shuffle(this)
            ord = randperm( numel(this.Images) );
            reorder(this, ord);
        end
        
        %------------------------------------------------------------------
        function reorder(this, indices)
            this.ImageDatastore.Files = this.ImageDatastore.Files(indices);
            this.PixelLabelDatastore.shuffle(indices);
        end
    end
    
    methods
        %------------------------------------------------------------------
        function src = get.Images(this)
            src = this.ImageDatastore.Files;
        end
        
        %------------------------------------------------------------------
        function src = get.PixelLabelData(this)
            src = this.PixelLabelDatastore.Files;
        end
        
        %------------------------------------------------------------------
        function tbl = countEachLabel(this)
            % tbl = countEachLabel(datasource) counts the occurrence of
            % each pixel label for all images represented by the
            % datasource. The output tbl is a table with the following
            % variables names:
            %
            %   Name            - The pixel label class name.
            %
            %   PixelCount      - The number of pixels of a given class.
            %
            %   ImagePixelCount - The total number of pixels in images that
            %                     had an instance of the given class.
            %
            % Class Balancing
            % ---------------
            % The output of countEachLabel can be used to calculate class
            % weights for class balancing, for example:
            %
            %   * Uniform class balancing weights each class such that each
            %     has a uniform prior probability:
            %
            %        numClasses = height(tbl)
            %        prior = 1/numClasses;
            %        classWeights = prior./tbl.PixelCount
            %
            %   * Inverse frequency balancing weights each class such that
            %     underrepresented classes are given higher weight:
            %
            %        totalNumberOfPixels = sum(tbl.PixelCount)
            %        frequency = tbl.PixelCount / totalNumberOfPixels;
            %        classWeights = 1./frequency
            %
            %   * Median frequency balancing weights each class using the
            %     median frequency. The weight for each class c is defined
            %     as median(imageFreq)/imageFreq(c) where imageFreq(c) is
            %     the number of pixels of a given class divided by the
            %     total number of pixels in images that had a instance of
            %     the given class c.
            %
            %        imageFreq = tbl.PixelCount ./ tbl.ImagePixelCount
            %        classWeights = median(imageFreq) ./ imageFreq
            %
            % The calculated class weights can be passed to the
            % pixelClassificationLayer. See example below.
            %
            % Example
            % --------
            % % Setup of data location.
            % dataDir = fullfile(toolboxdir('vision'), 'visiondata');
            % imDir = fullfile(dataDir, 'building');
            % pxDir = fullfile(dataDir, 'buildingPixelLabels');
            %
            % % Create datasource using ground truth and pixel labeled images.
            % imds = imageDatastore(imDir);
            % classNames = ["sky" "grass" "building" "sidewalk"];
            % pixelLabelID = [1 2 3 4];
            % pxds = pixelLabelDatastore(pxDir, classNames, pixelLabelID);
            % src = pixelLabelImageSource(imds, pxds);
            %
            % % Tabulate pixel label counts in dataset.
            % tbl = countEachLabel(src)
            %
            % % Class balancing using uniform prior weighting.
            % prior = 1/numel(classNames);
            % uniformClassWeights = prior./tbl.PixelCount
            %
            % % Class balancing using inverse frequency weighting.
            % totalNumberOfPixels = sum(tbl.PixelCount);
            % frequency = tbl.PixelCount / totalNumberOfPixels;
            % invFreqClassWeights = 1./frequency
            %
            % % Class balancing using median frequency weighting.
            % freq = tbl.PixelCount ./ tbl.ImagePixelCount
            % medFreqClassWeights = median(freq) ./ freq
            %
            % % Pass the class weights to the pixel classification layer.
            % layer = pixelClassificationLayer('ClassNames', tbl.Name, ...
            %     'ClassWeights', medFreqClassWeights)
            %
            % See also pixelClassificationLayer, pixelLabelDatastore,
            %          imageDatastore.
            
            tbl = this.PixelLabelDatastore.countEachLabel();
        end
        
    end
    
    methods(Hidden, Static)
        %------------------------------------------------------------------
        function this = loadobj(s)
            this = pixelLabelImageSource(s.imds, s.pxds);
            this.ColorPreprocessing = s.ColorPreprocessing;
            this.DataAugmentation = s.DataAugmentation;
        end
        
        %------------------------------------------------------------------
        function A = onehotencode(C)
            
            numCategories = numel(categories(C));
            [H, W, ~, numObservations] = size(C);
            dummifiedSize = [H, W, numCategories, numObservations];
            A = zeros(dummifiedSize, 'single');
            C = iMakeVertical( C );
            
            [X,Y,Z] = meshgrid(1:W, 1:H, 1:numObservations);
            
            X = iMakeVertical(X);
            Y = iMakeVertical(Y);
            Z = iMakeVertical(Z);
            
            % Remove missing labels. These are pixels we should ignore during
            % training. The dummified output is all zeros along the 3rd dims and are
            % ignored during the loss computation.
            [C, removed] = rmmissing(C);
            X(removed) = [];
            Y(removed) = [];
            Z(removed) = [];
            
            idx = sub2ind(dummifiedSize, Y(:), X(:), int32(C), Z(:));
            A(idx) = 1;
        end
        
        %------------------------------------------------------------------
        function [X,Y] = augment(augmenter,X,Y)
            % Convert pixel label data to single for augmentation. This
            % allows using NaN fill values which are converted to
            % undefined categoricals and excluded from
            % training/inference.
            if iscell(Y)
                Y = cellfun(@(y)single(y),Y,'UniformOutput', false);
            else
                Y = single(Y);
            end
            % Use nearest interpolation for pixel label data.
            interpY = 'nearest';
            fillValueY = NaN;
            
            [X,Y] = augmenter.augmentPair(X,Y,interpY,fillValueY);
        end
    end
    
    methods(Hidden, Access = private)
        %------------------------------------------------------------------
        function [X, Y] = augmentData(this, X, Y)
            if ~strcmp(this.DataAugmentation,'none')
                [X,Y] = pixelLabelImageSource.augment(this.DataAugmentation,X,Y);
            end
        end
        
        %------------------------------------------------------------------
        function [X, Y] = preprocess(this, X, Y, info)
            % Apply color preprocessing.
            switch this.ColorPreprocessing
                case 'none'
                case 'rgb2gray'
                    X = iConvertAnyRGBToGray(X);
                case 'gray2rgb'
                    X = iConvertAnyGrayToRGB(X);
            end
            
            if isa(this.DataAugmentation,'imageDataAugmenter') || ...
                    (~isempty(this.OutputSize) && string(this.OutputSizeMode).contains('crop'))
                
                % Data augmentation and output cropping require that both X
                % and Y have the same [H W].
                sizesX = iSizesInBatch(X);
                sizesY = iSizesInBatch(Y);
                
                if ~isequal(sizesX, sizesY)
                    error(message('vision:semanticseg:augOutSizeNotSupported'))
                end
            end
            
            % Apply data augmentation
            [X, Y] = augmentData(this, X, Y);
            
            % Apply output size selection.
            if ~isempty(this.OutputSize)
                
                switch this.OutputSizeMode
                    case 'resize'
                        Y = iResizeLabelMatrix(Y, this.OutputSize);
                        X = iResize(X, this.OutputSize);
                    case 'randcrop'
                        [X, Y] = iRandCrop(X, Y, this.OutputSize);
                    case 'centercrop'
                        [X, Y] = iCenterCrop(X, Y, this.OutputSize);
                end
                
            end
            
            % Convert pixel label data to categorical.
            Y = label2categorical(this.PixelLabelDatastore, Y, info);
            
            % Convert pixel label data to 4D array. This allows datasource
            % dispatching to dummify 4D categorical.
            Y = iCellTo4DArray(Y);
            
            % Leave X as cell array. It will be converted to 4D array by
            % datasource dispatcher.
        end
        
    end
end

%--------------------------------------------------------------------------
function sizes = iSizesInBatch(batch)
if iscell(batch)
    sizes = cellfun(@(x)iHeightWidth(x),batch,'UniformOutput',false);
else
    sizes = {iHeightWidth(batch)};
end
end

%--------------------------------------------------------------------------
function hw = iHeightWidth(x)
sz = size(x);
hw = sz(1:2);
end

%--------------------------------------------------------------------------
function x = iCheckColorPreprocessing(x)
x = validatestring(x, {'none', 'rgb2gray', 'gray2rgb'}, mfilename, 'ColorPreprocessing');
end

%--------------------------------------------------------------------------
function aug = iCheckDataAugmentation(aug)
validateattributes(aug, {'char', 'string', 'imageDataAugmenter'},{},...
    mfilename, 'DataAugmentation');

if isa(aug, 'imageDataAugmenter')
    validateattributes(aug, {'imageDataAugmenter'},{'scalar'}, mfilename, 'DataAugmentation');
else
    aug = validatestring(aug, {'none'}, mfilename, 'DataAugmentation');
    aug = char(aug);
end
end

%--------------------------------------------------------------------------
function p = iAddCommonParameters(p)
p.addParameter('DataAugmentation', 'none');
p.addParameter('ColorPreprocessing', 'none');
p.addParameter('OutputSize', []);
p.addParameter('OutputSizeMode', 'resize');
p.addParameter('BackgroundExecution', false);
end

%--------------------------------------------------------------------------
function params = iCheckCommonParameters(userInput)
dataAugmentation   = iCheckDataAugmentation(userInput.DataAugmentation);
colorPreprocessing = iCheckColorPreprocessing(userInput.ColorPreprocessing);
mode               = iCheckOutputSizeMode(userInput.OutputSizeMode);

vision.internal.inputValidation.validateLogical(...
    userInput.BackgroundExecution, 'BackgroundExecution');

iCheckOutputSize(userInput.OutputSize);

params.DataAugmentation    = dataAugmentation;
params.ColorPreprocessing  = char(colorPreprocessing);
params.OutputSizeMode      = char(mode);
if ~isempty(userInput.OutputSize)
    params.OutputSize = double(userInput.OutputSize(1:2));
else
    params.OutputSize = [];
end

params.BackgroundExecution = logical(userInput.BackgroundExecution);
end

%--------------------------------------------------------------------------
function mode = iCheckOutputSizeMode(mode)
mode = validatestring(mode, {'resize', 'randcrop', 'centercrop'}, ...
    mfilename, 'OutputSizeMode');
end

%--------------------------------------------------------------------------
function iCheckOutputSize(sz)
if ~isempty(sz)
    validateattributes(sz, {'numeric'}, ...
        {'row', 'positive', 'finite'}, mfilename, 'OutputSize');
end
end

%--------------------------------------------------------------------------
function [gTruth, params] = iParseGroundTruthInput(varargin)

p = inputParser;
p.addRequired('gTruth', @iCheckGroundTruth);
p = iAddCommonParameters(p);

p.parse(varargin{:});

userInput = p.Results;

gTruth = userInput.gTruth;

params = iCheckCommonParameters(userInput);

end

%--------------------------------------------------------------------------
function [imds, pxds, params] = iParseImdsPxdsInput(varargin)

p = inputParser;
p.addRequired('imds');
p.addRequired('pxds');
p = iAddCommonParameters(p);

p.parse(varargin{:});

userInput = p.Results;

imds = userInput.imds;
pxds = userInput.pxds;

validateattributes(imds, {'matlab.io.datastore.ImageDatastore'},...
    {'scalar'}, mfilename, 'imds');

validateattributes(pxds, {'matlab.io.datastore.PixelLabelDatastore'},...
    {'scalar'}, mfilename, 'imds');


params = iCheckCommonParameters(userInput);

end

%--------------------------------------------------------------------------
function iCheckGroundTruth(g)
validateattributes(g, {'groundTruth'}, {'vector','nonempty'}, ...
    mfilename, 'gTruth');

names = cell(numel(g),1);
for i = 1:numel(g)
    
    iAssertAllGroundTruthHasPixelLabelType(g(i));
    
    iAssertAllPixelLabelDataIsNotMissing(g(i));
    
    names{i} = iGatherLabelNamesOfPixelLabelType(g(i));
end

% array of groundTruth should have same pixel label classes. order does not
% matter.
iAssertAllGroundTruthHasSameLabelNames(names);

end

%--------------------------------------------------------------------------
function iAssertAllGroundTruthHasPixelLabelType(gTruth)
if ~any(gTruth.LabelDefinitions.Type == labelType.PixelLabel)
    error(message('vision:semanticseg:missingPixelLabelData'))
end
end

%--------------------------------------------------------------------------
function iAssertAllPixelLabelDataIsNotMissing(gTruth)
if all(strcmp('', gTruth.LabelData.PixelLabelData))
    error(message('vision:semanticseg:missingPixelLabelData'));
end
end

%--------------------------------------------------------------------------
function names = iGatherLabelNamesOfPixelLabelType(gTruth)
defs = gTruth.LabelDefinitions;
names = defs.Name(defs.Type == labelType.PixelLabel);
end

%--------------------------------------------------------------------------
function iAssertAllGroundTruthHasSameLabelNames(names)

n = names{1};
for i = 2:numel(names)
    C = setdiff(n, names{i});
    if ~isempty(C)
        error(message('vision:semanticseg:inconsistentPixelLabelNames'));
    end
end

end

%--------------------------------------------------------------------------
function X = iConvertAnyRGBToGray(X)
if iscell(X)
    for i = 1:numel(X)
        if ~ismatrix(X{i})
            X = rgb2gray(X);
        end
    end
    X = cellfun(@(x)rgb2gray(x), X, 'UniformOutput', false);
else
    if ~ismatrix(X)
        X = rgb2gray(X);
    end
end
end

%--------------------------------------------------------------------------
function X = iConvertAnyGrayToRGB(X)
if iscell(X)
    for i = 1:numel(X)
        if ismatrix(X{i})
            X{i} = repelem(X{i},1,1,3);
        end
    end
else
    if ismatrix(X)
        X = repelem(X,1,1,3);
    end
end
end

%--------------------------------------------------------------------------
function vec = iMakeVertical( vec )
vec = reshape( vec, numel( vec ), 1 );
end

%--------------------------------------------------------------------------
function [X, Y] = iRandCrop(X, Y, outputSize)
if iscell(X)
    [X, Y] = cellfun(@(x,y)iRandCropImage(x,y,outputSize), X, Y, 'UniformOutput', false);
else
    [X, Y] = iRandCropImage(X, Y, outputSize);
end
end

%--------------------------------------------------------------------------
function [X, Y] = iCenterCrop(X, Y, outputSize)
if iscell(X)
    [X, Y] = cellfun(@(x,y)iCenterCropImage(x,y,outputSize), X, Y, 'UniformOutput', false);
    
else
    [X, Y] = iCenterCropImage(X,Y,outputSize);
end
end

%--------------------------------------------------------------------------
function [X, Y] = iCenterCropImage(X, Y, outputSize)
% X and Y MUST have same size for this to make sense.
X = augmentedImageSource.centerCrop(X,outputSize);
Y = augmentedImageSource.centerCrop(Y,outputSize);
end

%--------------------------------------------------------------------------
function [X, Y] = iRandCropImage(X, Y, outputSize)
rect = augmentedImageSource.randCropRect(X,outputSize);
X = augmentedImageSource.crop(X, rect);
Y = augmentedImageSource.crop(Y, rect);
end

%--------------------------------------------------------------------------
function X = iResize(X, outputSize)
if iscell(X)
    X = cellfun(@(x)augmentedImageSource.resizeImage(x, outputSize), X, 'UniformOutput', false);
else
    X = augmentedImageSource.resizeImage(X, outputSize);
end
end

%------------------------------------------------------------------
function L = iResizeLabelMatrix(L,outputSize)
if iscell(L)
    L = cellfun(...
        @(x)iResizeLabels(x, outputSize), ...
        L, 'UniformOutput', false);
else
    L = iResizeLabels(L, outputSize);
end
end

%------------------------------------------------------------------
function imOut = iResizeLabels(L,outputSize)
ippResizeSupportedWithCast = isa(L,'int8') || isa(L,'uint16') || isa(L,'int16');
ippResizeSupportedForType = isa(L,'uint8') || isa(L,'single');
ippResizeSupported = ippResizeSupportedWithCast || ippResizeSupportedForType;

if ippResizeSupportedWithCast
    L = single(L);
end

if ippResizeSupported
    imOut = nnet.internal.cnnhost.resizeImage2D(L,outputSize,'nearest',false);
else
    imOut = imresize(L,'OutputSize',outputSize,'method','nearest','Antialias',false);
end

end

%--------------------------------------------------------------------------
function data = iCellTo4DArray( images )
% iCellTo4DArray   Convert a cell array of images to a 4-D array. If the
% input images is already an array just return it.
if iscell( images )
    try
        data = cat(4, images{:});
    catch e
        throwVariableSizesException(e);
    end
else
    data = images;
end
end
