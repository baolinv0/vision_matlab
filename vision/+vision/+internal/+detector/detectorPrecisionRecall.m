function [ap, precision, recall] = detectorPrecisionRecall(labels, scores, numExpected)
% Compute average precision metric for detector results. Follows
% PASCAL VOC 2011 average precision metric. labels greater than
% zero are for a positive samples and smaller than zero for
% negative samples.
if (isempty(labels) || numExpected == 0)
    ap = 0;
    precision = 1;
    recall = 0;
    return;
end

[~, idx] = sort(scores, 'descend');
labels = labels(idx);

tp = labels > 0;
fp = labels <= 0;

tp = cumsum(tp);
fp = cumsum(fp);

precision = tp ./ (tp + fp);
recall = tp ./ numExpected;

% Change in recall for every true positive.
deltaRecall = 1/numExpected; 

ap = sum( precision .* (labels>0) ) * deltaRecall;

% By convention, start precision at 1 and recall at 0
precision = [1; precision];
recall    = [0; recall];
