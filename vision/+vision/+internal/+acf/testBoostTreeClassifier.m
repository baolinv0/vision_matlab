function hs = testBoostTreeClassifier(X, model, maxDepth, minWeight)
%testBoostTreeClassifier Apply learned boosted decision tree classifier.
%  hs = testBoostTreeClassifier(X, model) returns predicted output log
%  ratios for the input matrix X. X is M-by-N single data matrix, with each
%  row as an instance of N features. model is the boost tree structure
%  returned by trainBoostTreeClassifier.
%
%  hs = testBoostTreeClassifier(..., maxDepth, minWight) takes additional
%  arguments to constrain the search of the trees. maxDepth gives the
%  maximum depth of tree to search, and minWeight gives the minimum sample
%  weight of the tree node. Nodes with weight lower than minWeight is not
%  explored.
%
% See also trainBoostTreeClassifier, trainBinaryTreeClassifier,
% testBinaryTreeClassifier

% Copyright 2016 The MathWorks, Inc.

% This code is a modified version of that found in:
%
% Piotr's Computer Vision Matlab Toolbox      Version 3.23
% Copyright 2014 Piotr Dollar & Ron Appel.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see pdollar_toolbox.rights]

if (nargin < 3 || isempty(maxDepth))
    maxDepth = 0; 
end

if (nargin < 4 || isempty(minWeight))
    minWeight = 0; 
end

if maxDepth > 0
    model.child(model.depth >= maxDepth) = 0; 
end

if minWeight > 0
    model.child(model.weights <= minWeight) = 0; 
end

nWeak = size(model.fids, 2); 
N = size(X, 1); 
hs = zeros(N, 1); 
for i = 1:nWeak
    hsi = visionACFBinaryTreeTest(X, model.thrs(:,i),model.fids(:,i), ...
      model.child(:,i), model.hs(:,i));
    hs = hs + hsi;
end