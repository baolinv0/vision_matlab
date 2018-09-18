%==========================================================================
%  Computer Loop Number for RANSAC/MSAC Algorithm
%==========================================================================
function N = computeLoopNumber(sampleSize, confidence, pointNum, inlierNum)
%#codegen
pointNum = cast(pointNum, 'like', inlierNum);
inlierProbability = (inlierNum/pointNum)^sampleSize;

if inlierProbability < eps(class(inlierNum))
    N = intmax('int32');
else
    conf = cast(0.01, 'like', inlierNum) * confidence;
    one  = ones(1,    'like', inlierNum);
    num  = log10(one - conf);
    den  = log10(one - inlierProbability);
    N    = int32(ceil(num/den));
end 