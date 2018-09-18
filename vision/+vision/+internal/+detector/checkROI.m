function r = checkROI(roi, imageSize)
% checkROI Check the attributes and values of ROI
% r = checkROI(roi, imageSize) returns true if ROI has integer values and
% is inside the image with size specified in imageSize. Also checks whether
% the width and height is >= zero.

%#codegen
%#ok<*EMCA>


if ~isempty(roi)
        
    % roi must be 1-by-4 numeric vector
    validateattributes(roi, {'numeric'}, ...
        {'real', 'nonsparse', 'finite', 'numel',4,'vector'},...
        'checkROI', 'ROI');
    
    % rounds floats and casts to int32 to avoid saturation of smaller integer types.
    roi = vision.internal.detector.roundAndCastToInt32(roi);    
    
    % width and height must be >= 0
    coder.internal.errorIf(roi(3) < 0 || roi(4) < 0, ...
        'vision:validation:invalidROIWidthHeight');
    
    % roi must be fully contained within I
    coder.internal.errorIf(roi(1) < 1 || roi(2) < 1 ...
        || roi(1)+roi(3) > imageSize(2)+1 ...
        || roi(2)+roi(4) > imageSize(1)+1, ...
        'vision:validation:invalidROIValue');
end
r = true;
