function [tree, err] = trainBinaryTreeClassifier(Xp, Xn, Wp, Wn, xMin, ...
    xStep, maxDepth, fracFtrs, xType)
%trainBinaryTreeClassifier Train binary decision tree classifier.
% [tree, err] = trainBinaryTreeClassifier(Xp, Xn, Wp, Wn, xMin, xStep, maxDepth, fracFtrs)
% trains a binary decision tree classifier. Xp and Xn are negative examples
% and positve examples respectively, with each row being an instance. Wp
% and Wn are vectors of weights for the examples. All examples must be
% quantized uint8 data. xMin and xStep give the minimum value and step size
% for de-quantization. maxDepth specifies the maximum tree depth allowed.
% fracFtrs specifies the fraction to sample the features.
%
% The output tree is a structure containing following fields:
%   .fids       - [Kx1] feature ids for each node
%   .thrs       - [Kx1] threshold corresponding to each fid
%   .child      - [Kx1] index of child for each node (1-indexed)
%   .hs         - [Kx1] log ratio (0.5*log(p/(1-p)) at each node
%   .weights    - [Kx1] total sample weight at each node
%   .depth      - [Kx1] depth of each node
%
% The output err is the decision tree training error
%
% See also testBinaryTreeClassifier, trainBoostTreeClassifier,
% testBoostTreeClassifier

% Copyright 2016 The MathWorks, Inc.
%
% References
% ----------
%   [1] R. Appel, T. Fuchs, P. Dollár, P. Perona; "Quickly Boosting
%   Decision Trees – Pruning Underachieving Features Early," ICML 2013.

% This code is a modified version of that found in:
%
% Piotr's Computer Vision Matlab Toolbox      Version 3.23
% Copyright 2014 Piotr Dollar & Ron Appel.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see pdollar_toolbox.rights]

nBins = 256;
minWeight = 0.01;

[Np, F] = size(Xp); 
Nq = size(Xn, 1); 

W = sum(Wp) + sum(Wn); 
if (abs(W-1)>1e-3)
    Wp = Wp / W; 
    Wn = Wn / W; 
end

% train decision tree classifier
numTreeNodes = 2 * (Np + Nq); % maximum number of possible tree nodes
thrs = zeros(numTreeNodes, 1, xType); % threshold at each node
hs = zeros(numTreeNodes, 1, 'single'); % predicted output log ratios
weights = hs; % weight of data 
errs = hs; 
fids = zeros(numTreeNodes, 1 , 'uint32'); % zero-based feature id
child = fids; % index of the child for the node, zero indicates leaf node 
depth = fids; % zero-based depth of each node in the tree
wtspAll = cell(numTreeNodes,1); 
wtspAll{1} = Wp; % weights for positive examples
wtsnAll = cell(numTreeNodes,1); 
wtsnAll{1} = Wn; % weights for negative examples
k = 1; 
numTreeNodes = 2; % next available cell
while (k < numTreeNodes)
    % get node weights and prior
    w0 = wtspAll{k};
    Wp = sum(w0);
    wtspAll{k} = []; 
    w1 = wtsnAll{k};
    Wn = sum(w1);
    wtsnAll{k} = []; 
    W = Wp + Wn; 
    prior = Wn / W; 
    weights(k) = W; 
    errs(k) = min(prior, 1-prior);
    hs(k) = max(-4, min(4, 0.5*log(prior/(1-prior))));
  
    % if nearly pure node or insufficient data don't train split
    if (prior < 1e-3 || prior > 1-1e-3 || depth(k) >= maxDepth || W < minWeight)
        k = k + 1; 
        continue; 
    end
    
    fidsSt = (1:F);
    if fracFtrs < 1 
        fidsSt = randperm(F, floor(F*fracFtrs));
    end
    
    % train best stump
    [errsSt, thrsSt] = visionACFBinaryTreeTrain(Xp, Xn, single(w0/W),...
                                single(w1/W), nBins, prior, uint32(fidsSt-1));
  
    [~, fid] = min(errsSt); 
    thr = single(thrsSt(fid)) + 0.5; 
    fid = fidsSt(fid);
  
    % split data and continue
    leftp = Xp(:,fid) < thr; 
    leftn = Xn(:,fid) < thr;
    if ((any(leftp)||any(leftn)) && (any(~leftp)||any(~leftn)))
        thr = xMin(fid) + xStep(fid) * thr;
        child(k) = numTreeNodes; 
        fids(k) = fid - 1; 
        thrs(k) = thr;
        wtspAll{numTreeNodes} = w0.*leftp; 
        wtspAll{numTreeNodes+1} = w0.*~leftp;
        wtsnAll{numTreeNodes} = w1.*leftn; 
        wtsnAll{numTreeNodes+1} = w1.*~leftn;
        depth(numTreeNodes:numTreeNodes+1) = depth(k)+1; 
        numTreeNodes = numTreeNodes + 2;
    end; 
    k = k + 1;
end;
numTreeNodes = numTreeNodes - 1;

% create output model struct
tree = struct('fids', fids(1:numTreeNodes), ...
              'thrs', thrs(1:numTreeNodes), ...
              'child', child(1:numTreeNodes), ...
              'hs', hs(1:numTreeNodes), ...
              'weights', weights(1:numTreeNodes), ...
              'depth', depth(1:numTreeNodes));
if (nargout >= 2)
    err = sum(errs(1:numTreeNodes).*tree.weights.*(tree.child==0));
end
