% -------------------------------------------------------------------------
% Compute HOG feature size
% -------------------------------------------------------------------------
function sz = getFeatureSize(params)
%#codegen
nBlocks = vision.internal.hog.getNumBlocksPerWindow(params);
sz = prod([params.NumBins params.BlockSize nBlocks]);
end
