function ax = pcshow(varargin)
%pcshow Plot 3-D point cloud.
%   PCSHOW(ptCloud) displays points with locations and colors
%   stored in the pointCloud object ptCloud. Use this function to display
%   static point cloud data.
% 
%   PCSHOW(xyzPoints) displays points at the locations that are
%   contained in an M-by-3 or M-by-N-by-3 xyzPoints matrix. The matrix,
%   xyzPoints, contains M or M-by-N [x,y,z] points. The color of each point
%   is determined by its Z value, which is linearly mapped to a color in
%   the current colormap.
%
%   PCSHOW(xyzPoints,C) displays points at the locations that are
%   contained in the M-by-3 or M-by-N-by-3 xyzPoints matrix with colors
%   specified by C. To specify the same color for all points, C must be a
%   color string or a 1-by-3 RGB vector. To specify a different color for
%   each point, C must be one of the following:
%   - A vector or M-by-N matrix containing values that are linearly mapped
%   to a color in the current colormap.
%   - An M-by-3 or M-by-N-by-3 matrix containing RGB values for each point.
%
%   PCSHOW(filename) displays the point cloud stored in the file specified
%   by filename. The file must contain a point cloud that PCREAD can read.
%   PCSHOW calls PCREAD to read the point cloud from the file, but does not
%   store the data in the MATLAB workspace.
%
%   ax = PCSHOW(...) returns the plot's axes.
%
%   pcshow(...,Name,Value) uses additional options specified by one
%   or more Name,Value pair arguments below:
%
%   'MarkerSize'       A positive scalar specifying the approximate
%                      diameter of the point marker in points, a unit
%                      defined by MATLAB graphics.
%
%                      Default: 6
%                       
%   'VerticalAxis'     A string specifying the vertical axis, whose value
%                      is 'X', 'Y' or 'Z'. 
%
%                      Default: 'Z'
%
%   'VerticalAxisDir'  A string specifying the direction of the vertical
%                      axis, whose value is 'Up' or 'Down'.
%
%                      Default: 'Up'
%
%   'Parent'           Specify an output axes for displaying the
%                      visualization. 
%
%   Notes 
%   ----- 
%   Points with NaN or inf coordinates will not be plotted. 
%
%   A 'MarkerSize' greater than 6 points may reduce rendering performance.
% 
%   cameratoolbar will be automatically turned on in the current figure.
%
%   Class Support 
%   ------------- 
%   ptCloud must be a pointCloud object. xyzPoints must be numeric. C must
%   be a color string or numeric.
% 
%   Example: Plot spherical point cloud with color 
%   ----------------------------------------------------------------- 
%   % Generate a sphere consisting of 600-by-600 faces
%   numFaces = 600;
%   [x,y,z] = sphere(numFaces);
%   ptCloud = pointCloud([x(:),y(:),z(:)]);
%
%   % plot the sphere with the default color map
%   figure
%   pcshow(ptCloud)
%   title('Sphere with the default color map')
%   xlabel('X')
%   ylabel('Y')
%   zlabel('Z')
%
%   % load an image for texture mapping
%   I = imread('visionteam1.jpg');
%
%   % resize and flip the image for mapping the coordinates 
%   J = flipud(imresize(I, size(x)));
%   colorPtCloud = pointCloud([x(:),y(:),z(:)], 'Color', reshape(J, [], 3));
%
%   % plot the sphere with the color texture
%   figure
%   pcshow(colorPtCloud);
%   title('Sphere with the color texture')
%   xlabel('X')
%   ylabel('Y')
%   zlabel('Z')
%
% See also pointCloud, pcplayer, reconstructScene, triangulate, plot3, scatter3 

%  Copyright 2013-2014 The MathWorks, Inc.

[X, Y, Z, C, markerSize, vertAxis, vertAxisDir, currentAxes] = ...
                            validateAndParseInputs(varargin{:});
          
                        
% Plot to the specified axis, or create a new one
if isempty(currentAxes)
    currentAxes = newplot;
end

% Get the current figure handle
hFigure = get(currentAxes,'Parent');

% Check the renderer
if strcmpi(hFigure.Renderer, 'painters')
    error(message('vision:pointcloud:badRenderer'));
end
              
if isempty(C)
    scatter3(currentAxes, X, Y, Z, markerSize, Z, '.');
elseif (ischar(C) || isequal(size(C),[1,3]))
    try
        plot3(currentAxes, X, Y, Z, '.', 'Color', C, 'MarkerSize', markerSize);
        grid(currentAxes, 'on');
    catch exception
        throwAsCaller(exception);
    end
else
    scatter3(currentAxes, X, Y, Z, markerSize, C, '.');
end

% Lower and upper limit of auto downsampling.
ptCloudThreshold = [1920*1080, 1e8]; 

% Initialize point cloud viewer controls.
vision.internal.pc.initializePCSceneControl(hFigure, currentAxes, vertAxis,...
    vertAxisDir, ptCloudThreshold, true);

if nargout > 0
    ax = currentAxes;
end
end

%========================================================================== 
function [X, Y, Z, C, markerSize, vertAxis, vertAxisDir, ax] = validateAndParseInputs(varargin)
% Validate and parse inputs
narginchk(1, 10);

% the 2nd argument is C only if the number of arguments is even and the
% first argument is not a pointCloud object
if  ~bitget(nargin, 1) && ~isa(varargin{1}, 'pointCloud')
    [X, Y, Z, C] = vision.internal.pc.validateAndParseInputsXYZC(mfilename, varargin{1:2});
    pvpairs = varargin(3:end);
else
    [X, Y, Z, C] = vision.internal.pc.validateAndParseInputsXYZC(mfilename, varargin{1});
    pvpairs = varargin(2:end);
end

parser = vision.internal.pc.getSharedParamParser(mfilename);

parser.addParameter('Parent', [], ...
    @vision.internal.inputValidation.validateAxesHandle);

parser.parse(pvpairs{:});
    
params = parser.Results;

markerSize  = params.MarkerSize;
ax          = params.Parent;
vertAxis    = params.VerticalAxis;
vertAxisDir = params.VerticalAxisDir;

end

