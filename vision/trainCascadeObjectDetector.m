function trainCascadeObjectDetector(varargin)
%trainCascadeObjectDetector Train a model for a cascade object detector
%
%   trainCascadeObjectDetector(outputXMLFileName, 
%     positiveInstances, negativeImages) writes a trained cascade 
%   detector xml file with name outputXMLFileName, which must have a 
%   .xml extension. 
%
%   positiveInstances is a two-column table. The first column contains image
%   file names. The images can be grayscale or true color, in any format 
%   supported by IMREAD. The second column contains M-by-4 matrices of 
%   [x y width height] bounding boxes specifying object locations. To create
%   this table, use imageLabeler app. For other ways to specify 
%   positiveInstances, see Reference page for trainCascadeObjectDetector.
% 
%   The actual number of positive samples used at each stage is determined
%   automatically, based on the number of stages and the true positive
%   rate.
%
%   negativeImages is an imageDatastore object. The images it contains are
%   used to generate negative samples, and thus must not contain any objects
%   of interest. Instead, they should contain backgrounds associated with 
%   the object. For other ways to specify negativeImages see Reference page
%   for trainCascadeObjectDetector
%
%   trainCascadeObjectDetector(outputXMLFileName, 'resume')
%   Resumes an interrupted training session. The outputXMLFileName input 
%   must match the output file name from the interrupted session. All 
%   arguments saved from the earlier session will be automatically reused. 
%
%   trainCascadeObjectDetector(..., Name, Value)
%   Specifies additional name-value pair arguments described below:
%
%   Optional parameters are:
%   'ObjectTrainingSize'    - A 2-element vector [height width] specifying  
%                             the size to which objects will be resized 
%                             during the training, or the string 'Auto'. If 
%                             'Auto' is used, the function will determine
%                             the size automatically based on the median
%                             width-height ratio of the positive instances.
%                             Increasing the size may improve detection 
%                             accuracy, but will also increase training and
%                             detection times. 
%
%                             Default: 'Auto'
%
%   'NegativeSamplesFactor' - A real-valued scalar which determines the 
%                             number of negative samples used at a stage as 
%                             a multiple of the number of positive samples. 
%
%                             Default: 2
%
%   'NumCascadeStages'      - The number of cascade stages to train.
%                             Increasing the number of stages may
%                             result in a more accurate detector, but will 
%                             increase the training time. More stages may
%                             require more training images.
%
%                             Default: 20
%
%   'FalseAlarmRate'        - False alarm rate acceptable at each stage. 
%                             The value must be greater than 0 and less
%                             than or equal to 1. The overall target false 
%                             alarm rate of the resulting detector is 
%                             FalseAlarmRate^NumCascadeStages. Lower value 
%                             of FalseAlarmRate may result in fewer false 
%                             detections, but in longer training and
%                             detection times.
%
%                             Default: 0.5
%
%   'TruePositiveRate'      - Minimum true positive rate required at each
%                             stage. The value must be greater than 0 and 
%                             less than or equal to 1. The overall target
%                             true positive rate of the resulting detector 
%                             is TruePositiveRate^NumCascadeStages. 
%                             Increasing this value may increase the number 
%                             of correct detections, at the cost of 
%                             increased training time.
%
%                             Default: 0.995
%
%   'FeatureType'           - A string that specifies the type of features 
%                             to use. Possible values are:
%                              'Haar' - Haar-like features
%                              'LBP'  - Local Binary Patterns
%                              'HOG'  - Histogram of Oriented Gradients
%
%                             Default: 'HOG'
%
%
%    Notes:
%    ------
%    trainCascadeObjectDetector allocates a large amount of memory,
%    especially when the Haar-like features are used. To avoid running out
%    of memory use this function on a 64-bit operating system with a 
%    sufficient amount of RAM.
%    
%    Example - Training a stop sign detector
%    -------------------------------------------
%    % Load the positive samples data from a mat file. The file contains
%    % a table specifying bounding boxes for several object categories.
%    % The table was exported from the Training Image Labeler app.
%    load('stopSignsAndCars.mat');
%
%    % Select the bounding boxes for stop signs
%    positiveInstances = stopSignsAndCars(:, 1:2);
%
%    % Add the image directory to the MATLAB path
%    imDir = fullfile(matlabroot, 'toolbox', 'vision', 'visiondata',...
%       'stopSignImages');
%    addpath(imDir);
%
%    % Specify folder with negative images
%    negativeFolder = fullfile(matlabroot, 'toolbox', 'vision', ...
%       'visiondata', 'nonStopSigns');
%
%    % Create an ImageDatastore object containing negative images
%    negativeImages = imageDatastore(negativeFolder);
%
%    % Train a cascade object detector called 'stopSignDetector.xml'
%    % using HOG features.
%    % NOTE: The command below can take several minutes to run
%    trainCascadeObjectDetector('stopSignDetector.xml', positiveInstances, ...
%       negativeFolder, 'FalseAlarmRate', 0.1, 'NumCascadeStages', 5);
%
%    % Use the newly trained classifier to detect a stop sign in an image
%    detector = vision.CascadeObjectDetector('stopSignDetector.xml');
%
%    img = imread('stopSignTest.jpg'); % read the test image
%
%    bbox = step(detector, img); % detect a stop sign
%
%    % Insert bounding box rectangles and return marked image
%    detectedImg = insertObjectAnnotation(img, 'rectangle', bbox, 'stop sign');
%
%    figure; imshow(detectedImg); % display the detected stop sign
%
%    rmpath(imDir); % remove the image directory from the path
%
%    See also imageLabeler, imageDatastore, 
%    vision.CascadeObjectDetector, insertObjectAnnotation

%   References: 
%   ----------- 
%  [1] Paul Viola and Michael J. Jones "Rapid Object Detection using a
%      Boosted Cascade of Simple Features" IEEE CVPR, 2001
%
%  [2] Rainer Lienhart, Alexander Kuranov, Vadim Pisarevsky
%      "Empirical Analysis of Detection Cascades of Boosted Classifiers 
%      for Rapid Object Detection", DAGM Symposium for Pattern 
%      Recognition, pp. 297-304, 2003    
%
%  [3] Dalal, N. and Triggs, B., Histograms of Oriented Gradients for
%      Human Detection. IEEE CVPR 2005
%
%  [4] T. Ojala, M. Pietikainen and T. Maenpaa.  Multiresolution gray-scale
%      and rotation invariant texture classification with local binary
%      patterns. IEEE Transactions on Pattern Analysis and Machine
%      Intelligence, 24(4), pp. 971-987, 2002

% Copyright 2012-2016 The MathWorks, Inc.

parser = parseInputs(varargin{:});

% Check if outputXMLFileName already exists, If 0 is returned, it means
% file already exists and user chose to abort training
if shouldExitBecauseOutputXMLFileExists(parser.Results.outputXMLFileName)
    return;
end

[filenameParams, trainerParams, cascadeParams, boostParams, ...
    featureParams, totalPosInstances] = populateTrainCascadeParams(parser);

% If the second argument is a string, run the resume procedure
if ischar(filenameParams.positiveInstances)
    % Reload the parameters from the interrupted session
    reloadedParameters = reloadInterruptedTrainingParameters(filenameParams);
    % Populate parameters for ocvTrainCascade
    filenameParams = reloadedParameters.filenameParams;
    trainerParams  = reloadedParameters.trainerParams;
    cascadeParams  = reloadedParameters.cascadeParams;
    boostParams    = reloadedParameters.boostParams;
    featureParams  = reloadedParameters.featureParams;    
    if isfield(reloadedParameters, 'negativeImages')        
        filenameParams.negativeImages = reloadedParameters.negativeImages;
    else
        error(message(...
            'vision:trainCascadeObjectDetector:cannotResumeFromOlderVersion'));
    end
    
    totalPosInstances = ...
        getTotalNumInstances(filenameParams.positiveInstances);
    
% Else normal procedure - Create the required temp files first
else  
    % Create temp folder where results will be saved
    % If function returns 0, it means temporary folder already existed and
    % user chose to not perform any training
    continueTraining = createTempXmlFolder(filenameParams);
    if continueTraining == 0
        return;
    end

    % This try-catch block will delete the temp folder in case the function
    % encounters an error anytime before calling ocvTrainCascade training
    % function. The temp folder may contain negatives description file,
    % positives vec file, and temp mat file
    try
        % If negativeImages is a char array, hence representing a folder, read
        % negative instances from a folder
        if ischar(filenameParams.negativeImagesFolder)
            %Create a negative instances from the negative images folder
            negativeImages = createNegativeInstancesFromFolder( ...
                filenameParams.negativeImagesFolder);
        % Else, it must be a cell array of image filenames. Read negative instances 
        % from these images
        else
            % Create negative instances from image filenames
            negativeImages = filenameParams.negativeImagesFolder;            
        end
    
        filenameParams.negativeImages = negativeImages;        
    
        % Create a positive instances vec file
        % First create a valid filename in the current folder
        filenameParams.positiveVecFilename = fullfile( ...
            filenameParams.tempXmlFoldername, 'positives.vec');   
                
        % Create vec file with the temporary name 
        % Note that createOcvVecFile takes the objectTrainingSize as 
        % [height, width]
        vision.internal.cascadeTrainer.createOcvVecFile(...
            filenameParams.positiveInstances, ...
            totalPosInstances,...            
            filenameParams.positiveVecFilename, ...
            cascadeParams.objectTrainingSize([2,1]));


        % Save the parameters to a mat file
        % in the current directory. This is used in case the user chooses to
        % 'resume' later in case of a crash.
        tempMatFilename = getTempMatFilename(filenameParams);
        save(tempMatFilename, 'filenameParams', 'trainerParams', 'cascadeParams', ...
            'boostParams', 'featureParams', 'negativeImages');
    catch e
        cleanUp(filenameParams);
        throw(e);
    end
        
end

assert(trainerParams.numPositiveSamples <= totalPosInstances);
fprintf('\n');
if isfield(cascadeParams, 'autoObjectTrainingSize') && ...
        cascadeParams.autoObjectTrainingSize
    disp(getString(message('vision:trainCascadeObjectDetector:autoObjectTrainingSize',...
        cascadeParams.objectTrainingSize(2), cascadeParams.objectTrainingSize(1))));
end
disp(getString(message('vision:trainCascadeObjectDetector:maxNumPositiveSamplesUsed', ...
    trainerParams.numPositiveSamples, totalPosInstances)));
disp(getString(message('vision:trainCascadeObjectDetector:maxNumNegativeSamplesUsed', ...
    trainerParams.numNegativeSamples)));
fprintf('\n');

% Run cascade detector OpenCV-mex code
% Use params obtained from parseInputs
ocvTrainCascade(filenameParams, trainerParams, cascadeParams, boostParams, ...
        featureParams);

% Copy the final xml file from tempXmlFolder to outputXmlFilename
copyTempXmlToFinalXml(filenameParams);

% Clean up all temp files and folders
cleanUp( filenameParams );

%
%==========================================================================
% Parse and check inputs
%==========================================================================
function parser = parseInputs(varargin)
% Check that the working directory is writable
[success, attributes] = fileattrib('.');
if ~success || attributes.system == 1 || ~attributes.UserWrite
    error(message('vision:trainCascadeObjectDetector:currentDirNotWriteable'));
end

% Parse the PV pairs
parser = inputParser;

parser.addRequired('outputXMLFileName', @checkOutputXmlFilename);
parser.addRequired('positiveInstances', @checkPositiveInstances);
parser.addOptional('negativeImages', '', @checkNegativeImages);
parser.addParameter('ObjectTrainingSize', 'Auto', ...
    @checkObjectTrainingSize);
parser.addParameter('NegativeSamplesFactor', 2, ...
    @checkNegativeSamplesFactor);
parser.addParameter('NumCascadeStages', 20, ...
    @checkNumCascadeStages);
parser.addParameter('FalseAlarmRate', 0.5, ...
    @checkFalseAlarmRate);
parser.addParameter('FeatureType', 'HOG', ...
    @checkFeatureType);
parser.addParameter('TruePositiveRate', .995, @checkTruePositiveRate);

% If second argument is a string, then we are in "resume" mode
% and the total number of input arguments must be equal to 2
if nargin > 2 && ischar(varargin{2})
    error(message('vision:trainCascadeObjectDetector:invalidResumeCommand'));
end

% Parse input
parser.parse(varargin{:});

%==========================================================================
% Populate the parameters to pass into C++ function ocvTrainCascade()
%==========================================================================
function [filenameParams, trainerParams, cascadeParams, boostParams, ...
    featureParams, totalPosInstances] = populateTrainCascadeParams(parser)

filenameParams.outputXmlFilename = parser.Results.outputXMLFileName;

% Name of the output folder where the trained cascade and intermediate
% cascades will be saved. A temporary mat file will also be saved here.
filenameParams.tempXmlFoldername = getXmlFoldername( filenameParams.outputXmlFilename);

filenameParams.positiveInstances = parser.Results.positiveInstances;

% If positiveInstances is a char array, don't populate any other parameters
if ischar(parser.Results.positiveInstances)
    trainerParams = [];
    cascadeParams = [];
    boostParams = [];
    featureParams =[];
    totalPosInstances = -1;
    return;
elseif istable(filenameParams.positiveInstances)
    validateattributes(filenameParams.positiveInstances, ...
        {'table'}, {'ncols', 2}, mfilename);
    filenameParams.positiveInstances.Properties.VariableNames{1} = ...
        'imageFilename';
    filenameParams.positiveInstances.Properties.VariableNames{2} = ...
        'objectBoundingBoxes';
    filenameParams.positiveInstances = ...
        table2struct(filenameParams.positiveInstances);
end
    
    
% Else populate all other parameters
if isa(parser.Results.negativeImages, 'matlab.io.datastore.ImageDatastore')
    filenameParams.negativeImagesFolder = parser.Results.negativeImages.Files;
else
    filenameParams.negativeImagesFolder = parser.Results.negativeImages;
end


% count the bounding boxes and also check the their validity
totalPosInstances = getTotalNumInstances(filenameParams.positiveInstances);

% Size of training examples in pixels (all examples will be resized to this
% size)
if ischar(parser.Results.ObjectTrainingSize) % auto
    cascadeParams.objectTrainingSize = int32(determineObjectTrainingSizeWH(...
        filenameParams.positiveInstances));
    cascadeParams.autoObjectTrainingSize = true;
else
    % OpenCV defines size as [width, height]    
    cascadeParams.objectTrainingSize ...
        = int32(parser.Results.ObjectTrainingSize([2,1]));
end

if strcmpi(parser.Results.FeatureType, 'HOG') && ...
        min(cascadeParams.objectTrainingSize) < 16
    error(message(...
        'vision:trainCascadeObjectDetector:objectTrainingSizeTooSmallForHOG'));
end

% Maximum desired false alarm rate at each stage
boostParams.falseAlarmRate           = parser.Results.FalseAlarmRate;

% Minimum desired true positive rate at each stage
boostParams.minHitRate               = parser.Results.TruePositiveRate;

% Number of cascade stages to train
trainerParams.numCascadeStages       = parser.Results.NumCascadeStages;

% Maximum number of positive samples used in each stage
minPositivesForFilteringOut = floor(1 / (1 - boostParams.minHitRate));
if minPositivesForFilteringOut >= totalPosInstances
    trainerParams.numPositiveSamples = totalPosInstances;
else
    trainerParams.numPositiveSamples = ...
        max(floor(totalPosInstances / ...
            (1 + (trainerParams.numCascadeStages - 1) * (1 - boostParams.minHitRate))),...
            minPositivesForFilteringOut);
end

% numNegativeSamples is numPositiveSamples times NegativeSamplesFactor. These
% many negative examples will be used for training each stage.
trainerParams.numNegativeSamples = parser.Results.NegativeSamplesFactor *...
    trainerParams.numPositiveSamples;
minNumSamples = 10;
if trainerParams.numPositiveSamples + trainerParams.numNegativeSamples ...
        <= minNumSamples
    error(message('vision:trainCascadeObjectDetector:notEnoughSamples', ...
        minNumSamples));
end

% Type of features to use HAAR/LBP/HOG
cascadeParams.featureType            = parser.Results.FeatureType;

% Call validatestring again and set featureName to the matched string 
% this will ensure that a partial matching featureName is now saved as its
% full value
cascadeParams.featureType = validatestring(cascadeParams.featureType,...
    {'Haar', 'LBP', 'HOG'});
% Change MATLAB input 'Haar' to C++ expected 'haar'
if strcmp(cascadeParams.featureType, 'Haar')
    cascadeParams.featureType = 'haar';
end

%--------------------------------------------------------------------------
% Other OpenCV parameters which are not exposed in the main interface
%--------------------------------------------------------------------------
% precalcValBufSize - Size of buffer for precalculated feature values in MB
trainerParams.precalcValBufSize       = 256;

% precalcIdxBufSize - Size of buffer for precalculated feature indices in MB
trainerParams.precalcIdxBufSize       = 256;

% Saves old format cascade for haar features - should be false usually
% Must be false if cascadeParams.featureType is HOG or LBP
trainerParams.oldFormatSave           = false;

% Type of stages to use (Only boosted classifier supported as of now)
% cascade stage type ('BOOST')
cascadeParams.stageType               = 'BOOST';

% boost parameters
% boosting type ('DAB','RAB', 'LB','GAB')
%  'DAB' - Discrete AdaBoost, 'RAB' - Real AdaBoost, 'LB' - LogitBoost,
%  'GAB' - Gentle AdaBoost
boostParams.boostingType              = 'GAB';

% Specifies whether weight trimming is to be used and its weight
boostParams.weightTrimRate            = .95;

% Maximum depth of weak tree - 1 means classifier is a stump
boostParams.maxDepth                  = 1;

% Maximum weak tree count. At each stage, at most these many weak trees will
% be learned in order to achieve the FalseAlarmRate for the stage.
boostParams.maxWeakCount              = 100;

% haarFeature parameters ('BASIC', 'CORE', 'ALL')
%  'BASIC' - Only upright features, 'ALL' - Uses upright along with 45 degree
%   rotated features
featureParams.mode                    = 'BASIC';

%==========================================================================
function tf = checkOutputXmlFilename(str)
validateattributes(str,...
    {'char'},...
    {'nonempty', 'nonsparse', 'vector'},...
    mfilename, 'outputXMLFileName', 1);
% Valid outputXmlFilename must end in '.xml'
if ~strcmpi( str(end-3:end), '.xml')
    error( message('vision:trainCascadeObjectDetector:invalidXmlExtension'));
end
% Valid outputXmlFilename must not have a folder name attached to it
% If '\' or '/' is found, throw error
if ~isempty(strfind(str,'/')) || ~isempty(strfind(str,'\'))
    error( message('vision:trainCascadeObjectDetector:invalidXmlFilepath'));
end
tf = true;

%==========================================================================
function tf = checkPositiveInstances(positiveInstances)
% Check if struct
validateattributes(positiveInstances,...
    {'struct', 'char', 'table'},...
    {'nonempty', 'nonsparse'},...
    mfilename, 'positiveInstances', 2);
% If positiveInstances is a struct
if isstruct(positiveInstances)
    %Check the fields
    if(~isfield( positiveInstances, 'imageFilename'))
        error( message('vision:trainCascadeObjectDetector:structFieldNotFound', ...
            'imageFilename'));
    end
    if(~isfield(positiveInstances, 'objectBoundingBoxes'))
        error( message('vision:trainCascadeObjectDetector:structFieldNotFound', ...
            'objectBoundingBoxes'));
    end
% Else if it is a char array
elseif ischar(positiveInstances)
    % If input string does not exactly match 'resume', throw error
    if ~strcmp(positiveInstances, 'resume')
        error(message('vision:trainCascadeObjectDetector:invalidResumeString'));
    end
end
tf = true;

%==========================================================================
function tf = checkNegativeImages(negativeImages)
validateattributes(negativeImages,...
    {'char', 'cell', 'matlab.io.datastore.ImageDatastore'},...
    {'nonempty', 'nonsparse'},...
    mfilename, 'negativeImages', 3);
% negativeImages can be either a string or a cell array of strings
% If it is a string, check that the folder exists
if ischar(negativeImages)
    if ~exist(negativeImages, 'dir')
        error(message('vision:trainCascadeObjectDetector:negativesFolderNotFound', ...
            negativeImages));
    end
% If it is an cell array, check that each element is a string and that each
% string is a valid file
else
    if isa(negativeImages, 'matlab.io.datastore.ImageDatastore')
        negativeImages = negativeImages.Files;
    end
    
    % If cell, it must a vector
    validateattributes(negativeImages, ...
        {'cell'}, ...
        {'vector'});
    
    if isempty(negativeImages)
        error(message('vision:trainCascadeObjectDetector:noNegativeImages'));
    end
    % Each element in the cell array must be a string
    disableImfinfoWarnings();
    for i = 1:length(negativeImages)
        if ~ischar(negativeImages{i})
            enableImfinfoWarnings();
            error(message('vision:trainCascadeObjectDetector:invalidNegativesName', ...
                 i));
        else        
            try                
                imfinfo(negativeImages{i});                
            catch
                enableImfinfoWarnings();
                error(message('vision:trainCascadeObjectDetector:cannotOpenImage',...
                    negativeImages{i}, i));
            end
        end
    end
    enableImfinfoWarnings();    
end
tf = true;

%==========================================================================
function tf = checkObjectTrainingSize(objectTrainingSize)
if ischar(objectTrainingSize)
    validatestring(objectTrainingSize, {'Auto'}, mfilename, ...
        'ObjectTrainingSize');
else
    validateattributes(objectTrainingSize,...
        {'numeric'},...
        {'nonempty', 'nonsparse', 'vector', 'integer', 'positive', 'numel', 2, ...
        '>', 3}...
        , mfilename, 'ObjectTrainingSize');
end
tf = true;

%==========================================================================
function tf = checkNegativeSamplesFactor(number)
validateattributes(number,...
    {'numeric'},...
    {'nonempty', 'scalar', 'positive', 'finite'}...
    , mfilename, 'NegativeSamplesFactor');
tf = true;

%==========================================================================
function tf = checkNumCascadeStages(number)
validateattributes(number,...
    {'numeric'},...
    {'nonempty', 'scalar', 'integer', 'positive'}...
    , mfilename, 'NumCascadeStages');
tf = true;

%==========================================================================
function tf = checkFalseAlarmRate(number)
validateattributes(number,...
    {'double', 'single'},...
    {'nonempty', 'scalar', 'real', 'positive', '<=', 1},...
    mfilename, 'StageFalseAlarmRate');
tf = true;

%==========================================================================
function tf = checkFeatureType(featureName)
validatestring(featureName,...
    {'Haar', 'LBP', 'HOG'},...
    mfilename, 'FeatureType');
tf = true;

%==========================================================================
function tf = checkTruePositiveRate(number)
validateattributes(number,...
    {'double', 'single'},...
    {'nonempty', 'scalar', 'real', 'positive', '<=', 1},...
    mfilename, 'StageFalseAlarmRate');
tf = true;

%==========================================================================
function instances = createNegativeInstancesFromFolder(imagesFoldername)

% createNegativeInstancesFromFolder Creates a struct array with information about 
%  image names for all images that exist in the folder called foldername
%  instances = createNegativeInstancesFromFolder(imagesFoldername)
%  Returns a cell array that contains image filenames 
%  All files in the folder that are readable with imread are included in the
%  cell array.

instances = [];
numImages = 0;

% Check if folder exists
if ~exist(imagesFoldername, 'dir')
    error( message('vision:trainCascadeObjectDetector:negativesFolderNotFound', ...
        imagesFoldername));
end

D = dir(imagesFoldername);

for i = 1:size(D,1)
    % If this is not . or ..
    if (D(i).name(1)~='.')
        % Read only valid file extension fileExt
        imgName = D(i).name;
        imgFullName = fullfile(imagesFoldername, imgName); 
        
        % Read image. If empty is returned, then the name is not a valid
        % image filename
        tempImg = vision.internal.cascadeTrainer.readImage(imgFullName);
        
        if ~isempty(tempImg)
            numImages = numImages+1;
            instances{numImages} = imgFullName; %#ok
        end
    end
end
% Throw error if number of images is 0
if numImages==0
    error(message('vision:trainCascadeObjectDetector:noNegativeImages'));
end


%==========================================================================
% Function that returns number of BoundingBoxes in a instances struct array
% Additionally checks that each imageFilename and boundingBoxes are
% valid
function totalNumInstances = getTotalNumInstances(instances)
% Determine total number of instances
totalNumInstances = 0;

for imgNum = 1:numel(instances)
    currentImageName = instances(imgNum).imageFilename;
    % Validate that current image name is valid. If error, catch it and
    % throw error from catalog
    try
        validateattributes(currentImageName,...
        {'char'},...
        {'nonempty', 'nonsparse','vector'},...
        mfilename, 'outputXMLFileName', 1);
    catch e
        error( message('vision:trainCascadeObjectDetector:invalidImageFilename', ...
            imgNum));
    end
    
    % Open image using readImage. If succeeds (returns non-zero image),
    % then proceed. Else, error out.
    tmpImg = vision.internal.cascadeTrainer.readImage(currentImageName);
    if isempty(tmpImg)
        error( message('vision:trainCascadeObjectDetector:cannotOpenPositiveImage', ...
            currentImageName, imgNum));
    end
        
    currentBoundingBoxes = instances(imgNum).objectBoundingBoxes;
    if (~ismatrix(currentBoundingBoxes)) || (size(currentBoundingBoxes, 2)~=4) ...
            || (size(currentBoundingBoxes, 1)==0)
        error( message('vision:trainCascadeObjectDetector:invalidBoundingBoxes', ...
            imgNum, currentImageName));
    end 
    totalNumInstances = totalNumInstances + size(currentBoundingBoxes, 1);
end

if totalNumInstances==0
    error( message('vision:trainCascadeObjectDetector:noPositiveExamples'));
end

%==========================================================================
function objectTrainingSizeWH = ...
    determineObjectTrainingSizeWH(instances)

bboxes = vertcat(instances(:).objectBoundingBoxes);
ratios = bboxes(:, 3) ./ bboxes(:, 4);
r = median(ratios);
if r > 1
    h = 32;
    w = h * r;
else
    w = 32;
    h = w / r;
end

% OpenCV defines size as [width, height]
objectTrainingSizeWH = round([w, h]);

%==========================================================================
% Function that generates a filename for the temporary mat file where the
% training parameters are saved
function matFilename = getTempMatFilename( filenameParams)
    matFilename = fullfile(filenameParams.tempXmlFoldername, ...
       'parameters.mat');
    
%==========================================================================
% Function that returns a foldername derived from str by stripping out the
% '.xml' in the end
function foldername = getXmlFoldername(str)
foldername = str(1:end-4);
if isempty(foldername)
    error(message('vision:trainCascadeObjectDetector:invalidOutputFilename'));
end
foldername = sprintf('%s_trainCascadeTemp', foldername);

%==========================================================================
% Function that checks if output xml file already exists
% If output already exists, will prompt user to overwrite the existing
% file or exit training without making any changes.
% Returns 0 if user chooses to exit training, 1 if file did not exist, 2 if
% user chose to overwrite existing file
function result = shouldExitBecauseOutputXMLFileExists(outputXmlFilename)
% Check if the outputXmlFilename already exists
if exist(outputXmlFilename, 'file')
    % If it does, then issue prompt to user to overwrite file or return with
    % no changes
    msg = message('vision:trainCascadeObjectDetector:xmlFileAlreadyExistsPrompt', ...
        outputXmlFilename);
    while true
        disp(msg.getString);
        reply = input('', 's');
        if isequal(reply,'1')
            % Delete existing xml file
            disp(getString(message(...
                'vision:trainCascadeObjectDetector:deletingXMLFile',...
                outputXmlFilename)));
            delete(outputXmlFilename);
            result = false;
            break;
        elseif isempty(reply) || isequal(reply,'2')
            result = true;
            break;
        end
    end
    % If outputXmlFile does not exist
else
    result = false;
end

%==========================================================================
% Function that creates a temporary folder where OpenCV will write the
% intermediate stage information
% If folder already exists, will prompt user to overwrite the existing
% folder or exit training without making any changes.
% Returns 0 if user chose to exit training, 1 if folder did not exist, 2 if
% user chose to overwrite existing folder
function result = createTempXmlFolder(filenameParams)
% Check if the tempXmlFolder already exists
if exist(filenameParams.tempXmlFoldername, 'dir')
    % If it does, then issue prompt to user to delete and restart or use
    % 'resume' option
    msg = message('vision:trainCascadeObjectDetector:tempFolderAlreadyExistsPrompt', ...
        filenameParams.outputXmlFilename, filenameParams.outputXmlFilename);
    
    while true
        disp(msg.getString);
        reply = input('', 's');
        
        if isequal(reply,'1')
            % Delete existing folder contents
            disp(getString(message(...
                'vision:trainCascadeObjectDetector:deletingTempDirectory')));
            filenamesToDelete = fullfile(filenameParams.tempXmlFoldername, '*');
            delete(filenamesToDelete);
            result = 1;
            return;
        elseif isempty(reply) || isequal(reply,'2')
            result = 0;
            return;
        end
    end
    % If tempXmlFolder does not exist, create a new one
else
    mkdir (filenameParams.tempXmlFoldername);
    result = 2;
end

%==========================================================================
% Function that cleans up the temp files and folder created during training
function cleanUp( filenameParameters )
% Delete the temp negative images description file, if it exists
if isfield(filenameParameters, 'negativeImagesDescFilename')
    if (exist(filenameParameters.negativeImagesDescFilename, 'file')==2)
        delete(filenameParameters.negativeImagesDescFilename);
    end
end

% Delete the temp vec file, if it exists
if isfield(filenameParameters, 'positiveVecFilename')
    if (exist(filenameParameters.positiveVecFilename, 'file')==2)
        delete(filenameParameters.positiveVecFilename);
    end
end

% Delete the temp mat file where parameters were saved, if it exists
tempMatFilename = getTempMatFilename(filenameParameters);
    if (exist(tempMatFilename, 'file')==2)
        delete(tempMatFilename);
    end
% Delete the tempXmlFolder that contains intermediate cascade stages
deleteFolder(filenameParameters.tempXmlFoldername);

%==========================================================================
% Function that deletes a folder after emptying it
function deleteFolder(foldername)
% Delete existing folder contents
success = rmdir(foldername, 's');
if ~success
    warning(message('vision:trainCascadeObjectDetector:cannotDeleteTempDir', foldername));
end

%==========================================================================
% Function that moves the final cascade xml file from tempXmlFolder to user
% specified outputXmlFilename
function copyTempXmlToFinalXml(params)
finalXmlFilename = fullfile(params.tempXmlFoldername, 'cascade.xml');
success = copyfile(finalXmlFilename, params.outputXmlFilename, 'f');
if ~success
    error(message('vision:trainCascadeObjectDetector:finalXmlWriteError', ...
        params.outputXmlFilename, finalXmlFilename));
end

%==========================================================================
% Function that loads an earlier saved training session. Checks if the 
% positiveInstances field in the params struct is 'resume'. If so, loads the
% earlier saved mat file with all parameters required for ocvTrainCascade 
function parameters = reloadInterruptedTrainingParameters(filenameParams)

% Check that temp xml folder exists
if(~exist(filenameParams.tempXmlFoldername, 'dir'))
    error(message('vision:trainCascadeObjectDetector:cannotFindResumeCascadeFolder', ...
        filenameParams.tempXmlFoldername));
end    
    
% Get temp mat filename
tempMatFilename = getTempMatFilename(filenameParams);
% If this file does not exist, throw error
if(~exist(tempMatFilename, 'file'))
    error(message('vision:trainCascadeObjectDetector:cannotFindTempMatFile', ...
        tempMatFilename));
% Else
else
    % Load the parameters mat file
    parameters = load(tempMatFilename);
    % Ensure that all required temporary files exist
    % Check that positive instances vec file exists
    if(~exist(parameters.filenameParams.positiveVecFilename, 'file'))
        error(message('vision:trainCascadeObjectDetector:cannotFindResumeVecFile', ...
            parameters.filenameParams.positiveVecFilename));
    end 
end

%------------------------------------------------------------------------
function disableImfinfoWarnings()
imfinfoWarnings('off');

%------------------------------------------------------------------------
function enableImfinfoWarnings()
imfinfoWarnings('on');

%------------------------------------------------------------------------
function imfinfoWarnings(onOff)
warnings = {'MATLAB:imagesci:tifftagsread:badTagValueDivisionByZero',...
            'MATLAB:imagesci:tifftagsread:numDirectoryEntriesIsZero',...
            'MATLAB:imagesci:tifftagsread:tagDataPastEOF'};
for i = 1:length(warnings)
    warning(onOff, warnings{i});
end


