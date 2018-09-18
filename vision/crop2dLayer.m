function layer = crop2dLayer(varargin)
%crop2dLayer 2-D crop layer
%   layer = crop2dLayer('centercrop') creates a layer for center cropping
%   an input feature map. The size, [H W], of the cropped region is
%   automatically determined using the size of a second input feature map
%   connected to this layer. After creating this layer, use connectLayers
%   to connect a second input.
%
%   layer = crop2dLayer([X Y]) creates a layer for cropping an input
%   feature map. [X Y] specifies the upper-left corner location of a
%   cropping window positioned within the first input feature map. X is the
%   location in the horizontal direction and Y is the location is the
%   vertical direction. The size, [H W], of the cropping window is
%   automatically determined by the size of the second input feature map
%   connected to this layer. Use connectLayers to connect a second input to
%   this layer.
%
%   layer = crop2dLayer(..., Name, Value) specifies optional parameter
%   name-value pairs for creating the layer:
%
%      'Name'      - A name for the layer. The default is ''.
%
%   A 2-D crop layer has the following inputs:
%       'in'  - Input feature map to crop.
%       'ref' - Reference feature map whose first and second dimension,
%               [H W], are used to determine the first and second dimension
%               of the cropped output.
%
% Example:
%    % Create a 2-D crop layer and connect both of its inputs using a
%    % layerGraph object.
%
%    layers = [
%        imageInputLayer([32 32 3], 'Name', 'image')
%        crop2dLayer('centercrop', 'Name', 'crop')
%        ]
% 
%    % Create a layerGraph. The first input of crop2dLayer is automatically
%    % connected to the first output of the image input layer.
%    lgraph = layerGraph(layers)
% 
%    % Connect the second input to the image layer output.
%    lgraph = connectLayers(lgraph, 'image', 'crop/ref')  
%    
% See also nnet.cnn.layer.Crop2DLayer, pixelClassificationLayer, fcnLayers,
%          LayerGraph, LayerGraph/connectLayers, trainNetwork.

% Copyright 2017 The MathWorks, Inc.

narginchk(1,3);
args = iParseArguments(varargin{:});

internalLayer = nnet.internal.cnn.layer.Crop2DLayer(args.Name, args.Location, args.Mode);

layer = nnet.cnn.layer.Crop2DLayer(internalLayer);

%--------------------------------------------------------------------------
function args = iParseArguments(varargin)
p = inputParser();
p.addRequired('location');
p.addParameter('Name', '', @nnet.internal.cnn.layer.paramvalidation.validateLayerName);
p.parse(varargin{:});
userInput = p.Results;

loc = iIsValidLocation(userInput.location);

if ischar(loc)
    args.Mode = 'centercrop';
    args.Location = 'auto';
else
    args.Mode = 'custom';
    if isscalar(userInput.location)
        args.Location = repelem(double(userInput.location),1,2);
    else
        args.Location = userInput.location;
    end
    
end
args.Name = char(userInput.Name);

%--------------------------------------------------------------------------
function sz = iIsValidLocation(sz)
validateattributes(sz, {'numeric','char','string'}, {}, mfilename, 'location');
if isstring(sz) || ischar(sz)
    sz = validatestring(sz, {'centercrop'}, 1);
    sz = char(sz); 
else
    validateattributes(sz, {'numeric'}, ...
        {'positive', 'integer', 'real', 'finite', 'nonsparse'},...
        mfilename, 'location');
    
    % must be scalar, 2-element vector, or 2x2 matrix
    if ~(isscalar(sz) || iIsTwoElementVector(sz))
        error(message('vision:cnn_layers:crop2dInvalidLocation'));
    end
end

%--------------------------------------------------------------------------
function tf = iIsTwoElementVector(sz)
tf = isvector(sz) && numel(sz) == 2;  