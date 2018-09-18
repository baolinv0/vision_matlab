function index = indexImages(imgSet, varargin)
%indexImages Create an index for image search.
%   imageIndex = indexImages(imds) indexes the images within imds to create
%   an invertedImageIndex object, imageIndex. imds must be an
%   ImageDatastore object. Use imageIndex with the retrieveImages function
%   to search for images.
% 
%   The indexing procedure uses the bag of feature framework with the SURF
%   detector and extractor to learn a vocabulary of 20000 visual words. The
%   visual words are then used to create an index mapping visual words to
%   the images in imds. The index can be used to search for images within
%   imds that are similar to a given query image:
%
%      imageIDs = retrieveImages(queryImage, imageIndex)
%
%   imageIndex = indexImages(imds, bag) returns a search index created
%   using a custom bagOfFeatures object, bag. Use this syntax to modify the
%   number of visual words or feature type used to index imds.
%
%   [...] = indexImages(...,Name,Value) specifies additional name-value
%   pair arguments described below:
%
%     'SaveFeatureLocations'  Set to true to save feature locations for
%                             post-processing, such as geometric
%                             verification. Set to false to reduce memory
%                             consumption.
%
%                             Default: true
%
%     'Verbose'               Set to true to display progress information.
%
%                             Default: true
%
%   Notes
%   -----
%   - indexImages supports parallel computing using multiple MATLAB
%     workers. Enable parallel computing using the <a href="matlab:preferences('Computer Vision System Toolbox')">preferences dialog</a>.
%
%
% Example 1 - Search for a query image
% ------------------------------------
% % Define a collection of images to index.
% setDir  = fullfile(toolboxdir('vision'),'visiondata','imageSets','cups');
% imds = imageDatastore(setDir);
% 
% % Index the collection of images
% imageIndex = indexImages(imds)
%
% % Select a query image
% queryImage = readimage(imds,2);
% figure
% imshow(queryImage)
%
% % Search for the query image
% indices = retrieveImages(queryImage,imageIndex)
% bestMatchIdx = indices(1); % best result is first
%
% % Display the best match
% bestMatch = imageIndex.ImageLocation{bestMatchIdx}
% figure
% imshow(bestMatch)
%
% Example 2 - Create a search index using a custom bag of features
% ----------------------------------------------------------------
% setDir  = fullfile(toolboxdir('vision'),'visiondata','imageSets','cups');
% imds = imageDatastore(setDir);
%
% % Train a bag of features using a custom feature extractor
% extractor = @exampleBagOfFeaturesExtractor;
% bag = bagOfFeatures(imds,'CustomExtractor',extractor);
% 
% % Use the trained bag of features to index the image set
% imageIndex = indexImages(imds, bag) 
%
% queryImage = readimage(imds,4);
% 
% figure
% imshow(queryImage)
%
% % Search for the image
% indices = retrieveImages(queryImage,imageIndex);
%
% bestMatch = imageIndex.ImageLocation{indices(1)};
% figure
% imshow(bestMatch)
%
% See also retrieveImages, invertedImageIndex, evaluateImageRetrieval, 
%          bagOfFeatures, imageDatastore.

% References
% ----------
% Sivic, J., Zisserman, A.: Video Google: A text retrieval approach to
% object matching in videos. In: ICCV. (2003) 1470-1477
%
% Philbin, J., Chum, O., Isard, M., A., J.S., Zisserman: Object retrieval
% with large vocabularies and fast spatial matching. In: CVPR. (2007)


[bag, params] = parseInputs(imgSet, varargin{:});

printer = vision.internal.MessagePrinter.configure(params.Verbose);

printer.printMessage('vision:indexImages:startIndexing');
printer.print('-------------------------------------------------------\n');

if isempty(bag)
    
    % Disable vocab reduction warning. imgSet may be small.
    prevState    = warning('off','vision:bagOfFeatures:reducingVocabSize');
    resetWarning = onCleanup(@()warning(prevState));
    
    bag = bagOfFeatures(imgSet, 'VocabularySize', 20000, ...
        'PointSelection', 'Detector', ...
        'Upright', false, 'Verbose', params.Verbose, 'UseParallel', params.UseParallel);    
end

index = invertedImageIndex(bag, 'SaveFeatureLocations', params.SaveFeatureLocations);
addImages(index, imgSet, 'UseParallel', params.UseParallel,'Verbose', params.Verbose);

printer.printMessage('vision:indexImages:indexingDone');

% -------------------------------------------------------------------------
function [bag, params] = parseInputs(imgSet, varargin)

validateattributes(imgSet, ...
    {'imageSet', 'matlab.io.datastore.ImageDatastore'}, ...
    {'scalar'}, mfilename, 'imds',1);

if numel([imgSet.Files]) == 0
    error(message('vision:invertedImageIndex:emptyImageSet'));
end

d = getDefaultParameterValues();

p = inputParser();

p.addOptional('Bag', d.Bag, @checkBag);

p.addParameter('Verbose', d.Verbose, ...
    @(x)vision.internal.inputValidation.validateLogical(x,'Verbose'));

p.addParameter('UseParallel', d.UseParallel, ...
    @(x)vision.internal.inputValidation.validateLogical(x,'UseParallel'));

p.addParameter('SaveFeatureLocations', d.SaveFeatureLocations, ...
    @(x)vision.internal.inputValidation.validateLogical(x,'SaveFeatureLocations'));

parse(p,varargin{:});

bag = p.Results.Bag;

params.Verbose              = logical(p.Results.Verbose);
params.UseParallel          = logical(p.Results.UseParallel);
params.SaveFeatureLocations = logical(p.Results.SaveFeatureLocations);

% -------------------------------------------------------------------------
function checkBag(bag)

validateattributes(bag, {'bagOfFeatures'},{},mfilename,'bag');

% -------------------------------------------------------------------------
function defaults = getDefaultParameterValues()
defaults.Bag                  = [];
defaults.Verbose              = true;
defaults.UseParallel          = vision.internal.useParallelPreference();
defaults.SaveFeatureLocations = true;
