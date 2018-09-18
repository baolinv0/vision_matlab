function requiresCUDAComputeCapability30(filename)
% requiresCUDAComputeCapability30 
%   requiresCUDAComputeCapability30 will error if the currently selected
%   GPU device cannot be used with the Convolutional Neural Network
%   feature, which requires an NVIDIA GPU with compute capability 3.0

%   Copyright 2016 The MathWorks, Inc.
if ~nnet.internal.cnn.util.isGPUCompatible()
    error(message('vision:rcnn:requiresComputeCapability30',filename))
end
