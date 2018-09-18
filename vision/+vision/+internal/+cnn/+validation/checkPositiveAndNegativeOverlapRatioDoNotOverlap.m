function checkPositiveAndNegativeOverlapRatioDoNotOverlap(params)
% positive and negative ranges should not overlap
if params.PositiveOverlapRange(1) < params.NegativeOverlapRange(2)
    error(message('vision:rcnn:rangesOverlap'));
end
