function checkTrainingOptions(options, name)
validateattributes(options, {'nnet.cnn.TrainingOptionsSGDM'}, {}, name);

if options.MiniBatchSize < 4
    error(message('vision:rcnn:miniBatchSizeTooSmall'));
end

if ~isempty(options.ValidationData)
    error(message('vision:rcnn:validationDataNotSupported',name));
end