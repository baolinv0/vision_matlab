% plotCamera Plot a camera in 3-D coordinates.
%   cam = plotCamera() returns a camera visualization object rendered
%   in the current axes. 
% 
%   cam = plotCamera(cameraTable) returns an array of camera visualization
%   objects rendered in the current axes. cameraTable is a table containing
%   properties of the camera visualization objects. The columns of the
%   table can be any of the camera visualization object properties
%   described below, except for 'Parent'. Additionally, if the table
%   contains a 'ViewId' table, then the view ids will be used as camera
%   labels.
%
%   cam = plotCamera(..., Name, Value) creates a camera visualization
%   object with the property values specified in the argument list.
%   The following properties are supported:
%
%   'Location'       Camera location specified as a 3-element vector of 
%                    [x, y, z] coordinates in the data units of the parent.
%
%                    Default: [0, 0, 0]
%
%   'Orientation'    A 3-by-3 3-D rotation matrix.
% 
%                    Default: eye(3)
%
%   'Size'           The width of camera's base specified as a scalar.
%
%                    Default: 1
%
%   'Label'          Camera label specified as a string.
%
%                    Default: ''
%
%   'Color'          The color of the camera specified as a string or a 
%                    3-element vector of RGB values with the range of [0, 1].
%
%                    Default: [1, 0, 0]   
%
%   'Opacity'        A scalar in the range of [0, 1] specifying the opacity
%                    of the camera.
%
%                    Default: 0.2
%
%   'Visible'        A logical scalar, specifying whether the camera is visible.
% 
%                    Default: true
%
%   'AxesVisible'    A logical scalar, specifying whether to display
%                    camera's axes.
%
%                    Default: false
%
%   'ButtonDownFcn'  Callback function that executes when you click the camera.
%
%                    Default: ''
%
%   'Parent'         Specify an output axes for displaying the visualization.
%
%                    Default: gca
%
%   Example 1 - Create an Animated Camera
%   -------------------------------------
%   % Plot a camera pointing along the Y-axis
%   R = [1     0     0;
%        0     0    -1;
%        0     1     0];
%
%   % Setting opacity of the camera to zero for faster animation.
%   cam = plotCamera('Location', [10 0 20], 'Orientation', R, 'Opacity', 0);
% 
%   % Set view properties
%   grid on
%   axis equal
%   axis manual
%
%   % Make the space large enough for the animation.
%   xlim([-15, 20]);
%   ylim([-15, 20]);
%   zlim([15, 25]);
% 
%   % Make the camera fly in a circle
%   for theta = 0:pi/64:10*pi
%       % Rotation about camera's y-axis
%       T = [cos(theta)  0  sin(theta);
%               0        1      0;
%            -sin(theta) 0  cos(theta)];
%       cam.Orientation = T * R;
%       cam.Location = [10 * cos(theta), 10 * sin(theta), 20];
%       drawnow();
%   end
%
%   Example 2 - Sparse 3-D Reconstruction From Two Views
%   ----------------------------------------------------
%   % This example shows you how to perform sparse 3-D reconstruction from
%   % two views, and how to visualize the resulting 3-D point cloud
%   % together with the camera locations and orientations.
%   % <a href="matlab:web(fullfile(matlabroot,'toolbox','vision','visiondemos','html','StructureFromMotionExample.html'))">View example</a>
%
%   See also showExtrinsics, estimateWorldCameraPose, relativeCameraPose,
%            extrinsics, extrinsicsToCameraPose

function cam = plotCamera(varargin)

params = parseInputs(varargin{:});

% Record the current 'hold' state so that we can restore it later.
holdState = get(params(1).Parent,'NextPlot');

for i = 1:numel(params)
    hCamera(i) = vision.graphics.Camera.plotCameraImpl(...
        double(params(i).Size), double(params(i).Location), ...
        double(params(i).Orientation), params(i).Parent); %#ok<AGROW>
        
    if isfield(params, 'ViewId')
        hCamera(i).Label = num2str(params(i).ViewId); %#ok<AGROW>
    else
        hCamera(i).Label         = params(i).Label; %#ok<AGROW>
    end
    
    hCamera(i).Visible       = params(i).Visible; %#ok<AGROW>
    hCamera(i).Color         = params(i).Color; %#ok<AGROW>
    hCamera(i).Opacity       = params(i).Opacity; %#ok<AGROW>
    hCamera(i).AxesVisible   = params(i).AxesVisible; %#ok<AGROW>
    hCamera(i).ButtonDownFcn = params(i).ButtonDownFcn; %#ok<AGROW>
    hold on;
end

% Restore the hold state.
set(params(1).Parent, 'NextPlot', holdState);

if nargout > 0
    cam = hCamera;
end

%--------------------------------------------------------------------------
function params = parseInputs(varargin)
import vision.graphics.*;

parser = inputParser;
parser.addParameter('Location', [0,0,0], @Camera.checkLocation);
parser.addParameter('Orientation', eye(3), @Camera.checkOrientation);
parser.addParameter('Size', 1, @Camera.checkCameraSize);

parser.addParameter('Color', [1 0 0], @Camera.checkColor);
parser.addParameter('Label', '', @Camera.checkLabel);
parser.addParameter('Visible', true, @Camera.checkVisible);
parser.addParameter('AxesVisible', false, @Camera.checkAxesVisible);
parser.addParameter('Opacity', 0.2, @Camera.checkOpacity);
parser.addParameter('ButtonDownFcn', '', @Camera.checkCallback);

parser.addParameter('Parent', [], @checkParent);

if ~isempty(varargin) && istable(varargin{1})
    camTable = varargin{1};
    checkCameraTable(camTable);
    
    parser.parse(varargin{2:end});
            
    params = table2struct(camTable);
    
    singleParams = parser.Results;
    if isempty(singleParams.Parent)
        singleParams.Parent = gca();
    end
    
    singleParams.Location = singleParams.Location(:)';
    
    singleParamNames = fields(parser.Results);
    for i = 1:numel(singleParamNames)
        if ~isfield(params, singleParamNames{i})
            [params.(singleParamNames{i})] = deal(...
                singleParams.(singleParamNames{i}));
        end
    end    
else
    parser.parse(varargin{:});
    params = parser.Results;
    % Set parent to gca if it is not specified.
    % This must be done after parsing the parameters. Otherwise, a new axes may
    % be created even if parameter validation fails.
    if isempty(params.Parent)
        params.Parent = gca();
    end
    
    % Force location to be a row vector;
    params.Location = params.Location(:)';
end


%--------------------------------------------------------------------------
function tf = checkParent(parent)
tf = vision.internal.inputValidation.validateAxesHandle(parent);

%--------------------------------------------------------------------------
function checkCameraTable(camTable)
import vision.graphics.*;
validator = vision.internal.inputValidation.TableValidator;
validator.CanBeEmpty = false;
validator.OptionalVariableNames = {'ViewId', 'Location', 'Orientation', ...
    'Size', 'Label', 'Color', 'Opacity', 'Visible', 'AxesVisible', ...
    'ButtonDownFcn'};

validator.ValidationFunctions('Location') = @Camera.checkLocation;
validator.ValidationFunctions('Orientation') = @Camera.checkOrientation;
validator.ValidationFunctions('Size') = @Camera.checkCameraSize;
validator.ValidationFunctions('Label') = @Camera.checkLabel;
validator.ValidationFunctions('Visible') = @Camera.checkVisible;
validator.ValidationFunctions('Opacity') = @Camera.checkOpacity;
validator.ValidationFunctions('ButtonDownFcn') = @Camera.checkCallback;
validator.ValidationFunctions('ViewId') = ...
    @(id)validateattributes(id, {'numeric'}, ...
    {'integer', 'scalar', 'nonnegative'}, ...
    mfilename, 'ViewId');

validator.validate(camTable, mfilename, 'cameraTable');

