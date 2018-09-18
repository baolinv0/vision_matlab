function Iroi = cropImageIfRequested(I, roi, usingROI)
% Crops out and returns the roi from I if usingROI is true. Otherwise, the
% original image is returned. 
%
% The roi should already be validated using vision.internal.detector.checkROI.

%#codegen
if usingROI          
    Iroi = vision.internal.detector.cropImage(I, roi);
else
    % return original image. This is a no-op in codegen.    
    Iroi = I;    
end