%averagePrecision Compute the average precision metric
%   ap = averagePrecision(actualIDs, expectedIDs) returns the average
%   precision metric, ap, for evaluating the accuracy of image search.  The
%   input actualIDs is a vector of indices representing the ranked search
%   results (from best to worst) for a single query. The expectedIDs is
%   a vector of indices that represent all the expected search results for
%   that same query. The order of the expectedIDs does not matter: all
%   expectedIDs are given equal importance. The average precision is
%   computed over all the expected results.
%
%   ap = averagePrecision(..., N) returns the average precision at N. This
%   is the average precision up to the top N results. 
%
%   The range of the average precision metric is 0 <= ap <= 1.
function ap = averagePrecision(actual,expected,N)

if nargin > 2   
    deltaRecall = min(N, numel(expected));     
    
    % evaluate top N
    actual = actual(1:min(N, numel(actual))); 
else
    deltaRecall = numel(expected);
end

isRelevant = ismember(actual, expected);

% compute precision over results
precision = cumsum(isRelevant) .* isRelevant;

ap = sum(precision(:) ./ (1:numel(isRelevant))')/ deltaRecall;

