function [indexPairs, matchMetric] = cvalgMatchFeatures(features1in, ...
    features2in, metric, ...
    matchPercentage, method, ...
    maxRatioThreshold, isPrenormalized, ...
    uniqueMatches, isLegacyMethod)

% Main algorithm used by the matchFeatures function. See matchFeatures
% for more details.

% Copyright 2011 The MathWorks, Inc.
%#codegen

% Determine output class
if (isa(features1in, 'double'))
    outputClass = 'double';
else
    outputClass = 'single';
end

if isempty(features1in) || isempty(features2in)
    indexPairs  = zeros(2, 0, 'uint32');
    matchMetric = zeros(1, 0, outputClass);
    return;
end

% cast feature data to expected output class
[features1, features2] = castFeatures(features1in, features2in, metric,...
    method, outputClass);

% normalize features using L2-norm
if ~isPrenormalized && ~strcmpi(metric, 'hamming')
    [features1, features2] = normalizeFeatures(features1, features2, method, metric);
end

% Convert match threshold percent to a numeric threshold
matchThreshold = percentToLevel(matchPercentage, size(features1, 1), ...
    metric, outputClass);

% Find matches based on selected method
if isLegacyMethod
    
    [indexPairs, matchMetric] = findMatchesLegacy(features1, features2, ...
        metric, method, maxRatioThreshold, matchThreshold, outputClass);
    
elseif strcmpi(method, 'approximate')
    
    [indexPairs, matchMetric] = findMatchesApproximate(features1,features2,...
        metric, maxRatioThreshold, matchThreshold, uniqueMatches, outputClass);
    
else % exhaustive
    
    [indexPairs, matchMetric] = findMatchesExhaustive(features1,features2, ...
        metric, maxRatioThreshold, matchThreshold, uniqueMatches, outputClass);
    
end

%==========================================================================
% Use Approximate nearest neighbor search to find matches. 
%==========================================================================
function [indexPairs, matchMetric] = findMatchesApproximate(features1,features2,...
    metric, maxRatioThreshold, matchThreshold, uniqueMatches, outputClass)

N2 = cast(size(features2, 2), 'uint32');

[indexPairs, matchMetric] = findApproximateNearestNeighbors(features1,...
    features2, metric, outputClass);

[indexPairs, matchMetric] = removeWeakMatches(indexPairs, ...
    matchMetric, matchThreshold, metric);

[indexPairs, matchMetric] = removeAmbiguousMatches(indexPairs, ...
    matchMetric, maxRatioThreshold, N2, metric);

if uniqueMatches    
    % perform backward match to remove non-unique matches.
    
    % avoid search for the same feature more than once.
    idx = unique(indexPairs(2,:));
    
    reverse_index_pairs = findApproximateNearestNeighbors(...
        features2(:,idx), features1, metric, outputClass);
    
    f2ToF1Matches = zeros(1,N2,'uint32');
    f2ToF1Matches(idx) = reverse_index_pairs(2,:);       
    
    symmetric_pairs = f2ToF1Matches(indexPairs(2,:)) == indexPairs(1,:);
    
else % branch required for codegen
    symmetric_pairs = true(1,size(indexPairs,2));
end

indexPairs  = indexPairs(:,symmetric_pairs);
matchMetric = matchMetric(1,symmetric_pairs);

%==========================================================================
% Find approximate nearest neighbors. Return indices to the matching
% features and the distance metrics for the 2 nearest neighbors (for the
% ratio test).
%==========================================================================
function [indexPairs, metrics] = findApproximateNearestNeighbors(...
    features1, features2, metric, outputClass)

if isSimMode
    [indexPairs, metrics] = ocvFlannBasedMatching(...
        features1, features2, metric);
    
else
    coder.internal.errorIf(~coder.internal.isTargetMATLABHost,...
        'vision:matchFeatures:codegenApproxHostOnly');

    features1 = features1';
    features2 = features2';
    
    [indexPairs, metrics] = ...
        vision.internal.buildable.matchFeaturesApproxNN.findApproximateNearestNeighbors(...
        features1, features2, metric);
end

if coder.isColumnMajor
    % type of metric output should match feature input type
    metrics = cast(metrics, outputClass);

    % convert to 1-based indexing & cast to uint32
    indexPairs  = bsxfun(@plus, uint32(indexPairs(1,:)), uint32(1));

    indexPairs  = vertcat(uint32(1:size(indexPairs,2)), indexPairs(1,:));
else
    % type of metric output should match feature input type
    metrics = cast(metrics', outputClass);

    % convert to 1-based indexing & cast to uint32
    idxPairs = indexPairs';
    indexPairs  = bsxfun(@plus, uint32(idxPairs(1,:)), uint32(1));

    indexPairs  = vertcat(uint32(1:size(indexPairs,2)), indexPairs(1,:));
end

%==========================================================================
% Find matches using an exhaustive search. 
%==========================================================================
function [indexPairs, matchMetric] = findMatchesExhaustive(features1, features2,...
    metric, maxRatioThreshold, matchThreshold, uniqueMatches, outputClass)
% SCORES is an N1-by-N2 correspondence metric matrix where the rows
% correspond to the feature vectors in FEATURES1, and the columns
% correspond to the feature vectors in FEATURES2.

N1 = uint32(size(features1,2));
N2 = uint32(size(features2,2));

scores = exhaustiveDistanceMetrics(features1, features2, N1, N2, outputClass, metric);

[indexPairs, matchMetric] = findNearestNeighbors(scores, metric);

[indexPairs, matchMetric] = removeWeakMatches(indexPairs, ...
    matchMetric, matchThreshold, metric);

[indexPairs, matchMetric] = removeAmbiguousMatches(indexPairs, ...
    matchMetric, maxRatioThreshold, N2, metric);

if uniqueMatches
    uniqueIndices = findUniqueIndices(scores, metric, indexPairs);
else
    % branch required for codegen
    uniqueIndices = true(1,size(indexPairs,2));
end
indexPairs  = indexPairs(:, uniqueIndices);
matchMetric = matchMetric(1, uniqueIndices);

%==========================================================================
% Find nearest neighbors using an exhaustive search. Return indices to the
% matching features and the distance metrics for the 2 nearest neighbors
% (for the ratio test).
%==========================================================================
function  [indexPairs, topTwoMetrics] = findNearestNeighbors(scores, metric)

if strcmp(metric, 'normxcorr')
    [topTwoMetrics, topTwoIndices] = vision.internal.partialSort(scores, 2, 'descend');    
else
    [topTwoMetrics, topTwoIndices] = vision.internal.partialSort(scores, 2, 'ascend');
end

indexPairs = vertcat(uint32(1:size(scores,1)), topTwoIndices(1,:));

%==========================================================================
% Compute distance metrics
%==========================================================================
function scores = exhaustiveDistanceMetrics(features1, features2, ...
    N1, N2, outputClass, metric)
% Generate correspondence metric matrix
switch metric
    case 'sad'
        % Generate correspondence matrix using Sum of Absolute Differences
        scores = metricSAD(features1, features2, N1, N2, outputClass);
    case 'normxcorr'
        % Generate correspondence matrix using Normalized Cross-correlation
        scores = metricNormXCorr(features1, features2);
    case 'ssd'
        % Generate correspondence matrix using Sum of Squared Differences
        scores = metricSSD(features1, features2, N1, N2, outputClass);
    otherwise % 'hamming'
        % Generate correspondence matrix using Sum of Squared Differences
        scores = metricHamming(features1, features2, N1, N2, outputClass);
end

%==========================================================================
% Find matches using legacy method modes.
%==========================================================================
function [indexPairs, matchMetric] = findMatchesLegacy(features1, features2, ...
    metric, method, maxRatioThreshold, matchThreshold, outputClass)

N1 = uint32(size(features1,2));
N2 = uint32(size(features2,2));

switch method
    case 'nearestneighborsymmetric'
        scores = exhaustiveDistanceMetrics(features1, features2, N1, N2, ...
            outputClass, metric);
        
        % keep this for backward compatibility
        [indexPairs, matchMetric] = findMatchesNN(scores, metric, ...
            matchThreshold);
        
    case 'threshold'
        % keep this for backward compatibility
        
        scores = exhaustiveDistanceMetrics(features1, features2, N1, N2, ...
            outputClass, metric);
        
        [indexPairs, matchMetric] = findMatchesThreshold(scores, ...
            metric, matchThreshold);
        
    case 'nearestneighbor_old'
        % keep this for backward compatibility
        
        scores = exhaustiveDistanceMetrics(features1, features2, N1, N2,...
            outputClass, metric);
        
        [indexPairs, matchMetric] = findMatchesNN_old(scores, N1, N2, ...
            metric);
        
        [indexPairs, matchMetric] = removeWeakMatches(indexPairs, ...
            matchMetric, matchThreshold, metric);
        
    case 'nearestneighborratio'
        if N2 > 1
            [indexPairs, matchMetric] = findMatchesExhaustive(...
                features1, features2, metric, maxRatioThreshold, ...
                matchThreshold, false, outputClass);
        else
            % If FEATURES2 contains only 1 feature, we cannot use ratio.
            % Use NearestNeighborSymmetric instead, resulting in a single
            % match
            scores = exhaustiveDistanceMetrics(features1, features2, ...
                N1, N2, outputClass, metric);
            [indexPairs, matchMetric] = findMatchesNN(scores, ...
                metric, matchThreshold);
        end
        
        
end

%==========================================================================
% Remove ambiguous matches using the nearest neighbor ratio test.
%==========================================================================
function [indexPairs, matchMetric] = removeAmbiguousMatches(indexPairs, ...
    matchMetric, maxRatio, N2, metric)

if N2 > 1
    % apply ratio test only if there are more than 1 feature vectors
    unambiguousIndices = findUnambiguousMatches(matchMetric, maxRatio, metric);
else
    unambiguousIndices = true(1,size(matchMetric,2));
end

indexPairs  = indexPairs(:, unambiguousIndices);
matchMetric = matchMetric(1,unambiguousIndices);

%==========================================================================
% Enforce uniqueness by applying a bi-directional match constraint
%==========================================================================
function uniqueIndices = findUniqueIndices(scores, metric, ...
    indexPairs)

if strcmpi(metric,'normxcorr')
    [~, idx] = max(scores(:,indexPairs(2,:)));
else
    [~, idx] = min(scores(:,indexPairs(2,:)));
end

uniqueIndices = idx == indexPairs(1,:);

%==========================================================================
% Find matches using Nearest-Neighbor strategy
%==========================================================================
function [indexPairs, matchMetric] = findMatchesNN(scores, ...
    metric, matchThreshold)
% Find the maximum(minimum) entry in scores.
% Make it a match.
% Eliminate the corresponding row and the column.
% Repeat.

nRows = size(scores, 1);
nCols = size(scores, 2);
nMatches = min(nRows, nCols);
indexPairs = zeros([2, nMatches], 'uint32');
matchMetric = zeros(1, nMatches, 'like', scores);

useMax = strcmp(metric, 'normxcorr');

for i = 1:nMatches
    if useMax
        [matchMetric(i), ind] = max(scores(:));
        [r, c] = ind2sub(size(scores), ind);
    else
        [matchMetric(i), ind] = min(scores(:));
        [r, c] = ind2sub(size(scores), ind);
    end
    
    indexPairs(:, i) = [r, c];
    if useMax
        scores(r, :) = -inf('like',scores);
        scores(:, c) = -inf('like',scores);
    else
        scores(r, :) = inf('like',scores);
        scores(:, c) = inf('like',scores);
    end
end

[indexPairs, matchMetric] = removeWeakMatches(indexPairs, ...
    matchMetric, matchThreshold, metric);

%==========================================================================
% Normalize features to be unit vectors
%==========================================================================
function [features1, features2] = normalizeFeatures(features1, features2, ...
    method, metric)

% move this to parsing where we map old method values.
% normalize the features
if strcmp(method, 'nearestneighbor_old') && ...
        strcmp(metric, 'normxcorr')
    % for backward compatibility, subtract the mean from features
    f1Mean = mean(features1);
    features1 = bsxfun(@minus, features1, f1Mean);
    f2Mean = mean(features2);
    features2 = bsxfun(@minus, features2, f2Mean);
end

% Convert feature vectors to unit vectors
features1 = normalizeX(features1);
features2 = normalizeX(features2);

%==========================================================================
% Convert match threshold percent to an numeric threshold
%==========================================================================
function matchThreshold = percentToLevel(matchPercentage, ...
    vector_length, metric, outputClass)

matchPercentage = cast(matchPercentage, outputClass);
vector_length = cast(vector_length, outputClass);

if (strcmp(metric, 'normxcorr'))
    matchThreshold = cast(0.01, outputClass)*(cast(100, outputClass) ...
        - matchPercentage);
else
    if (strcmp(metric, 'sad'))
        max_val = cast(2, outputClass)*sqrt(vector_length);
    elseif (strcmp(metric, 'ssd'))
        max_val = cast(4, outputClass);
    else % 'hamming'
        % the below value assumes that binary features are stored
        % in 8-bit buckets, which is correct for binaryFeatures class
        max_val = cast(8*vector_length, outputClass);
    end
    
    matchThreshold = (matchPercentage*cast(0.01, outputClass))*max_val;
    
    if strcmp(metric, 'hamming')
        % Round up since we are dealing with whole bits
        matchThreshold = round(matchThreshold);
    end
end

%==========================================================================
% Cast features to expected output class.
%==========================================================================
function [features1, features2] = castFeatures(features1in, features2in,...
    metric, method, outputClass)

if ~strcmp(metric, 'hamming')
    if strcmpi(method, 'approximate')
        % approximate search requires single
        features1 = cast(features1in, 'single');
        features2 = cast(features2in, 'single');
    else
        features1 = cast(features1in, outputClass);
        features2 = cast(features2in, outputClass);
    end
else
    % do not cast binary feature data
    features1 = features1in;
    features2 = features2in;
end

%==========================================================================
% Find unambiguous matches using David Lowe's disambiguation strategy
%==========================================================================
function unambiguousIndices = findUnambiguousMatches(topTwoScores, maxRatioThreshold, metric)

if strcmpi(metric, 'normxcorr')
    % If the metric is 'normxcorr', then the scores are cosines
    % of the angles between the feature vectors.
    % The ratio of the angles is an approximation of the ratio of
    % euclidean distances.  See David Lowe's demo code.
    
    topTwoScores(topTwoScores > 1) = 1; % prevent complex angles
    topTwoScores = acos(topTwoScores);
end
    
% handle division by effective zero
zeroInds = topTwoScores(2, :) < cast(1e-6, 'like', topTwoScores);
topTwoScores(:, zeroInds) = 1;
ratios = topTwoScores(1, :) ./ topTwoScores(2, :);

unambiguousIndices = ratios <= maxRatioThreshold;

%==========================================================================
% Find matches using a bidirectional greedy strategy
%==========================================================================
function [indexPairs, matchMetric] = findMatchesThreshold(scores, ...
    metric, matchThreshold)

if strcmp(metric, 'normxcorr')
    inds = find(scores >= matchThreshold);
else
    inds = find(scores <= matchThreshold);
end

matchMetric = scores(inds)';
[rowInds, colInds] = ind2sub(size(scores), inds);
indexPairs = cast([rowInds, colInds]', 'uint32');

%==========================================================================
% Find matches using the old nearest neighbor strategy for compatibility
%==========================================================================
function [indexPairs, matchMetric] = findMatchesNN_old(scores, N1, N2,...
    metric)
% SCORES is an N1-by-N2 correspondence metric matrix where the rows
% correspond to the feature vectors in FEATURES1, and the columns
% correspond to the feature vectors in FEATURES2.

% For each feature vector in FEATURES1 find the best match in FEATURES2.
% This is simply the entry along each row with the minimum or maximum
% metric value, depending on the metric.
row_index_pairs = [(1:N1); zeros(1, N1)];
if (strcmp(metric, 'normxcorr'))
    [row_scores, row_index_pairs(2, :)] = max(scores, [], 2);
else
    [row_scores, row_index_pairs(2, :)] = min(scores, [], 2);
end

% For each feature vector in FEATURES2 find the best match in FEATURES1.
% This is simply the entry down each col with the minimum or maximum metric
% value, depending on the metric.
col_index_pairs = [zeros(1, N2); (1:N2)];
if (strcmp(metric, 'normxcorr'))
    [col_scores, col_index_pairs(1, :)] = max(scores, [], 1);
else
    [col_scores, col_index_pairs(1, :)] = min(scores, [], 1);
end

% Concatenate both row and column lists
M = [row_scores', col_scores];
indexPairs = [row_index_pairs, col_index_pairs];

% Remove duplicate entries in the matches list
[trimmed_index_pairs, I, ~] = unique(indexPairs', 'rows');
matchMetric = M(I);
indexPairs = trimmed_index_pairs';

%==========================================================================
% Generate correspondence metric matrix using Sum of Absolute Differences
%==========================================================================
function scores = metricSAD(features1, features2, N1, N2, outputClass)

% Need to obtain feature vector length to perform explicit row indexing
% needed for code generation of variable sized inputs

if isSimMode()
    % call optimized builtin function
    scores = zeros(N1, N2, outputClass);
    scores(:,:) = visionSADMetric(features1,features2);
else
    if coder.internal.isTargetMATLABHost
        features1 = features1';
        features2 = features2';        
        scores = vision.internal.buildable.ComputeMetricBuildable.ComputeMetric_core(features1,features2, 'sad', N1, N2, outputClass);
    else
        % for portable C code generation
        vector_length = size(features1, 1);
        scores = zeros(N1, N2, outputClass);
        
        for c = 1:N2
            for r = 1:N1
                scores(r, c) = sum(abs(features1(1:vector_length, r) - ...
                    features2(1:vector_length, c)));
            end
        end
    end
end

%==========================================================================
% Generate correspondence metric matrix using Sum of Squared Differences
%==========================================================================
function scores = metricSSD(features1, features2, N1, N2, outputClass)

% Need to obtain feature vector length to perform explicit row indexing
% needed for code generation of variable sized inputs

if isSimMode()
    % call optimized builtin function
    scores = zeros(N1, N2, outputClass);
    scores(:,:) = visionSSDMetric(features1,features2);
else
    if coder.internal.isTargetMATLABHost
        features1 = features1';
        features2 = features2';
        scores = vision.internal.buildable.ComputeMetricBuildable.ComputeMetric_core(features1,features2, 'ssd', N1, N2, outputClass);
    else
        % for portable C code generation
        vector_length = size(features1, 1);
        scores = zeros(N1, N2, outputClass);
        
        for c = 1:N2
            for r = 1:N1
                scores(r, c) = sum((features1(1:vector_length, r) - ...
                    features2(1:vector_length, c)).^2);
            end
        end
    end
end

%==========================================================================
% Generate correspondence metric matrix based on Hamming distance
%==========================================================================
function scores = metricHamming(features1, features2, N1, N2, outputClass)

persistent lookupTable; % lookup table for counting bits

% Need to obtain feature vector length to perform explicit row indexing
% needed for code generation of variable sized inputs
if isSimMode()
    % call optimized builtin function
    scores = zeros(N1, N2, outputClass);
    scores(:,:) = visionHammingMetric(features1,features2);
else
    if coder.internal.isTargetMATLABHost
        features1 = features1';
        features2 = features2';        
        scores = vision.internal.buildable.ComputeMetricBuildable.ComputeMetric_core(features1,features2, 'hamming', N1, N2, outputClass);
    else
        % for portable C code generation
        vector_length = size(features1, 1);
        scores = zeros(N1, N2, outputClass);
        
        if isempty(lookupTable)
            lookupTable = zeros(256, 1, outputClass);
            for i = 0:255
                lookupTable(i+1) = sum(dec2bin(i)-'0');
            end
        end
        
        for c = 1:N2
            for r = 1:N1
                temp = bitxor(features1(1:vector_length, r),...
                    features2(1:vector_length, c));
                idx = double(temp) + 1; % cast needed to avoid integer math
                scores(r,c) = sum(lookupTable(idx));
            end
        end
    end
end

%==========================================================================
% Generate correspondence metric matrix using Normalized Cross-Correlation
%==========================================================================
function scores = metricNormXCorr(features1, features2)
scores = features1' * features2;

%==========================================================================
% Remove weak matches
%==========================================================================
function [indices, matchMetric] = removeWeakMatches(indices, ...
    matchMetric, matchThreshold, metric)

if (strcmp(metric, 'normxcorr'))
    inds = matchMetric(1,:) >= matchThreshold;
else
    inds = matchMetric(1,:) <= matchThreshold;
end

indices = indices(:, inds);
matchMetric = matchMetric(:, inds);

%==========================================================================
% Normalize the columns in X to have unit norm.
%==========================================================================
function X = normalizeX(X)
Xnorm = sqrt(sum(X.^2, 1));
X = bsxfun(@rdivide, X, Xnorm);

% Set effective zero length vectors to zero
X(:, (Xnorm <= eps(single(1))) ) = 0;

%==========================================================================
function flag = isSimMode()

flag = isempty(coder.target);