function [locations, metricValues] = applyMinQuality(points, params)
% Apply the MinQuality constraint to detect points.

%#codegen 

% Exclude corners that do not meet the threshold criteria.
if ~isempty(points.Metric)
    % in codegen, max doesn't support empty input
    threshold = params.MinQuality * max(points.Metric);

    validIndex = points.Metric >= threshold;
    locations = points.Location(validIndex, :);
    metricValues = points.Metric(validIndex);
else
    locations    = zeros(0, 2, 'like', points.Location);
    metricValues = zeros(0, 1, 'like', points.Metric);
end