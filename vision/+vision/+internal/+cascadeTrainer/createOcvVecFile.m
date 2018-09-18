function createOcvVecFile(positives, totalNumInstances,...
    outputVecFilename, objectTrainingSize)
%function createOcvVecFile(positives, outputVecFilename, sampleWidth, ...
%  sampleHeight) writes an OpenCV style "vec" file to be used for training 
%  a cascade object detector.
%
%    positives           struct array that contains image file names with 
%                        the associated bounding boxes.
% 
%    totalNumInstances   number of bounding boxes in all images, should be
%                        computed in trainCascadeObjectDetector.
%
%    outputVecFilename   name of the output vec file
%
%    objectTrainingSize  [sampleHeight, sampleWidth], the size to which all 
%                        samples will be resized

vecFile = openOutputVecFile(outputVecFilename);

writeHeader(vecFile, totalNumInstances, objectTrainingSize);

% count the number of samples written as a sanity check
samplesWritten = 0;

for imgNum = 1:length(positives)
    
    boundingBoxes = getBoundingBoxes(positives, imgNum, vecFile);
    img = readImage(positives, imgNum, vecFile);
    
    % readImage returns [] if it tries to read a non-image file.
    % Skipping silently.
    if ~isempty(img)
        
        % If img is color, convert it to grayscale
        if ndims(img) == 3
            img = rgb2gray(img);
        end
    
        % For each instance in image
        for boundingBoxNum = 1:size(boundingBoxes, 1)            
            % Extract the sub-image specified by the bounding box
            imgPatch = cropROI(img, boundingBoxes, boundingBoxNum, ...
                imgNum, vecFile);
            
            % Resize the sub-image to [sampleHeight sampleWidth]
            % Note that width and height must be revesed to comply with
            % imresize convention.
            imgPatchResize = imresize(imgPatch, objectTrainingSize);

            % Write to image data to vec file
            writeImageInfoToVecFile(imgPatchResize, vecFile.id);
            samplesWritten = samplesWritten + 1;
        end
    end
end

% If everything succeeds, close the outputVecFile.
fclose(vecFile.id);

% Sanity check. Must always pass.
assert(samplesWritten == totalNumInstances);

%==========================================================================
% Create a new output vec file with validation
% Return a struct with fields 
%   name   the file name
%   id     the file id returned by fopen
% Error if unable to create the file
function vecFile = openOutputVecFile(outputVecFilename)
% trainCascadeObjectDetector.m has already checked to ensure that a file
% with this name does not already exist
vecFile.name = outputVecFilename;
vecFile.id = fopen(vecFile.name, 'w');
if(vecFile.id ==  -1)
    error(message('vision:trainCascadeObjectDetector:cannotWriteVecFile'));
end

%==========================================================================
% Write header information to the outputVecFile
function writeHeader(vecFile, totalNumInstances, objectTrainingSize)

fwrite(vecFile.id, totalNumInstances, 'int');
fwrite(vecFile.id, prod(objectTrainingSize), 'int');

% mysterious min/max values from OpenCV
tmp = int16(0);
fwrite(vecFile.id, tmp, 'short');
fwrite(vecFile.id, tmp, 'short');

%==========================================================================
% Get bounding boxes associated with the current image and check their
% validity.
function currentBoundingBoxes = getBoundingBoxes(instances, imgNum, vecFile)
currentImageInstance = instances(imgNum);
currentBoundingBoxes = round(currentImageInstance.objectBoundingBoxes);
% Check that currentBoundingBoxes is an M-by-4 array
if (~ismatrix(currentBoundingBoxes)) || (size(currentBoundingBoxes, 2)~=4) ...
        || (size(currentBoundingBoxes, 1)==0)
    errMsg = message('vision:trainCascadeObjectDetector:invalidBoundingBoxes',...
        imgNum, currentImageInstance.imageFilename);
    cleanUpAndErrorOut(errMsg, vecFile);
end

%==========================================================================
% Read the image and validate it
function img = readImage(instances, imgNum, vecFile)
currentImageInstance = instances(imgNum);
% Read the image
imgName = currentImageInstance.imageFilename;
if ~exist(imgName, 'file');
    errMsg = message('vision:trainCascadeObjectDetector:cannotFindFile',...
        imgNum, imgName);
    cleanUpAndErrorOut(errMsg, vecFile);
end

img = vision.internal.cascadeTrainer.readImage(imgName);

%==========================================================================
% Crop the ROI specified by the bounding box and validate it
function imgPatch = cropROI(img, boxes, boundingBoxNum, imgNum, vecFile)

x      = boxes(boundingBoxNum, 1);
y      = boxes(boundingBoxNum, 2);
width  = boxes(boundingBoxNum, 3);
height = boxes(boundingBoxNum, 4);

% Check bounding box bounds - within image limits?
if any(boxes(boundingBoxNum, :) < 1) || y + height - 1 > size(img, 1) || ...
        x + width - 1 > size(img, 2)
    errMsg = message('vision:trainCascadeObjectDetector:cannotReadBoundingBox',...
        boundingBoxNum, imgNum);
    cleanUpAndErrorOut(errMsg, vecFile);
end

% Crop the ROI specified by the bounding box
imgPatch = img(y:y+height-1, x:x+width-1);

%==========================================================================
% Write image intensity data in row-major format as short data type to the
% outputVecFile
function writeImageInfoToVecFile(img, outputVecFile)
% 0 separator
chartmp = uint8(0);
fwrite(outputVecFile, chartmp, 'uchar');
% image data
fwrite(outputVecFile, img', 'short');

%==========================================================================
% Error in the function. Close the vec file, delete it, and throw error
% message
function cleanUpAndErrorOut(errorMessage, vecFile)
fclose(vecFile.id);
delete(vecFile.name);
error(errorMessage);