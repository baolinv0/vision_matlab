function ax = pcshowpair(ptCloudA, ptCloudB, varargin)
%PCSHOWPAIR Visualize differences between point clouds.
%   PCSHOWPAIR(ptCloudA, ptCloudB) creates a visualization of the
%   differences between point cloud ptCloudA and ptCloudB.
% 
%   ax = PCSHOWPAIR(...) returns the plot's axes.
%
%   PCSHOWPAIR(...,Name,Value) uses additional options specified by one
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
%   'BlendFactor'      A scalar between 0 and 1. It specifies the color
%                      blending coefficient, which controls the amount of
%                      magenta in the first point cloud and the amount of
%                      green in the second point cloud.
%
%                      Default: 0.7
%
%   'Parent'           Specify an output axes for displaying the
%                      visualization. 
%
%   Notes 
%   ----- 
%   - Points with NaN or Inf coordinates will not be displayed. 
%
%   - If the point cloud does not contain color information, pure magenta and green are
%     used to render the first and second point cloud, respectively.
%
%   - A 'MarkerSize' greater than 6 points may reduce rendering performance.
%
%   Class Support 
%   ------------- 
%   ptCloudA and ptCloudB must be pointCloud objects.
% 
%   Example: Visualize the difference between two point clouds
%   ----------------------------------------------------------
%   % Load two point clouds captured using Kinect
%   load('livingRoom');
%
%   pc1 = livingRoomData{1};
%   pc2 = livingRoomData{2};
%
%   % Plot and set the viewpoint
%   figure
%   pcshowpair(pc1,pc2,'VerticalAxis','Y','VerticalAxisDir','Down')
%   title('Visualize the difference between two point clouds')
%   xlabel('X(m)')
%   ylabel('Y(m)')
%   zlabel('Z(m)')
%
% See also pointCloud, pcregrigid, pcshow, pcplayer 

%  Copyright 2015 The MathWorks, Inc.

if ~isa(ptCloudA, 'pointCloud')
    error(message('vision:pointcloud:notPointCloudObject', 'ptCloudA'));
end
if ~isa(ptCloudB, 'pointCloud')
    error(message('vision:pointcloud:notPointCloudObject', 'ptCloudB'));
end

[markerSize, vertAxis, vertAxisDir, blendFactor, currentAxes] = validateAndParseOptInputs(varargin{:});
                                 
% Plot to the specified axis, or create a new one
currentAxes = newplot(currentAxes);

% Get the current figure handle
hFigure = get(currentAxes,'Parent');

% Check the renderer
if strcmpi(hFigure.Renderer, 'painters')
    error(message('vision:pointcloud:badRenderer'));
end
            
plotFirstPointCloud(currentAxes, ptCloudA, markerSize, blendFactor);
tf = ishold;
if ~tf
    hold(currentAxes, 'on');
    plotSecondPointCloud(currentAxes, ptCloudB, markerSize, blendFactor);
    hold(currentAxes, 'off');
else
    plotSecondPointCloud(currentAxes, ptCloudB, markerSize, blendFactor);
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
function plotFirstPointCloud(currentAxes, ptCloud, markerSize, blendFactor)
if ptCloud.Count > 0
    % Blend magenta color
    if isempty(ptCloud.Color)
        C = [blendFactor, 0, blendFactor];
    else
        C = im2double(ptCloud.Color);
        if ~ismatrix(C)
            C = reshape(C, [], 3);
        end
        C(:, [1,3]) = C(:, [1,3]) * (1 - blendFactor) + blendFactor;
    end

    count = ptCloud.Count;
    X = ptCloud.Location(1:count);
    Y = ptCloud.Location(count+1:count*2);
    Z = ptCloud.Location(count*2+1:end);    
    scatter3(currentAxes, X, Y, Z, markerSize, C, '.');
end
end

%========================================================================== 
function plotSecondPointCloud(currentAxes, ptCloud, markerSize, blendFactor)
if ptCloud.Count > 0
    % Blend green color
    if isempty(ptCloud.Color)
        C = [0, blendFactor, 0];
    else
        C = im2double(ptCloud.Color);
        if ~ismatrix(C)
            C = reshape(C, [], 3);
        end
        C(:, 2) = C(:, 2) * (1 - blendFactor) + blendFactor;
    end

    count = ptCloud.Count;
    X = ptCloud.Location(1:count);
    Y = ptCloud.Location(count+1:count*2);
    Z = ptCloud.Location(count*2+1:end);    
    scatter3(currentAxes, X, Y, Z, markerSize, C, '.');
end
end

%========================================================================== 
function [markerSize, vertAxis, vertAxisDir, blendFactor, ax] = ...
                                        validateAndParseOptInputs(varargin)

parser = vision.internal.pc.getSharedParamParser(mfilename);

parser.addParameter('BlendFactor', 0.7, ...
            @(x)validateattributes(x, {'single', 'double'}, ...
                {'real', 'scalar', '>=', 0, '<=', 1}, mfilename, 'BlendFactor'));

parser.addParameter('Parent', [], @vision.internal.inputValidation.validateAxesHandle);

parser.parse(varargin{:});
    
params = parser.Results;

markerSize  = params.MarkerSize;
ax          = params.Parent;
blendFactor = params.BlendFactor;
vertAxis    = params.VerticalAxis;
vertAxisDir = params.VerticalAxisDir;

end