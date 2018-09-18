function [I_u8c, expandedROI] = cropImage(I_u8, params)

%#codegen

imageSize = size(I_u8);
if params.usingROI
    % If an ROI has been defined, we expand it by 2 pixels on the top,
    % bottom, left, and right borders, so only valid pixels are used to
    % compute the corners.
    expandedROI = vision.internal.detector.expandROI(imageSize, ...
        params.ROI, 2);
    
    % Crop the image within the expanded ROI.
    I_u8c = vision.internal.detector.cropImage(I_u8, expandedROI);
else
    expandedROI = coder.nullcopy(zeros(1,4,'like',params.ROI));
    I_u8c = I_u8;
end
