% approximateKMeans Performs approximate K-Means clustering.
%   [centers, assignments] = approximateKMeans(features, K) clusters
%   features into K groups and returns the cluster centers and the feature
%   vector assignments to each cluster. features must be a M-by-N matrix,
%   where M is the number of features to cluster, and N is the dimension of
%   each feature vector. The output centers is a K-by-N matrix of cluster
%   centers. assignments is a 1-by-M array of cluster assignments.
%
%   [...] = approximateKMeans(...,Name,Value) specifies additional
%   name-value pair arguments described below:
%
%   'MaxIterations'   Maximum number of iterations before the K-Means
%                     algorithm is terminated.
%
%                     Default: 100
%
%   'Threshold'       When the change in the total sum of intra-cluster
%                     distances is below the Threshold, the K-Means
%                     algorithm is terminated.
%
%                     Default: 0.0001
%
%   'NumTrials'       The number of times the K-Means algorithm is run with
%                     different initial cluster centers. The solution with
%                     the lowest total sum of intra-cluster distances is
%                     returned.
%
%                     Default: 1
%
%   'Initialization'  Specify the method used to initialize the cluster
%                     centers as 'Random' or 'KMeans++'.
%
%                     Default: 'KMeans++'
%
%

% References
% ----------
% J. Philbin, O. Chum, M. Isard, J. Sivic, and A. Zisserman. Object
% retrieval with large vocabularies and fast spatial matching. InProc.
% Computer Vision and Pattern Recognition (CVPR), 2007
%
% Arthur, D. and Vassilvitskii, S. (2007). "k-means++: the advantages of
% careful seeding". Proceedings of the eighteenth annual ACM-SIAM symposium
% on Discrete algorithms. Society for Industrial and Applied Mathematics
% Philadelphia, PA, USA. pp. 1027-1035.

%   Copyright 2014 MathWorks, Inc.

function [bestCenters, bestAssignments] = approximateKMeans(features, K, varargin)

params = parseInputs(features, K, varargin{:});

printer = vision.internal.MessagePrinter.configure(params.Verbose);

N = size(features,1);

bestCompactness = inf('like', features);

printer.printMessage('vision:kmeans:numFeatures', N);
printer.printMessage('vision:kmeans:numClusters', K).linebreak;

trial = 1;

while trial <= params.NumTrials
    
    centers = initializeClusterCenters(features, K, params, printer);
    
    printTrialStartMessage(printer, trial, params);
    
    msg = printProgress(printer, '', 0, params.MaxIterations,'');
    
    [assignments, dists, isValid] = assignDataToClusters(features, centers, params);
    
    % Remove invalid features that contain Inf or NaN
    if any(~isValid)
        features = features(logical(isValid),:);
    
        if isempty(features)
            error(message('vision:kmeans:allHadInfNaN'));
        elseif size(features, 1) < K
            error(message('vision:kmeans:tooManyInfNaN', K));
        else
            warning(message('vision:kmeans:droppingInfNaN', ...
                N-size(features,1), N));
        end
        
        N = size(features,1);
        
        % Do not count this as a valid trial.
        continue
    end
    
    [centers, assignments] = updateClusterCenters(features, assignments, dists, K, params);
    
    prevCompactness = clusterCompactness(features, centers, assignments);
    prevDist        = dists;
    prevAssignments = assignments;
          
    for i = 1:params.MaxIterations
        start = tic;
        [assignments, dists] = assignDataToClusters(features, centers, params);
        
        % The approximate neighbor search can produce a worse cluster
        % assignment than the previous iteration. Keep the old assignment when
        % this happens.
        idx = (prevAssignments~=assignments) & (prevDist < dists);
        
        assignments(idx) = prevAssignments(idx);
        
        [centers, assignments] = updateClusterCenters(features, assignments, dists, K, params);
        
        % Evaluate termination criteria
        compactness = clusterCompactness(features, centers, assignments);
                
        delta = abs(prevCompactness - compactness)/(prevCompactness + eps(single(1)));
        
        elapsedTimeMessage = sprintf('(~%.2f seconds/iteration)',toc(start));
        msg = printProgress(printer, msg, i, params.MaxIterations, elapsedTimeMessage);
        
        if delta <= params.Threshold;
            printer.printMessage('vision:kmeans:trialEnd', i);
            break;
        end
        
        prevCompactness = compactness;
        prevDist        = dists;
        prevAssignments = assignments;                
    end
    
    if compactness < bestCompactness
        bestCompactness = compactness;
        bestCenters     = centers;
        bestAssignments = assignments;
    end
    
    % completed trial
    trial = trial + 1;
end

printer.linebreak;

%--------------------------------------------------------------------------
function [assignments, dists, varargout] = assignDataToClusters(features, centers, params)

% capture the rand state for each assignment. This is used in parallel
% code paths to ensure KD-Tree indexing is deterministic on all workers. 
randState = rng;

if params.UseParallel
    [assignments, dists, varargout{1:nargout-2}] = assignDataToClustersParallel(features, centers, randState);
else
    [assignments, dists, varargout{1:nargout-2}] = assignDataToClustersSerial(features, centers, randState);
end

%--------------------------------------------------------------------------
function [assignments, dists, varargout] = assignDataToClustersSerial(features, centers, randState)
if isempty(features)
    assignments = [];
    dists       = [];
    if nargout == 3
        varargout{1} = [];
    end
else
    
    searcher = vision.internal.Kdtree();
    
    % Set rand state explicity prior to indexing. This allows the rand
    % state to be provided as an input argument in parallel code paths and
    % ensure deterministic results.    
    sPrev = rng(randState);
    searcher.index(centers);
    rng(sPrev);
    
    opts.checks    = int32(32);
    opts.eps       = single(0);
    opts.grainSize = int32(10000);
    opts.tbbQueryThreshold = uint32(10000);

    [assignments, dists, varargout{1:nargout-2}] = searcher.knnSearch(features, 1, opts); % find only the closest neighbor
end
%--------------------------------------------------------------------------
function [assignments, dists, varargout] = assignDataToClustersParallel(features, centers, randState)

% outputs
assignments = [];
dists       = [];
isValid     = [];

[numFeatures, featureDim] = size(features);

% get the current parallel pool
pool = gcp();

if isempty(pool)
    [assignments, dists] = assignDataToClustersSerial(features, centers, randState);
else
    
    % Divide the work evenly amongst the workers. This helps minimize the
    % number of indexing operations.
    chunkSize = floor(numFeatures/pool.NumWorkers);
    
    % The remainder is processed in serial
    if chunkSize == 0
        remainder = numFeatures;
    else
        remainder = rem(numFeatures,chunkSize);
    end

    % features are reshaped into 3-D array to avoid data copies between
    % workers.
    featuresCube = reshape(features(1:end-remainder,:)', featureDim, chunkSize, []);
    
    parfor n = 1:size(featuresCube,3)
        
        f = reshape(featuresCube(:,:,n),featureDim,[])';
        
        [tassignments, tdists, tisValid] = assignDataToClustersSerial(f, centers, randState);
        
        assignments = [assignments tassignments];
        dists       = [dists tdists];
        isValid     = [isValid; tisValid];
    end
    
    % finish the remainder
    [tassignments, tdists, tisValid] = assignDataToClustersSerial(...
        features(end-remainder+1:end,:), centers, randState);
    
    assignments = [assignments tassignments];
    dists       = [dists tdists];
    isValid     = [isValid; tisValid];
        
    if nargout == 3
        varargout{1} = isValid;
    end

end

%--------------------------------------------------------------------------
function [centers, assignments] = updateClusterCenters(features, assignments, dists, K, params)

if params.UseParallel
    [centers, assignments] = updateClusterCentersParallel(features, assignments, dists, K);
else
    [centers, assignments] = updateClusterCentersSerial(features, assignments, dists, K);
end

%--------------------------------------------------------------------------
function [centers, assignments] = updateClusterCentersSerial(features, assignments, dists, K)

[centerSums, counts] = sumClusterFeatures(features, assignments, K);

[centerSums, assignments, counts] = reinitializeEmptyClusters(features, assignments, centerSums, counts, dists);  

centers = computeClusterCenters(centerSums, counts);

%--------------------------------------------------------------------------
% Returns updated cluster centers and cluster assignments. The cluster
% update is done in parallel by computing partial cluster summations in
% parallel and then averaging at the end.
%
%    1) Split up all the features into distinct sub-sets.
%    2) For each feature sub-set, sum the contribution of each feature to
%       its assigned cluster. And keep track of the number of features
%       belonging to each cluster. The overall cluster sum is tabulated as
%       a parallel reduction within the parfor loop.
%    3) After all sub-sets are processed in parallel, serially compute the
%       cluster centers using the cluster sums and counts.
%--------------------------------------------------------------------------
function [centers, assignments] = updateClusterCentersParallel(features, assignments, dists, K)

[numFeatures, featureDim] = size(features);

% get the current parallel pool
pool = gcp();

if isempty(pool)
    [centers, assignments] = updateClusterCentersSerial(features, assignments, dists, K);
else
    % Divide the work evenly amongst the workers. This helps minimize the
    % number of indexing operations.
    chunkSize = floor(numFeatures/pool.NumWorkers);
    
    % The remainder is processed in serial
    if chunkSize == 0
        remainder = numFeatures;
    else
        remainder = rem(numFeatures,chunkSize);
    end

    % Data is reshaped into 3-D array to avoid data copies between workers.
    assignmentsCube = reshape(assignments(1:end-remainder), 1, chunkSize, []);
    featuresCube    = reshape(features(1:end-remainder,:)', featureDim, chunkSize, []);
    
    % Process chucks of the data in parallel and compute partial cluster
    % sums. These partial sums are then averaged serially for the final
    % cluster center.
    centerSums = zeros(K, featureDim);
    counts     = zeros(K,1);
    parfor n = 1:size(featuresCube,3)
        f = reshape(featuresCube(:,:,n),featureDim,[])';                
        
        a = assignmentsCube(:,:,n);
                
        [partialSums, partialCounts] = sumClusterFeatures(f, a, K);

        centerSums = centerSums + partialSums;
        counts     = counts     + partialCounts;
    end
    
    % finish the remainder
    f = features(end-remainder+1:end,:);
    a = assignments(end-remainder+1:end);
    
    [partialSums, partialCounts] = sumClusterFeatures(f, a, K);
    
    centerSums = centerSums + partialSums;
    counts     = counts     + partialCounts;
       
    [centerSums, assignments, counts] = reinitializeEmptyClusters(features, assignments, centerSums, counts, dists);       
        
    centers = computeClusterCenters(centerSums, counts);
    
end

%--------------------------------------------------------------------------
function centers = computeClusterCenters(centerSums, counts)
K = numel(counts);
countInv = spdiags(1./(counts+eps), 0, K, K);  % reduce storage costs of K-by-K diagonal matrix
centers  = single(full(countInv * centerSums)); 

%--------------------------------------------------------------------------
function [accum, counts] = sumClusterFeatures(features, assignments, K)
% sum up features assigned to each cluster. To be used during cluster
% update.

[M, N] = size(features);

accum  = zeros(K, N); 
counts = zeros(K, 1);

% Load assignments into sparse matrix to avoid checks within the for-loop
assignmentMatrix = sparse(1:M, double(assignments), logical(assignments), M, K);

for k = 1:K
    accum(k,:) = sum(features(assignmentMatrix(:,k),:), 1, 'double'); % accumulate in double for precision.
    counts(k)  = nnz(assignmentMatrix(:,k));
end

%--------------------------------------------------------------------------
% Returns updated cluster sums, assignments and counts. For each empty
% cluster, reinitialize it using a feature that is the furthest from any
% other cluster center, taking care not to create more empty clusters in
% the process.
%--------------------------------------------------------------------------
function [centerSums, assignments, counts] = reinitializeEmptyClusters(...
    features, assignments, centerSums, counts, dists)

emptyClusterIdx = find(counts == 0);

for i = 1:numel(emptyClusterIdx)
    
    empty = emptyClusterIdx(i);
    
    clusterIsEmpty = true;
    while clusterIsEmpty
                
        [maxValue, idx] = max(dists);
        
        if maxValue == -inf
            % No alternate choices left.
            break;
        end
        
        % Prevent feature from being selected again
        dists(idx) = -inf(1,'like',dists);        
        
        % Remove feature from assigned cluster only if another empty
        % cluster is not created in the process.
        previous = assignments(idx);
        if counts(previous) > 1
            
            assignments(idx) = empty;
            
            % remove feature from it's previous cluster
            centerSums(previous, :) = centerSums(previous, :) - features(idx, :);
            counts(previous)        = counts(previous) - 1;
            
            % and move feature to empty cluster
            centerSums(empty, :) = features(idx, :);
            counts(empty)       = 1;
                                    
            clusterIsEmpty = false;
        end
    end
    
end

%--------------------------------------------------------------------------
function compactness = clusterCompactness(features, centers, assignments)

compactness = sum(sum((centers(assignments,:) - features).^2, 2));

%--------------------------------------------------------------------------
function centers = initializeClusterCenters(features, K, params, printer)

if strcmpi(params.Initialization, 'random')
    
    centers = randomClusterInit(features,K);
else
    
    centers = kmeansPlusPlusInit(features, K, printer);
end

%--------------------------------------------------------------------------
% Select cluster centers randomly.
function centers = randomClusterInit(features, K)

N = size(features, 1);

idx     = randperm(N,K);
centers = features(idx,:);

%--------------------------------------------------------------------------
% Initialize cluster centers using KMeans++.
function centers = kmeansPlusPlusInit(features, K, printer)

[M,N] = size(features);

centers       = zeros(K, N, 'like', features);
centerIndices = zeros(1,K);
minDistances  = inf(M,1,'like',features);

one = ones(1,'like', features);

% Select first center randomly
centerIndices(1) = randi(M,1);
centers(1, :)    = features(centerIndices(1), :);

printer.printMessageNoReturn('vision:kmeans:initialization');

featuresTransposed = features';

msg = '';
for k = 2:K
    % Randomly select next cluster center based on weighted distances to
    % current set of cluster centers. This biases the center selection
    % towards those centers that are furthest away from existing centers.
    
    msg = printInitProgress(printer, msg, k, K);
    
    % Compute squared distances from features to the newest cluster center
    dists = visionSSDMetric(featuresTransposed, centers(k-1,:)');
    
    % Update the minimum distances to the cluster centers
    minDistances = min(dists, minDistances);
    
    samplingWeights = bsxfun(@rdivide, minDistances, ...
        sum(minDistances) + eps(class(minDistances)));
    
    % Weighted sampling using the minimum distances as weights.
    edges = [0; cumsum(samplingWeights)];
    
    edges(end)         = one; % CDF must end at 1
    edges(edges > one) = one; % and must have all values <= 1
    
    if all(isfinite(edges))
        centerIndices(k) = discretize(rand(1), edges);
    else
        % pick a random center when edges have Infs or NaNs
        centerIndices(k) = randi(M,1);
    end
    
    centers(k, :) = features(centerIndices(k), :);
    
end
printer.print('.\n');

%--------------------------------------------------------------------------
function params = parseInputs(features, K, varargin)

if size(features, 1) < K
    error(message('vision:kmeans:numDataGTEqK'))
end

parser = inputParser();
parser.addOptional('MaxIterations', 100, @checkMaxIterations);
parser.addOptional('Threshold', single(.0001), @checkThreshold);
parser.addOptional('Initialization', 'KMeans++');
parser.addOptional('Verbose', false);
parser.addOptional('NumTrials', 1, @(x)isscalar(x) && isnumeric(x));
parser.addOptional('UseParallel', vision.internal.useParallelPreference());

parser.parse(varargin{:});

initMethod = validatestring(parser.Results.Initialization, ...
    {'Random', 'KMeans++'}, mfilename);

vision.internal.inputValidation.validateLogical(parser.Results.Verbose,'Verbose');
useParallel = vision.internal.inputValidation.validateUseParallel(parser.Results.UseParallel);

params.MaxIterations  = double (parser.Results.MaxIterations);
params.Threshold      = single (parser.Results.Threshold);
params.Initialization = initMethod;
params.Verbose        = logical(parser.Results.Verbose);
params.NumTrials      = double (parser.Results.NumTrials);
params.UseParallel    = useParallel;
params.K              = K;

%--------------------------------------------------------------------------
function checkMaxIterations(val)

validateattributes(val,{'numeric'}, ...
    {'scalar','integer','positive','real','finite'}, mfilename);

%--------------------------------------------------------------------------
function checkThreshold(val)

validateattributes(val,{'numeric'}, ...
    {'scalar','positive','real','finite'}, mfilename);

%--------------------------------------------------------------------------
function printTrialStartMessage(printer, trial, params)

if params.NumTrials > 1
    printer.printMessageNoReturn('vision:kmeans:trialStart', trial, params.NumTrials);
else
    printer.printMessageNoReturn('vision:kmeans:clustering');
end

%--------------------------------------------------------------------------
function updateMessage(printer, prevMessage, nextMessage)
backspace = sprintf(repmat('\b',1,numel(prevMessage))); % figure how much to delete
printer.printDoNotEscapePercent([backspace nextMessage]);

%--------------------------------------------------------------------------
function nextMessage = printInitProgress(printer, prevMessage, k, K)
nextMessage = sprintf('%.2f%%%%',100*k/K);
updateMessage(printer, prevMessage(1:end-1), nextMessage);

%--------------------------------------------------------------------------
function nextMessage = printProgress(printer, prevMessage, i, N, elapsed)
nextMessage = getString(message('vision:kmeans:clusteringProgress',i,N,elapsed));
updateMessage(printer, prevMessage, nextMessage);
