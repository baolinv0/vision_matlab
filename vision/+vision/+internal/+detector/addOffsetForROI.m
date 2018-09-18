function locations = addOffsetForROI(locations, roi, useROI) 
% Add offset to locations based on the ROI. locations is M-by-2 ([x y]).
% roi is 4 element vector. 

%#codegen
if useROI && ~isempty(roi) 
    roi = vision.internal.detector.roundAndCastToInt32(roi);
    if roi(3) && roi(4) % non-zero width height ROI
        
        % offset bbox relative to image coordinate system
        offset = cast([roi(1) roi(2)] - 1, 'like', locations);
        
        locations(:,1) = locations(:,1) + offset(1);
        locations(:,2) = locations(:,2) + offset(2);
    end
end
   
