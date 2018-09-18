function checkGroundTruth(gt, name)
validateattributes(gt, {'table'},{'nonempty'}, name, 'trainingData',1);

if width(gt) < 2 
    error(message('vision:ObjectDetector:trainingDataTableWidthLessThanTwo'));
end

for i = 2:width(gt)
    if classHasNoBoxes(gt(:,i))        
        cls = gt.Properties.VariableNames{i};
        error(message('vision:ObjectDetector:classHasNoBoxes', cls));
    end
end

%--------------------------------------------------------------------------
function TF = classHasNoBoxes(tblCol)
TF = true;
for i = 1:height(tblCol)
    if ~isempty(tblCol{i,1}{1})
        TF = false;
        break
    end
end