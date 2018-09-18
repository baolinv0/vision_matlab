function checkClassNamesMatchGroundTruth(classnames, trainingData, bgLabel)
% Verify that detector classnames still match those used in ground truth
% when resuming training.
expectedNames = [trainingData.Properties.VariableNames(2:end) bgLabel]';
if ~isequal(classnames, expectedNames)
    error(message('vision:rcnn:resumeClassNameMismatch'));        
end

