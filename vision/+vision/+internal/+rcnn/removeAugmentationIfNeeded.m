%--------------------------------------------------------------------------
% Remove the augmentations, if present, and issues a warning.
%--------------------------------------------------------------------------
function layers = removeAugmentationIfNeeded(layers, augmentations)

augmentations = cellstr(augmentations);
for i = 1:numel(augmentations)
    layers = iRemoveAugmentationAndWarn(layers, augmentations{i});
end

%--------------------------------------------------------------------------
function layers = iRemoveAugmentationAndWarn(layers, augmentation)

if ismember(augmentation, layers(1).DataAugmentation)
    warning(message('vision:rcnn:removingAugmentation', augmentation));
    
    augmentations = cellstr(layers(1).DataAugmentation);
    idx = strcmpi(augmentation, augmentations);
    
    % remove randcrop data augmentation
    augmentations(idx) = [];
    
    if isempty(augmentations)
        augmentations = 'none';
    end        
    
    layers(1) = imageInputLayer(layers(1).InputSize, ...
        'Name', layers(1).Name,...
        'DataAugmentation', augmentations, ...
        'Normalization', layers(1).Normalization);
end

