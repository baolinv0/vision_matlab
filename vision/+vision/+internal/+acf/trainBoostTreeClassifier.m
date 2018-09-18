function model = trainBoostTreeClassifier(X0, X1, nWeak, maxDepth, fracFtrs)
%trainBoostTreeClassifier Train boosted decision tree classifier.
% model = trainBoostTreeClassifier(X0, X1, nWeak, maxDepth, fracFtrs)
% trains discrete adaboost classifier where the weak classifiers are
% decision trees. X0 and X1 are negative and positive examples,
% respectively. Each row is an instance. nWeak is the number of weak
% classifiers. maxDepth specifies the maximum depth of the decision tree.
% fracFtrs is the fraction of features to sample for fast training.
%
% model is the learned boosted tree classifier with the following fields:
%   .fids       - [K x nWeak] feature ids for each node
%   .thrs       - [K x nWeak] threshold corresponding to each fid
%   .child      - [K x nWeak] index of child for each node (1-indexed)
%   .hs         - [K x nWeak] log ratio (.5*log(p/(1-p)) at each node
%   .weights    - [K x nWeak] total sample weight at each node
%   .depth      - [K x nWeak] depth of each node
%   .errs       - [1 x nWeak] error for each tree (for debugging)
%   .losses     - [1 x nWeak] loss after every iteration (for debugging)
%   .treeDepth  - depth of all leaf nodes (or 0 if leaf depth varies)
%
% See also testBinaryTreeClassifier, trainBinaryTreeClassifier,
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

% main loop
N0 = size(X0, 1);
N1 = size(X1, 1);
H0 = zeros(N0,1); 
H1 = zeros(N1,1);
losses = zeros(1, nWeak); 
errs = losses;

nBins = 256;
xMin = min(min(X0),min(X1))-0.01;
xMax = max(max(X0),max(X1))+0.01;
xStep = (xMax-xMin) / (nBins-1);
Xq0 = uint8(bsxfun(@times,bsxfun(@minus,X0,xMin),1./xStep));
Xq1 = uint8(bsxfun(@times,bsxfun(@minus,X1,xMin),1./xStep));

W0 = ones(N0,1) / N0;
W1 = ones(N1,1) / N1;

for i = 1:nWeak
    % train tree and classify each example
    [tree, err] = vision.internal.acf.trainBinaryTreeClassifier(Xq0, Xq1, ...
                    W0, W1, xMin, xStep, maxDepth, fracFtrs, class(X0));

    tree.hs = single((tree.hs > 0) * 2 - 1);
    h0 = vision.internal.acf.testBinaryTreeClassifier(X0, tree);
    h1 = vision.internal.acf.testBinaryTreeClassifier(X1, tree);
    
    % compute alpha and incorporate directly into tree model
    alpha = max(-5, min(5, 0.5*log((1-err)/err)));
    
    if alpha <= 0
        nWeak = i - 1; 
        break; 
    end
    
    tree.hs = tree.hs * alpha;
    
    % update cumulative scores H and weights
    H0 = H0 + h0 * alpha; 
    W0 = exp(H0) / N0 / 2;
    H1 = H1 + h1 * alpha; 
    W1 = exp(-H1) / N1 / 2;
    loss = sum(W0) + sum(W1);
    if i == 1
        trees = repmat(tree, nWeak, 1); 
    end
    
    trees(i) = tree; 
    errs(i) = err; 
    losses(i) = loss;
  
    if (loss < 1e-40) 
        nWeak = i; 
        break; 
    end
end

% create output model struct
k = 0; 
for i = 1:nWeak
    k = max(k, size(trees(i).fids, 1)); 
end

Z = @(type) zeros(k, nWeak, type);
model = struct('fids', Z('uint32'), ...
    'thrs', Z(class(X0)), ...
    'child', Z('uint32'), ...
    'hs', Z('single'), ...
    'weights', Z('single'), ...
    'depth', Z('uint32'), ...
    'errs', errs, ...
    'losses', losses);

for i = 1:nWeak
    T = trees(i); 
    k = size(T.fids, 1);
    model.fids(1:k, i) = T.fids; 
    model.thrs(1:k, i) = T.thrs;
    model.child(1:k, i) = T.child; 
    model.hs(1:k, i) = T.hs;
    model.weights(1:k, i) = T.weights; 
    model.depth(1:k, i) = T.depth;
end

depth = max(model.depth(:));
model.treeDepth = depth * uint32(all(model.depth(~model.child)==depth));
