function out = roundAndCastToInt32(ROI)
% Round and cast ROI so that it is integer valued.

%#codegen
if isfloat(ROI)    
    out = int32(round(ROI));
else
    out = int32(ROI);
end
