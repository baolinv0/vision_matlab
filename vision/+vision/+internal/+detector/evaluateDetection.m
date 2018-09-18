function s = evaluateDetection(detectionResults,groundTruth,threshold)
% Return per image detection evaluation result.
% detectionResults is a table of two/three columns: boxes, scores, labels
% groundTruth is a table of boxes, one column for each class
% threshold is the intersection-over-union (IOU) threshold. 

% Copyright 2016-2017 The MathWorks, Inc.

numImages = height(groundTruth);
numClasses = width(groundTruth);

allResults = iPreallocatePerImageResultsStruct(numImages);
ismulcls = (width(detectionResults) > 2);
if ismulcls
    classNames = categorical(groundTruth.Properties.VariableNames);
end

for i = 1:numImages
        
    [expectedBoxes, expectedLabelIDs] = iGetGroundTruthBoxes(groundTruth, i); 
    if isempty(expectedBoxes)
        expectedBoxes = zeros(0, 4, 'like', expectedBoxes);
    end
 
    bboxes = detectionResults{i, 1}{1};
    scores = detectionResults{i, 2}{1};
    if ismulcls
        detLabelIDs = detectionResults{i, 3}{1};
        if ~isempty(detLabelIDs)
            % convert to numeric values
            [~, detLabelIDs] = ismember(detLabelIDs,classNames);
        else
            detLabelIDs = [];
        end
    else
        detLabelIDs = ones(size(scores));
    end
    
    results = iPreallocatePerClassResultsStruct(numClasses);
    
    for c = 1:numClasses
    
        expectedBoxesForClass = expectedBoxes(expectedLabelIDs == c, :);
               
        if isempty(bboxes)
            scoresPerClass = scores;
            bboxesPerClass = zeros(0, 4, 'like', bboxes);
        else
            scoresPerClass = scores(detLabelIDs == c);
            bboxesPerClass = bboxes(detLabelIDs == c, :);
        end
        
        if ~isempty(expectedBoxesForClass)
            [labels, falseNegative, assignments] = ...
                vision.internal.detector.assignDetectionsToGroundTruth(bboxesPerClass, ...
                scoresPerClass, expectedBoxesForClass, threshold);
        else
            labels = zeros(size(bboxesPerClass, 1),1);
            falseNegative = 0;
            assignments = [];
        end
        % per class per image results       
        results(c).labels = labels;
        results(c).scores = scoresPerClass;
        results(c).Detections = bboxesPerClass;
        results(c).FalseNegative = falseNegative;
        results(c).GroundTruthAssignments = assignments;
        results(c).NumExpected = size(expectedBoxesForClass,1);                  
        
    end
     
    allResults(i).Results = results;
end
   
% vertcat results over all images for each class. Results holds a
% 1xnumClasses struct array. After concat s is numImages-by-numClasses
% struct array.
s = vertcat(allResults(:).Results);

%==========================================================================
function s = iPreallocatePerImageResultsStruct(numImages)
s(numImages) = struct('Results', []);

%==========================================================================
function s = iPreallocatePerClassResultsStruct(numClasses)
s(numClasses) = struct(...
    'labels', [], ...
    'scores', [], ...
    'Detections', [], ...
    'FalseNegative', [], ...
    'GroundTruthAssignments', [], ...
    'NumExpected', []);

%==========================================================================
function [bboxes, labels] = iGetGroundTruthBoxes(tbl, i)
b = tbl(i,:);

n = cellfun(@(x)size(x,1), b{1,:});

label = cell(width(b),1);
for i = 1:width(b)
    label{i} = repelem(i,n(i),1);    
end
labels = vertcat(label{:});
bboxes = vertcat(b{1,:}{:});

