%evaluateImageRetrieval Evaluate image search results 
% averagePrecision = evaluateImageRetrieval(queryImage, imageIndex, expectedIDs) 
% returns the average precision metric for measuring the accuracy of image
% search results for the query image, queryImage. imageIndex is an
% invertedImageIndex object created using the indexImages function.
% expectedIDs is a vector of indices that correspond to images within
% imageIndex.ImageLocation that are known to be visually similar to
% queryImage.
%
% [..., imageIDs, scores] = evaluateImageRetrieval(...) optionally returns
% the indices corresponding to images within imageIndex that are visually
% similar to queryImage and the similarity scores. The scores are computed
% using the cosine similarity and range from 0 to 1.
%
% [...] = evaluateImageRetrieval(..., Name, Value) specifies additional
% name-value pair arguments described below:
%
%  'NumResults'  Specify the maximum number of search results to evaluate.
%                Set this to N to evaluate the top N search results and
%                return the average-precision-at-N metric.
%
%                Default: Inf
%
%  'ROI'         A vector of the format [x y width height], specifying a
%                rectangular search region within the query image.
%                
%                Default: [1 1 size(queryImage,2) size(queryImage,1)]
%
% Example 1 - Evaluate retrieval results
% --------------------------------------
% % Define a set of images
% dataDir = fullfile(toolboxdir('vision'),'visiondata','bookCovers');
% bookCovers = imageDatastore(dataDir);
%
% % Index the images
% imageIndex = indexImages(bookCovers);   % This will take a few minutes
%                                         
% % Select and display the query image
% queryDir = fullfile(dataDir,'queries',filesep);
% query = imread([queryDir 'query3.jpg']);
%
% figure
% imshow(query)
% 
% % Evaluation requires knowing the expected results. Here, the query
% % image is known to be the 3rd book in the imageIndex.
% expectedID = 3;
% 
% % Get the average precision score
% [averagePrecision, actualIDs] = evaluateImageRetrieval(query, imageIndex, expectedID);
% 
% fprintf('Average Precision is %f\n\n',averagePrecision)
% 
% % Show the query and best match side-by-side
% bestMatch = actualIDs(1);
% bestImage = imread(imageIndex.ImageLocation{bestMatch});
% 
% figure
% imshowpair(query,bestImage,'montage')
%
% Example 2 - Compute the Mean Average Precision (MAP)
% ----------------------------------------------------
% 
% % Define a set of images
% dataDir = fullfile(toolboxdir('vision'),'visiondata', 'bookCovers');
% bookCovers = imageDatastore(dataDir);
% 
% imageIndex = indexImages(bookCovers);   % This will take a few minutes.
%
% % Create a set of query images 
% queryDir = fullfile(dataDir,'queries',filesep);
% querySet = imageDatastore(queryDir);
%
% % Specify the expected search results for each query image.
% expectedIDs = [1 2 3];              
%
% % Evaluate each query image and collect average precision scores
% for i = 1:numel(querySet.Files)
%     query = readimage(querySet,i);
%     averagePrecision(i) = evaluateImageRetrieval(query, imageIndex, expectedIDs(i));
% end
% 
% % Compute Mean Average Precision (MAP)
% map = mean(averagePrecision)
% 
% See also retrieveImages, indexImages, invertedImageIndex, imageDatastore.

function [avgPrecision, actualIDs, scores] = evaluateImageRetrieval(queryImage, imageIndex, expectedIDs, varargin)

params = parseInputs(queryImage, imageIndex, expectedIDs, varargin{:});

[actualIDs, scores] = retrieveImages(queryImage, imageIndex, params);

if isfinite(params.NumResults)
    % average-precision-at-N
    avgPrecision = vision.internal.averagePrecision(actualIDs(:), expectedIDs(:), params.NumResults);
else
    % average precision over all expectedIDs
    avgPrecision = vision.internal.averagePrecision(actualIDs(:), expectedIDs(:));
end

% -------------------------------------------------------------------------
function params = parseInputs(queryImage,imageIndex,expectedIDs, varargin)
vision.internal.inputValidation.validateImage(queryImage,'queryImage');

validateattributes(imageIndex, {'invertedImageIndex'},{}, mfilename, 'imageIndex',2);

validateattributes(expectedIDs, {'numeric'}, ...
    {'vector','integer','positive','real','nonsparse','finite'},...
    mfilename,'expectedIDs')

% parse optional parameters
defaults  = getParameterDefaults();
parser    = inputParser;

parser.addParameter('NumResults', defaults.NumResults, @checkNumberOfResults);
parser.addParameter('ROI',        defaults.ROI,        @(x)vision.internal.detector.checkROI(x,size(queryImage)));

parse(parser, varargin{:});

params.NumResults  = double(parser.Results.NumResults);

wasROISpecified = ~ismember('ROI', parser.UsingDefaults);

if wasROISpecified
    params.ROI = double(round(parser.Results.ROI));
end

% -------------------------------------------------------------------------
function defaults = getParameterDefaults()

defaults.NumResults = inf; % by default, measure all results
defaults.ROI        = [];

% -------------------------------------------------------------------------
function checkNumberOfResults(n)
attrib = {'scalar','real','nonsparse','nonnan','positive'};
if isfinite(n)
    % add integer for non-inf
    attrib =  [attrib 'integer']; 
end
validateattributes(n, {'numeric'}, attrib, mfilename, 'NumResults');

