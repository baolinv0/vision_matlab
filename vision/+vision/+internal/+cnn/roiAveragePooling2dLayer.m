function layer = roiAveragePooling2dLayer(varargin)
%roiAveragePooling2dLayer ROI average pooling layer.
% layer = roiAveragePooling2dLayer(gridSize) returns an ROI average pooling
% layer. gridSize specifies the [height width] used to partition an ROI for
% max pooling. It can be a scalar, in which case the same value is used for
% both height and width. The ROI average pooling layer outputs fixed size
% feature maps given arbitrary sized input ROIs. The output size or an ROI
% max pooling layer is [height width C N], where C is the number of
% channels in the input feature map to the layer, and N is the number of
% input ROIs.
%
% [...] = roiAveragePooling2dLayer(..., 'Name', name) optionally specify the
% name of the layer. By default, the name is set to '' and is automatically
% set at network training time.
%
% Example
% -------
%
% % Create an ROI average pooling layer 
% layer = roiAveragePooling2dLayer([6 6]);
%
% See also vision.cnn.layer.ROIAveragePooling2DLayer, averagePooling2dLayer,
%          trainNetwork, SeriesNetwork.

% Copyright 2016 The MathWorks, Inc.

params = parseInputs(varargin{:});

% Create an internal representation of a roi pooling layer.
internalLayer = vision.internal.cnn.layer.ROIAveragePooling2DLayer(...
    params.Name, params.GridSize);

% Pass the internal layer to a function to construct a user visible
% pooling layer
layer = vision.cnn.layer.ROIAveragePooling2DLayer(internalLayer);

%--------------------------------------------------------------------------
function params = parseInputs(varargin)
p = inputParser;
p.addRequired('gridSize', ...
    @(x)vision.cnn.layer.ROIMaxPooling2DLayer.validateGridSize(x,mfilename,'gridSize'));
p.addParameter('Name', '', @(x)ischar(x) || isstring(x));
parse(p, varargin{:});

params.Name = char(p.Results.Name);

if isscalar(p.Results.gridSize)
    params.GridSize = double(repelem(p.Results.gridSize,2));
else
    params.GridSize = double(p.Results.gridSize);
end