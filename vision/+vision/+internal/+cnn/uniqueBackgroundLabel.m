function label = uniqueBackgroundLabel(groundTruth)
% Use a background label that is not included in the ground truth.
label = 'Background';
while ismember(label, groundTruth.Properties.VariableNames)
    label = sprintf('%s_%d', label, randi(9));
end
