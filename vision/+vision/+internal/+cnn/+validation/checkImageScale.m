function checkImageScale(s, inputSize, fname)
% empty scale means do no scaling.
if ~isempty(s)
    validateattributes(s, {'numeric'},...
        {'scalar', 'real', 'finite', 'nonsparse', 'positive'},...
        fname, 'ImageScale');
    
    % image scale should be greater than network image input size.
    if any(s(1) < inputSize(1:2))
        error(message('vision:rcnn:imageScaleLTNetInput', max(inputSize(1:2))));            
    end
end