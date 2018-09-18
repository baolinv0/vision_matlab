function [validLocation, validMetric] = excludePointsOutsideROI(...
    originalROI, expandedROI, locInExpandedROI, metric)
% excludePointsOutsideROI Exclude points outside ROI
%  [validLocation, validMetric] = excludePointsOutsideROI(originalROI,
%  expandedROI, locInExpandedROI, metric) returns the location and metric
%  for the points that are within the original ROI, originalROI. Location
%  of the input points, locInExpandedROI, is specified with respect to the
%  expanded ROI, expandedROI. Metric of the input points are specified in
%  the metric input.

%#codegen
if isempty(originalROI)
    validLocation = zeros(0,2,'like', locInExpandedROI);
    validMetric   = zeros(0,1,'like', metric);
else
    
    x1 = originalROI(1);
    y1 = originalROI(2);
    x2 = x1 + originalROI(3) - 1;
    y2 = y1 + originalROI(4) - 1;
    
    locInImage = bsxfun(@plus, single(locInExpandedROI), single(expandedROI(1:2))-1);
    
    validIndex = locInImage(:,1)>=x1 & locInImage(:,2)>=y1 ...
        & locInImage(:,1)<=x2 & locInImage(:,2)<=y2;
    
    validLocation = locInImage(validIndex, :);
    validMetric = metric(validIndex, :);
end