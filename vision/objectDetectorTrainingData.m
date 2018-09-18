function trainingData = objectDetectorTrainingData(varargin)
%objectDetectorTrainingData Create training data for an object detector from groundTruth.
%   objectDetectorTrainingData creates training data that can be used to
%   train an object detector from ground truth data. This training data can
%   be used to train an object detector using training functions like
%   trainACFObjectDetector, trainRCNNObjectDetector,
%   trainFastRCNNObjectDetector and trainFasterRCNNObjectDetector.
%
%   trainingData = objectDetectorTrainingData(gTruth) creates training data
%   from ground truth in gTruth. gTruth is an array of groundTruth objects.
%   trainingData is a table with 2 or more columns. The first column
%   contains image file names. The remaining columns contain object
%   locations for rectangular ROI labels in gTruth as M-by-4 matrices of
%   [x, y, width, height] bounding boxes that specify object locations
%   within each image.
%
%   trainingData = objectDetectorTrainingData(..., Name, Value) specifies
%   additional name-value pair arguments as described below:
% 
%   'SamplingFactor'    The sampling factor used to sub-sample images. A
%                       sampling factor N includes every Nth image in the
%                       ground truth data source that does not contain
%                       empty labels. The sampling factor must be 'auto',
%                       or a numeric scalar or vector. 
%
%                          * When sampling factor is 'auto', a sampling
%                            factor of 5 is used for data sources with
%                            timestamps, and a sampling factor of 1 is used
%                            for a collection of images.
%
%                          * When the sampling factor is a scalar, the same
%                            sampling factor is applied to all ground truth
%                            data sources in gTruth.
%
%                          * When the sampling factor N is a vector,
%                            sampling factor N(k) is applied to the data
%                            source in gTruth(k).
%
%                       Default: 'auto'
%
%   The following name-value pair arguments control the writing of image
%   files. These are valid only for groundTruth objects created using a
%   video file or custom data source.
%
%   'WriteLocation'     A scalar string or character vector to specify a 
%                       folder location to which extracted image files are
%                       written. The specified folder must exist and have
%                       write permissions.
%
%                       Default: pwd(current working directory)
%
%   'ImageFormat'       A scalar string or character vector to specify the
%                       image file format used to write images. Supported
%                       formats include all those supported by imwrite.
%
%                       Default: 'png'
%
%   'NamePrefix'        A scalar string or character vector to specify the 
%                       prefix applied to output image file names. The
%                       image files are named as
%                       <name_prefix><image_number>.<image_format>.
%
%                       Default: strcat(sourceName, '_'), where sourceName
%                                is the name of the data source from which
%                                the image is extracted.
%
%   'Verbose'           Set true to display writing progress information.
%
%                       Default: true
%
%
%   Notes
%   -----
%   - The 'WriteLocation', 'ImageFormat', 'NamePrefix' and 'Verbose'
%     name-value pairs are ignored for groundTruth objects created from an
%     image sequence data source.
%
%   - The function supports parallel computing using multiple MATLAB
%     workers. Enable parallel computing using the <a href="matlab:preferences('Computer Vision System Toolbox')">preferences dialog</a>.
% 
%   - For custom data sources in groundTruth, when parallel computing is
%     enabled, the reader function is expected to work with a pool of
%     MATLAB workers to read images from the data source in parallel.
%
%   - Only labels corresponding to rectangle ROI labels are returned in 
%     trainingData. Other labels are ignored.
%
%
%   Example - Train an ACF stop sign detector
%   -----------------------------------------
%
%   % Add the image directory to the MATLAB path
%   imageDir = fullfile(matlabroot, 'toolbox', 'vision', 'visiondata', 'stopSignImages');
%   addpath(imageDir);
%
%   % Load groundTruth data. Ground truth contains data for stops signs and
%   % cars.
%   load('stopSignsAndCarsGroundTruth.mat', 'stopSignsAndCarsGroundTruth')
%
%   % View label definitions to see label types in the ground truth.
%   stopSignsAndCarsGroundTruth.LabelDefinitions
%
%   % Select the stop sign data training
%   stopSignGroundTruth = selectLabels(stopSignsAndCarsGroundTruth, 'stopSign');
%
%   % Create training data for a vehicle object detector
%   trainingData = objectDetectorTrainingData(stopSignGroundTruth);
%   summary(trainingData)
%
%   % Train ACF object detector for vehicles
%   acfDetector = trainACFObjectDetector(trainingData, 'NegativeSamplesFactor', 2);
% 
%   % Test the ACF detector on a test image
%   I = imread('stopSignTest.jpg');
%   bboxes = detect(acfDetector, I);
% 
%   % Display the detected object
%   annotation = acfDetector.ModelName;
%   I = insertObjectAnnotation(I, 'rectangle', bboxes, annotation);
% 
%   figure 
%   imshow(I)
%
%   rmpath(imageDir); % remove the image directory from the path
%
%   See also groundTruth, trainACFObjectDetector, trainRCNNObjectDetector,
%   trainFastRCNNObjectDetector, trainFasterRCNNObjectDetector.

%   Copyright 2017 The MathWorks, Inc.

[gTruth, samplingFactor, writeParams, isVideoOrCustomSource, labelNames] = validateInputs(varargin{:});

sampleIndices = sampleDataSource(gTruth, labelNames, samplingFactor);

imageNames = cell(size(gTruth));
imageNames(isVideoOrCustomSource) = writeImages(gTruth(isVideoOrCustomSource), writeParams, sampleIndices(isVideoOrCustomSource));

trainingData = populateTrainingTable(gTruth, labelNames, sampleIndices, imageNames, isVideoOrCustomSource);
end

%--------------------------------------------------------------------------
function [gTruth, samplingFactor, writeParams, isVideoOrCustomSource, labelNames] = validateInputs(varargin)

inputs = parseInputs(varargin{:});

gTruth                  = inputs.gTruth;
samplingFactor          = inputs.SamplingFactor;
writeParams.Location    = inputs.WriteLocation;
writeParams.Prefix      = inputs.NamePrefix;
writeParams.Format      = inputs.ImageFormat;
writeParams.Verbose     = inputs.Verbose;
writeParams.UseParallel = inputs.UseParallel;

[gTruth,isVideoOrCustomSource, validGTruthIndices, samplingFactor] = ...
    checkGroundTruthSources(gTruth, writeParams.Location, samplingFactor);

labelNames = checkGroundTruthLabelDefinitions(gTruth, validGTruthIndices);

end

%--------------------------------------------------------------------------
function sampleIndices = sampleDataSource(gTruth, labelNames, samplingFactor)
%sampleDataSource sample data source from a groundTruth array
%
%   Inputs
%   ------
%   gTruth          - Array of groundTruth objects with valid (non-empty)
%                     data sources.
%   samplingFactor  - Scalar greater than 1 representing the down sample
%                     factor.
%
%   Outputs
%   -------
%   sampleIndices   - Cell array of the same size as gTruth, containing a
%                     list of indices to sample from gTruth.
%

labelDatas     = {gTruth.LabelData};
samplingFactor =  num2cell(samplingFactor);

sampleIndices = cellfun(@(data, sf)computeSampleIndices(data, labelNames, sf), labelDatas, samplingFactor, 'UniformOutput', false);
end

%--------------------------------------------------------------------------
function samples = computeSampleIndices(labelData, labelNames, samplingFactor)
%computeSampleIndices compute indices to sample from non-empty label data
%
%   Inputs
%   ------
%   labelData       - table or timetable of label data from a single
%                     groundTruth object.
%   labelNames      - cell array of label names for Rectangle label types.
%   samplingFactor  - scalar greater than 1 representing the down sample
%                     factor.
%
%   Outputs
%   -------
%   samples         - row indices into label data to be sampled for
%                     training.
%

labelData = labelData(:, labelNames);

% Find non-empty rows, which can be used for training.
areAllNotEmpty = @(varargin) ~all( cellfun(@isempty, varargin) );
validIndices = find(rowfun(areAllNotEmpty, labelData, 'ExtractCellContents', true, 'OutputFormat', 'uniform'));

% Sample among these rows
samples = validIndices( 1 : samplingFactor : end );
end

%--------------------------------------------------------------------------
function imageNames = writeImages(gTruthVideoOrCustom, writeParams, sampleIndices)
%writeImages writes images from a groundTruth array to disk
%
%   Inputs
%   ------
%   gTruthVideo     - Array of groundTruth objects containing video or
%                     custom data sources.
%   writeParams     - Struct containing fields Location, Prefix and Format
%                     describing parameters used to write images.
%   sampleIndices   - Cell array of the same size as gTruthVideo containing
%                     indices to frames to be written to disk.
%
%   Outputs
%   -------
%   imageNames      - Cell array of full-file image names written to disk.
%

numVideos   = numel(gTruthVideoOrCustom);
imageNames  = cell(size(gTruthVideoOrCustom));

if numVideos==0
    return;
end

addBackSlash = @(origStr)strrep(origStr,'\','\\');

% Create a message printer to print information about image write.
printer = vision.internal.MessagePrinter.configure(writeParams.Verbose);

printer.linebreak;
printer.printMessage('vision:objectDetectorTrainingData:writeBegin', addBackSlash(writeParams.Location));
printer.linebreak;

if writeParams.UseParallel
    % write images in parallel
    
    % Create a pool
    pool = gcp('nocreate');
    if isempty(pool)
        pool = tryToCreateLocalPool();
    end
    
    if ~isempty(pool)
        partitionSize = pool.NumWorkers;
    else
        partitionSize = 16;
    end
    
    % NOTE:
    % In order to work around g1465597, the reader is created inside
    % the parfor loop. Once this is fixed, the reader will be created
    % outside. Because of this, we also want to minimize the number of
    % times a VideoReader object is created (for long sequences, it takes
    % time to set up the timestamp vector). Once this is fixed, a more
    % efficient parallelization strategy can be used.
    
    for n = 1 : numVideos
        dataSource = gTruthVideoOrCustom(n).DataSource;
        videoName = dataSource.Source;
        samples     = sampleIndices{n};
        numImages   = numel(samples);
        
        formattedVideoName = addBackSlash(gTruthVideoOrCustom(n).DataSource.Reader.Name);
        printer.printMessageNoReturn('vision:objectDetectorTrainingData:writeSource', numImages, formattedVideoName);
        printer.print('...');
        
        imageFileNames = computeImageNames(dataSource.Source, samples, writeParams);
        
        numPartitions = ceil( numImages / partitionSize );
        if isVideoFileSource(dataSource)            
            parfor p = 1 : numPartitions           
                % Create videoreader at each worker
                reader = matlab.internal.VideoReader(videoName);
                indices = ((p-1)*partitionSize + 1) : min(p*partitionSize, numImages);
                isCustomSource = false;
                readAndWriteFrames(reader, imageFileNames, samples, indices, isCustomSource);
            end
            
        else
            % Custom data source
            parfor p = 1 : numPartitions                
                reader = dataSource.Reader; %#ok<PFBNS>
                indices = ((p-1)*partitionSize + 1) : min(p*partitionSize, numImages);
                isCustomSource = true;
                readAndWriteFrames(reader, imageFileNames, samples, indices, isCustomSource);
            end
        end
        
        imageNames{n} = imageFileNames;
        
        printer.printMessageNoReturn('vision:objectDetectorTrainingData:completed');
        printer.linebreak;
    end
else
    % write images sequentially
    for n = 1 : numVideos
        dataSource  = gTruthVideoOrCustom(n).DataSource;
        samples     = sampleIndices{n};
        numImages   = numel(samples);
        reader      = dataSource.Reader;
        
        printer.printMessageNoReturn('vision:objectDetectorTrainingData:writeSource', numImages, addBackSlash(reader.Name));
        printer.print('...');
        
        imageFileNames = computeImageNames(dataSource.Source, samples, writeParams);
        
        indices = 1 : numImages;
        readAndWriteFrames(reader, imageFileNames, samples, indices, dataSource.isCustomSource());

        imageNames{n} = imageFileNames;
        
        printer.printMessageNoReturn('vision:objectDetectorTrainingData:completed');
        printer.linebreak;
    end
end
end
%--------------------------------------------------------------------------
function readAndWriteFrames(reader, imageFileNames, samples, indices, isCustomSource)

for idx = indices
    try
        % Read image
        frame = reader.readFrameAtPosition(samples(idx)); 
        
    catch baseME
        % Throw errors coming from VideoReader or CustomReader
        % object as if they are coming from this function. These
        % are errors related to reading frames.
        fprintf('\n');
        newME = baseME;
        if isCustomSource
            newCauseME = MException('vision:groundTruthLabeler:CustomReaderFunctionCallError',...
                vision.getMessage('vision:groundTruthLabeler:CustomReaderFunctionCallError', func2str(reader.Reader)));
            newME = addCause(newME,newCauseME);
        end
        
        throwAsCaller(newME)
    end
    I = frame.Data;
    
    % Write image
    imwrite(I, imageFileNames{idx}); 
end
end
%--------------------------------------------------------------------------
function trainingData = populateTrainingTable(gTruth, labelNames, sampleIndices, imageNames, isVideoOrCustomSource)
%populateTrainingTable populate training data table from groundTruth
%datasources.
%
%   Inputs
%   ------
%   gTruth                 - Array of groundTruth objects.
%   labelNames             - Cell array of label names included in training data.
%   sampleIndices          - Cell array of sample indices into label data table.
%   imageNames             - Cell array of image names pre-populated for video
%                            or custom data sources.
%   isVideoOrCustomSource  - Logical indices to groundTruth array specifying which
%                            groundTruths belong to video or custom data sources.
%
%   Outputs
%   -------
%   trainingData    - training data table that can be fed to training
%                     functions.
%

trainingData = table();
for n = 1 : numel(gTruth)
    if isVideoOrCustomSource(n)
        % Image names have already been populated for video sources or custom data sources.
        imageNameTable = table(imageNames{n}, 'VariableNames', {'imageFilename'});
    else
        % Populate image names
        imageNameTable = table(gTruth(n).DataSource.Source(sampleIndices{n}), 'VariableNames', {'imageFilename'});
    end
    
    % Populate bounding boxes
    if isa(gTruth(n).LabelData, 'timetable')
        bboxes = timetable2table(gTruth(n).LabelData(sampleIndices{n}, labelNames), 'ConvertRowTimes', false);
    else
        bboxes = gTruth(n).LabelData(sampleIndices{n}, labelNames);
    end
    
    % Concatenate with training data table
    trainingData = [trainingData; [imageNameTable bboxes]]; %#ok<AGROW>
end

end


%--------------------------------------------------------------------------
function inputs = parseInputs(varargin)

% Defaults
samplingFactor  = 'auto';
writeLocation   = pwd;
imageFormat     = 'png';
namePrefix      = '';
verbose         = true;

parser = inputParser;

% gTruth
addRequired(parser, 'gTruth', ...
    @(in)validateattributes(in, {'groundTruth'}, {'nonempty', 'vector'}));

% SamplingFactor
addParameter(parser, 'SamplingFactor', samplingFactor);

% WriteLocation
addParameter(parser, 'WriteLocation', writeLocation, ...
    @(in)validateattributes(in,{'char','string'},{'scalartext'}));

% ImageFormat
addParameter(parser, 'ImageFormat', imageFormat, ...
    @validateImageFormat);

% NamePrefix
addParameter(parser, 'NamePrefix', namePrefix, ...
    @(in)validateattributes(in,{'string','char'},{'scalartext'}));

% Verbose
addParameter(parser, 'Verbose', verbose, ...
    @(in)vision.internal.inputValidation.validateLogical(in,'Verbose'));

% UseParallel
addParameter(parser, 'UseParallel', vision.internal.useParallelPreference);

parse(parser, varargin{:});

inputs = parser.Results;

if isString(inputs.SamplingFactor)
    validatestring(inputs.SamplingFactor, {'auto'}, mfilename, 'SamplingFactor');
    inputs.SamplingFactor = autoFillSamplingFactor(inputs.gTruth);
else
    validateattributes(inputs.SamplingFactor, {'numeric'},...
        {'vector','integer', 'positive', 'numel', numel(inputs.gTruth)}, ...
        mfilename, 'SamplingFactor');
    
    if isscalar(inputs.SamplingFactor)
        % expand scalar for each gTruth
        repelem(inputs.SamplingFactor, numel(inputs.gTruth),1);
    end
end

inputs.UseParallel = logical(parser.Results.UseParallel);
if inputs.UseParallel
    % Check for PCT installation
    try
        % GCP will error if PCT is not available.
        gcp('nocreate');
    catch
        inputs.UseParallel = false;
    end
end
end

%--------------------------------------------------------------------------
function s = autoFillSamplingFactor(gTruth)
% Sources with timestamps get a sampling factor of 5. Others get 1.
s = ones(1,numel(gTruth));
i = arrayfun(@(x)istimetable(x.LabelData), gTruth);
s(i) = 5;
end

%--------------------------------------------------------------------------
function tf = isString(s)
tf = ischar(s) || isstring(s);
end

%--------------------------------------------------------------------------
function TF = validateImageFormat(fmt)

try
    fmtStruct = imformats(fmt);
catch
    error(message('vision:objectDetectorTrainingData:unsupportedImageFormat',fmt))
end
if isempty(fmtStruct)
    error(message('vision:objectDetectorTrainingData:unsupportedImageFormat',fmt))
end

TF = true;
end

%--------------------------------------------------------------------------
function [gTruth,isVideoOrCustomSource,validGTruthIndices, samplingFactor] = checkGroundTruthSources(gTruth, writeLocation, samplingFactor)

% Discard empty data sources
dataSources = {gTruth.DataSource};
invalidGTruth = cellfun(@isempty,dataSources);

if all(invalidGTruth)
    error( message( 'vision:objectDetectorTrainingData:NoGroundTruthSources') )
end

gTruth(invalidGTruth) = [];
samplingFactor(invalidGTruth) = [];

validGTruth = ~invalidGTruth;
validGTruth(invalidGTruth) = [];
validGTruthIndices = find(validGTruth);

% Check if any sources point to videos or custom data sources
isVideo = arrayfun(@(x)gTruth(x).DataSource.isVideoFileSource,validGTruthIndices);
isCustomSrc = arrayfun(@(x)gTruth(x).DataSource.isCustomSource,validGTruthIndices);

isVideoOrCustomSource = isVideo | isCustomSrc;

if any(isVideoOrCustomSource)
    vision.internal.inputValidation.checkWritePermissions(writeLocation);
end

end

%--------------------------------------------------------------------------
function labelNames = checkGroundTruthLabelDefinitions(gTruth, originalIndices)

% sort by name
labelDefsStd = sortrows(gTruth(1).LabelDefinitions, 1);

% remove non-rectangle and discard description
labelDefsStd = labelDefsStd(labelDefsStd.Type == 'Rectangle', 1:2);

for n = 2 : numel(gTruth)
    labelDefs = sortrows(gTruth(n).LabelDefinitions, 1);
    labelDefs = labelDefs(labelDefs.Type == 'Rectangle', 1:2);
    
    if ~isequal(labelDefs, labelDefsStd)
        error( message('vision:objectDetectorTrainingData:consistentLabelDefinitions', originalIndices(n)) )
    end
end

labelNames = labelDefsStd.Name;
end

%--------------------------------------------------------------------------
function imageFileNames = computeImageNames(source, samples, writeParams)

folderLocation = writeParams.Location;

if isempty(writeParams.Prefix)
    % Default source name is the name of the video file.
    namePrefix = source;
    
    % Remove path and format from name.
    [~,namePrefix,~] = fileparts(namePrefix);
else
    namePrefix = writeParams.Prefix;
end

indexString  = strrep(cellstr(num2str(samples(:))), ' ', '0');
formatString = ['.' writeParams.Format];
fileNames = strcat(namePrefix, indexString, formatString);

imageFileNames = fullfile( folderLocation, fileNames );

end

%--------------------------------------------------------------------------
function pool = tryToCreateLocalPool()
defaultProfile = ...
    parallel.internal.settings.ProfileExpander.getClusterType(parallel.defaultClusterProfile());

if(defaultProfile == parallel.internal.types.SchedulerType.Local)
    % Create the default pool (ensured local)
    pool = parpool;
else
    % Default profile not local   
    error(message('vision:vision_utils:noLocalPool', parallel.defaultClusterProfile()));    
end
end