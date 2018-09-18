%retrieveImages Search for similar images
%   imageIDs = retrieveImages(queryImage, imageIndex) uses the
%   invertedImageIndex, imageIndex, to return indices of images that are
%   visually similar to the queryImage. The imageIDs are returned in ranked
%   order, from best to worst. queryImage must be a truecolor or grayscale
%   image. imageIndex is created using the indexImages function. The image
%   search uses a bag of features approach to find similar images.
%   
%   [..., scores] = retrieveImages(...) optionally returns the similarity
%   scores used to rank the image retrieval results. The scores are
%   computed using the cosine similarity and range from 0 to 1.
%
%   [..., imageWords] = retrieveImages(...) optionally returns the visual
%   words in queryImage that are used to search for similar images.
%   imageWords is a visualWords object that stores the visual word assignments
%   and their locations within queryImage. The <a href="matlab:helpview(fullfile(docroot,'toolbox','vision','vision.map'),'retrieveImagesVerification')">geometric verification</a>
%   example shows how to use the imageWords data.
%
%   [...] = retrieveImages(...,Name,Value) specifies additional name-value
%   pair arguments described below:
%
%   'NumResults'   Specify the maximum number of search results to return.
%                  Set this to Inf to return as many matching images as
%                  possible.
%                  
%                  Default: 20
%
%   'ROI'          A vector of the format [x y width height], specifying a
%                  rectangular search region within the query image.
%
%                  Default: [1 1 size(queryImage,2) size(queryImage,1)]
%
% Class Support
% -------------
% The input image queryImage can be uint8, int16, double, single, or logical.
%
% Example 1 - Search by Image
% ---------------------------
% % Define a set of images
% dataDir = fullfile(toolboxdir('vision'),'visiondata','bookCovers');
% bookCovers = imageDatastore(dataDir);
% 
% % Index the images
% imageIndex = indexImages(bookCovers); % This may take a few minutes
% 
% % Select and display the query image
% queryDir = fullfile(dataDir,'queries',filesep);
% queryImage = imread([queryDir 'query3.jpg']);
% 
% imageIDs = retrieveImages(queryImage, imageIndex);
% 
% % Show the query and best match side-by-side
% bestMatch = imageIDs(1);
% bestImage = imread(imageIndex.ImageLocation{bestMatch});
% 
% figure
% imshowpair(queryImage,bestImage,'montage')
% 
% Example 2 - Search for objects using ROIs
% -----------------------------------------
% % Define a set of images to search
% imageFiles = ...
%     {'elephant.jpg', 'cameraman.tif', ...
%     'peppers.png',  'saturn.png',...
%     'pears.png',    'stapleRemover.jpg', ...
%     'football.jpg', 'mandi.tif',...
%     'kids.tif',     'liftingbody.png', ...
%     'office_5.jpg', 'gantrycrane.png',...
%     'moon.tif',     'circuit.tif', ...
%     'tape.png',     'coins.png'};
%                             
% imds = imageDatastore(imageFiles);
% 
% % Create a search index
% imageIndex = indexImages(imds);
% 
% % Specify a query image and an ROI to search for the elephant
% queryImage = imread('clutteredDesk.jpg');
% queryROI = [130 175 330 365]; 
%
% figure
% imshow(queryImage)
% rectangle('Position',queryROI,'EdgeColor','yellow')
%
% % You can also use IMRECT to interactively select a ROI
% %   queryROI = getPosition(imrect)
%
% % Find images that contain the elephant 
% imageIDs = retrieveImages(queryImage,imageIndex,'ROI',queryROI)
% 
% bestMatch = imageIDs(1);
% 
% figure
% imshow(imageIndex.ImageLocation{bestMatch})
%
% See also indexImages, evaluateImageRetrieval, invertedImageIndex 
%          bagOfFeatures, imageDatastore.

% References
% ----------
% Sivic, J., Zisserman, A.: Video Google: A text retrieval approach to object
% matching in videos. In: ICCV. (2003) 1470-1477
%
% Philbin, J., Chum, O., Isard, M., A., J.S., Zisserman: Object retrieval with
% large vocabularies and fast spatial matching. In: CVPR. (2007)

function [imageIDs, scores, varargout] = retrieveImages(queryImage, imageIndex, varargin)

nargoutchk(0,3);

params = parseInputs(queryImage, imageIndex, varargin{:});

queryImage = vision.internal.detector.cropImageIfRequested(queryImage, params.ROI, params.UsingROI); 

[imageIDs, scores, queryWords] = search(imageIndex, queryImage, ...
    'NumResults', params.NumResults);

if nargout==3
    if params.UsingROI
        queryWords = addROIOffset(queryWords,params.ROI);
    end
    varargout{1} = queryWords;
end

% -------------------------------------------------------------------------
function params = parseInputs(queryImage, imageIndex, varargin)

vision.internal.inputValidation.validateImage(queryImage,'queryImage');

validateattributes(imageIndex, {'invertedImageIndex'}, {}, mfilename, 'imageIndex',2);

% parse optional parameters
defaults = getParameterDefaults();
parser   = inputParser;

parser.addParameter('NumResults',  defaults.NumResults,  @checkNumberOfResults);
parser.addParameter('ROI',         defaults.ROI,         @(x)vision.internal.detector.checkROI(x,size(queryImage)));

parse(parser, varargin{:});

params.NumResults  = double(parser.Results.NumResults);
params.ROI         = parser.Results.ROI;
params.UsingROI    = ~ismember('ROI', parser.UsingDefaults);

% -------------------------------------------------------------------------
function defaults = getParameterDefaults()

defaults.NumResults = 20;
defaults.ROI        = [];

% -------------------------------------------------------------------------
function checkNumberOfResults(n)
attrib = {'scalar','real','nonsparse','nonnan','positive'};
if isfinite(n)
    % add integer for non-inf
    attrib =  [attrib 'integer']; 
end
validateattributes(n, {'numeric'}, attrib, mfilename, 'NumResults');

    
