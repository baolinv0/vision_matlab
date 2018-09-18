function [matches, unassignedTracks, unassignedDetections] = ...
    assignDetectionsToTracks(costMatrix, costUnassignedTracks, ...
    costUnassignedDetections)

% assignDetectionsToTracks assign detections to tracks for multi-object tracking
%
% assignDetectionsToTracks assigns detections to tracks in the context of 
% multiple object tracking using the James Munkres' variant of the Hungarian
% assignment algorithm. assignDetectionsToTracks also determines which tracks
% are missing, and which detections should begin new tracks.
%
% [assignments, unassignedTracks, unassignedDetections] = ... 
%    assignDetectionsToTracks(costMatrix, costOfNonAssignment)
% returns the indices of assigned and unassigned tracks and detections
% based on the cost matrix and unassignedCost.
%
%     Inputs:
%     -------
%     costMatrix is an M-by-N matrix, where M is the number of tracks, and
%     N is the number of detections. costMatrix(i, j) is the cost of 
%     assigning j-th detection to i-th track. The lower the cost, the more 
%     likely the assignment is to be made. 
%
%     costOfNonAssignment is a scalar, which represents the cost of a track 
%     or a detection remaining unassigned.  Higher costOfNonAssignment 
%     corresponds to the higher likelihood that every existing track will 
%     be assigned a detection. 
%
%     Outputs:
%     -------
%     assignments is an L-by-2 matrix of index pairs of tracks and 
%     corresponding detections, where L is the number of pairs. The first 
%     column contains the track indices and the second column contains 
%     the corresponding detection indices.
% 
%     unassignedTracks is a P-element where P is the number of unassigned 
%     tracks. Each element is an index of a track to which no detections 
%     were assigned.
%
%     unassignedDetections is a Q-element vector, where Q is the number of 
%     unassigned detections. Each element is an index of a detection that 
%     was not assigned to any tracks. These detections can begin new tracks. 
%
% [...] = assignDetectionsToTracks(costMatrix, unassignedTrackCost,...
%   unassignedDetectionCost) specifies the cost of unassigned tracks and
% detections separately. 
%
%     Inputs:
%     -------
%     unassignedTrackCost is a scalar or an M-element vector, where M is 
%     the number of tracks. For the M-element vector, each element
%     represents the cost of not assigning any detection to that track. A
%     scalar input represents the same cost of being unassigned for all
%     tracks. The cost may vary depending on what you know about each track
%     and the scene. For example, if an object is about to leave the field
%     of view, the cost of the corresponding track being unassigned should
%     be low. 
%
%     unassignedDetectionCost is a scalar or an N-element vector, where N
%     is the number of detections. For the N-element vector, each element
%     represents the cost of starting a new track for that detection. A
%     scalar input represents the same cost of being unassigned for all
%     tracks. The cost may vary depending on what you know about each
%     detection and the scene. For example, if a detection appears close to
%     the edge of the image, it is more likely to be a new object. 
%
% Class Support:
% --------------
% All inputs must be of the same class, which can be int8, uint8, int16, 
% uint16, int32, uint32, single, or double, and they must be real and 
% nonsparse. costMatrix may contain Inf entries to indicate that no 
% assignment between a track and a detection is possible. costOfNonAssignment, 
% unassignedTrackCost, and unassignedDetectionCost must be finite.
%
% All outputs are of class uint32.
%
% Example:
% --------
% % Predicted locations of objects in the current frame.
% % Predictions can be obtained, for example, by using 
% % vision.KalmanFilter.
%  predictions = [1,1; 2,2];
% 
% % Locations of actual objects detected in the current frame.
% % Note that there are currently 2 tracks, and 3 new detections.
% % At least one of the detections would be unmatched, 
% % meaning that it may be a brand new track.
% detections = [1.1, 1.1; 2.1, 2.1; 1.5, 3];
% 
% % pre-allocate a cost matrix
% numPredictions = size(predictions, 1);
% numDetections = size(detections, 1);
% cost = zeros(numPredictions, numDetections);
% 
% % for each prediction, compute the cost of matching each detection.
% for i = 1:numPredictions
%     % the cost is defined as the Euclidean distance between the 
%     % prediction and the detection
%     diff = detections - repmat(predictions(i, :), [numDetections, 1]);
%     cost(i, :) = sqrt(sum(diff .^ 2, 2));
% end
% 
% % assign detections to predictions
% % detection 1 should match to track 1, detection 2 to track 2, and
% % detection 3 should be unmatched.
% [assignment, unassignedTracks, unassignedDetections] = ...
%     assignDetectionsToTracks(cost, 0.2);
%
% figure;
% plot(predictions(:, 1), predictions(:, 2), '*', ...
%    detections(:, 1), detections(:, 2), 'ro');
% hold on;
% legend('predictions', 'detections');
% for i = 1:size(assignment, 1)
%   text(predictions(assignment(i, 1), 1)+0.1, ...
%       predictions(assignment(i, 1), 2)-0.1, num2str(i));
%   text(detections(assignment(i, 2), 1)+0.1, ...
%       detections(assignment(i, 2), 2)-0.1, num2str(i));
% end
% for i = 1:length(unassignedDetections)
%   text(detections(unassignedDetections(i), 1)+0.1, ...
%       detections(unassignedDetections(i), 2)+0.1, 'unassigned');
% end
% xlim([0, 4]);
% ylim([0, 4]);
%
% See also vision.KalmanFilter
 
%   Copyright 2012 MathWorks, Inc.
%   Date: 2012/07/17 04:56:39 $
% 
%   References:
%   -----------
%   Matt L. Miller, Harold S. Stone, and Ingemar J. Cox. Optimizing Murty's 
%   Ranked Assignment Method.  IEEE Transactions on Aerospace and 
%   Electronic Systems, 33(3), 1997
%
%   James Munkres, Algorithms for Assignment and Transportation Problems, 
%   Journal of the Society for Industrial and Applied Mathematics Volume 5, 
%   Number 1, March, 1957
%
%   R. A. Pilgrim. Munkres' Assignment Algorithm Modified for Rectangular 
%   Matrices http://csclab.murraystate.edu/bob.pilgrim/445/munkres.html

%#codegen
%#ok<*EMCLS>
%#ok<*EMCA>

% Parse and check inputs
checkCost(costMatrix);
checkUnassignedCost(costUnassignedTracks, 'costUnassignedTracks');

coder.internal.errorIf(nargin == 2 && ~isscalar(costUnassignedTracks), ...
    'vision:assignDetectionsToTracks:costOfNotMatchingMustBeScalar');
coder.internal.errorIf(~isa(costMatrix, class(costUnassignedTracks)), ...
    'vision:assignDetectionsToTracks:allInputsMustBeSameClass');
if nargin > 2
    checkUnassignedCost(costUnassignedDetections, ...
        'costUnassignedDetections');
    coder.internal.errorIf(~isa(costMatrix, class(costUnassignedDetections)), ...
        'vision:assignDetectionsToTracks:allInputsMustBeSameClass');
    coder.internal.errorIf(~isscalar(costUnassignedTracks) && ...
        (numel(costUnassignedTracks) ~= size(costMatrix, 1)), ...
        'vision:assignDetectionsToTracks:costUnmatchedTracksInvalidSize');
    coder.internal.errorIf(~isscalar(costUnassignedDetections) && ...
        (numel(costUnassignedDetections) ~= size(costMatrix, 2)), ...
        'vision:assignDetectionsToTracks:costUnmatchedDetectionsInvalidSize');
end
 
theClass = class(costMatrix);
costUnmatchedTracksVector = ones(1, size(costMatrix, 1), theClass) .* ...
    costUnassignedTracks;
if nargin > 2    
    costUnmatchedDetectionsVector = ones(1, size(costMatrix, 2), theClass) ...
            .* costUnassignedDetections;
else    
    costUnmatchedDetectionsVector = ones(1, size(costMatrix, 2), theClass) .*...
        costUnassignedTracks;        
end

[matches, unassignedTracks, unassignedDetections] = ...
    cvalgAssignDetectionsToTracks(costMatrix, costUnmatchedTracksVector, ...
    costUnmatchedDetectionsVector);

%-------------------------------------------------------------------------
function tf = checkCost(cost)
validateattributes(cost, {'numeric'}, ...
    {'real', 'nonsparse', 'nonnan', '2d'}, ...
    'assignDetectionsToTracks', 'cost');
tf = true;

%-------------------------------------------------------------------------
function tf = checkUnassignedCost(val, varName)
validateattributes(val, {'numeric'}, ...
    {'vector', 'finite', 'real', 'nonsparse'}, ...
    'assignDetectionsToTracks', varName); 
tf = true;

%-------------------------------------------------------------------------
function [matches, unmatchedTracks, unmatchedDetections] = ...
    cvalgAssignDetectionsToTracks(cost, costUnmatchedTracks, ...
    costUnmatchedDetections)

% add dummy rows and columns to account for the possibility of 
% unassigned tracks and observations
paddedCost = getPaddedCost(cost, costUnmatchedTracks, ...
    costUnmatchedDetections);

% solve the assignment problem
[rowInds, colInds] = find(hungarianAssignment(paddedCost));

rows = size(cost, 1);
cols = size(cost, 2);
unmatchedTracks = uint32(rowInds(rowInds <= rows & colInds > cols));
unmatchedDetections = uint32(colInds(colInds <= cols & rowInds > rows));

matches = uint32([rowInds, colInds]);
matches = matches(rowInds <= rows & colInds <= cols, :);
if isempty(matches)
    matches = zeros(0, 2, 'uint32');
end

%-------------------------------------------------------------------------
function paddedCost = getPaddedCost(cost, costUnmatchedTracks,...
    costUnmatchedDetections)
% replace infinities with the biggest possible number
bigNumber = getTheHighestPossibleCost(cost);
cost(isinf(cost)) = bigNumber;

% create a "padded" cost matrix, with dummy rows and columns
% to account for the possibility of not matching
rows = size(cost, 1);
cols = size(cost, 2);
paddedSize = rows + cols;
paddedCost = ones(paddedSize, class(cost)) * bigNumber;

paddedCost(1:rows, 1:cols) = cost;

for i = 1:rows
    paddedCost(i, cols+i) = costUnmatchedTracks(i);
end
for i = 1:cols
    paddedCost(rows+i, i) = costUnmatchedDetections(i);
end
paddedCost(rows+1:end, cols+1:end) = 0;

%-------------------------------------------------------------------------
function bigNumber = getTheHighestPossibleCost(cost)
if isinteger(cost)
    bigNumber = intmax(class(cost));
else
    bigNumber = realmax(class(cost));
end

%-------------------------------------------------------------------------
function assignment = hungarianAssignment(cost)

assignment = true(size(cost));
if isempty(cost)
    return;
end

% step 1: subtract row minima
cost = bsxfun(@minus, cost, min(cost, [], 2));

% step 2: make an initial assignment by "starring" zeros 
stars = makeInitialAssignment(cost);
% step 3: cover all columns containing starred zeros
colCover = any(stars);

while ~all(colCover)
    % uncover all rows and unprime all zeros
    rowCover = false(1, size(cost, 1));
    primes = false(size(stars));
    Z = ~cost; % mark locations of the zeros
    Z(:, colCover) = false;
    while 1
        shouldCreateNewZero = true;
        % step 4: Find a noncovered zero and prime it.
        [zi, zj] = findNonCoveredZero(Z);
        while zi > 0
            primes(zi, zj) = true;
            % find a starred zero in the column containing the primed zero
            starredRow = stars(zi, :);
            if any(starredRow)
                % if there is one, cover the its row and uncover
                % its column.
                rowCover(zi) = true;
                colCover(starredRow) = false;
                Z(zi, :) = false;
                Z(~rowCover, starredRow) = ~cost(~rowCover, starredRow);
                [zi, zj] = findNonCoveredZero(Z);
            else
                shouldCreateNewZero = false;
                % go to step 5
                break;
            end
        end
        
        if shouldCreateNewZero
            % step 6: create a new zero
            [cost, Z] = createNewZero(cost, rowCover, colCover);
        else
            break;
        end
    end
    
    % step 5: Construct a series of alternating primed and starred zeros.
    stars = alternatePrimesAndStars(stars, primes, zi, zj);
    % step 3: cover all columns containing starred zeros
    colCover = any(stars);
end
assignment = stars;

%-------------------------------------------------------------------------
function stars = makeInitialAssignment(cost)
rowCover = false(1, size(cost, 1));
colCover = false(1, size(cost, 2));
stars = false(size(cost));

[zr, zc] = find(cost == 0);
for i = 1:numel(zr)
    if ~rowCover(zr(i)) && ~colCover(zc(i))
        stars(zr(i), zc(i)) = true;
        rowCover(zr(i)) = true;
        colCover(zc(i)) = true;
    end
end

%-------------------------------------------------------------------------
function [zi, zj] = findNonCoveredZero(Z)
[i, j] = find(Z, 1);
if isempty(i)
    zi = -1;
    zj = -1;
else
    zi = i(1);
    zj = j(1);
end

%-------------------------------------------------------------------------
function [cost, Z] = createNewZero(cost, rowCover, colCover)
Z = false(size(cost));

% find a minimum uncovered value
uncovered = cost(~rowCover, ~colCover);
minVal = min(uncovered(:));

% add the minimum value to all intersections of covered rows and cols
cost(rowCover, colCover) = cost(rowCover, colCover) + minVal;
    
% subtract the minimum value from all uncovered entries creating at
% least one new zero
cost(~rowCover, ~colCover) = uncovered - minVal;
    
% mark locations of all uncovered zeros
Z(~rowCover, ~colCover) = ~cost(~rowCover, ~colCover);

%-------------------------------------------------------------------------
% Step 5.
% Construct a series of alternating primed and starred zeros.  
% Start with the primed uncovered zero Z0 at (zi, zj).  Find a starred zero 
% Z1 in the column of Z0. Star Z0, and unstar Z1. Find a primed zero Z2 in 
% the row of Z1. If the are no starred zeros in the column of Z2, stop.  
% Otherwise repeat with Z0 = Z2.
function stars = alternatePrimesAndStars(stars, primes, zi, zj)
nRows = size(stars, 1);
nCols = size(stars, 2);

% create a logical index of Z0
lzi = false(1, nRows);
lzj = false(1, nCols);
lzi(zi) = true;
lzj(zj) = true;

% find a starred zero Z1 in the column of Z0
rowInd = stars(1:nRows, lzj);

% star Z0
stars(lzi, lzj) = true;

while any(rowInd(:))
    % unstar Z1
    stars(rowInd, lzj) = false;
    
    % find a primed zero Z2 in Z1's row
    llzj = primes(rowInd, 1:nCols);
    lzj = llzj(1, :);
    lzi = rowInd;
    
    % find a starred zero in Z2's column
    rowInd = stars(1:nRows, lzj);
    
    % star Z2
    stars(lzi, lzj) = true;
end

