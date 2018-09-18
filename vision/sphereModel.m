classdef sphereModel < vision.internal.EnforceScalarHandle
%sphereModel Object for storing a parametric sphere model.
%   model = sphereModel(params) constructs a parametric sphere model from a
%   1-by-4 vector, params. params has four parameters [xc, yc, zc, r] to
%   describe a sphere equation (x-xc)^2 + (y-yc)^2 + (z-zc)^2 = r^2.
%
%   sphereModel properties (read only):
%      Parameters       - Sphere model parameters
%      Center           - Center of the sphere
%      Radius           - Radius of the sphere
%
%   sphereModel methods:
%      plot             - plot a sphere
%
%   See also sphereModel>plot, pcfitsphere, pointCloud, surf, planeModel, 
%            cylinderModel, pcshow
 
%  Copyright 2015 The MathWorks, Inc.
    properties (GetAccess = public, SetAccess = private)
        % Parameters is a 1-by-4 vector [xc, yc, zc, r] that describes a
        % sphere equation (x-xc)^2 + (y-yc)^2 + (z-zc)^2 = r^2.
        Parameters;
    end
    
    properties(Dependent)
        % Center is a 1-by-3 vector [xc, yc, zc] that specifies the center
        % coordinates of the sphere.
        Center;
        % Radius specifies the radius of the sphere.
        Radius;
    end
        
    methods
        %==================================================================
        % Constructor
        %==================================================================
        % model = sphereModel(params);
        function this = sphereModel(params)
            if nargin == 0
                this.Parameters = [0 0 0 0];
            else
                
                % Validate the inputs
                validateattributes(params, {'single', 'double'}, ...
                    {'real', 'nonsparse', 'finite', 'vector', 'numel', 4}, mfilename, 'params');
                
                validateattributes(params(4), {'single', 'double'}, ...
                    {'scalar','positive'}, mfilename, 'Radius, params(4),');
                
                this.Parameters = params;
            end
        end
        
        %==================================================================
        % Dependent properties
        %==================================================================
        function center = get.Center(this)
            center = this.Parameters(1:3);
        end     
        
        function radius = get.Radius(this)
            radius = this.Parameters(4);
        end
        
        %==================================================================
        % Plot the sphere
        %==================================================================
        function H = plot(this, varargin)
            %plot plot the sphere in a figure window.
            %  H = plot(model) plots a sphere and returns a handle to
            %  <a href="matlab:doc('surf')">surface plot object</a>.
            %
            %  H = plot(..., 'Parent', ax) additionally allows you to
            %  specify an output axes. By default, ax is set to gca.
            %
            %  Example : Detect a sphere in a point cloud
            %  ------------------------------------------
            %  load('object3d.mat');
            % 
            %  figure
            %  pcshow(ptCloud)
            %  xlabel('X(m)')
            %  ylabel('Y(m)')
            %  zlabel('Z(m)')
            %  title('Detect a sphere in a point cloud')
            % 
            %  % Set the maximum point-to-sphere distance (1cm) for sphere fitting
            %  maxDistance = 0.01;
            % 
            %  % Set the roi to constrain the search
            %  roi = [-inf, 0.5; 0.2, 0.4; 0.1, inf];
            %  sampleIndices = findPointsInROI(ptCloud, roi);
            % 
            %  % Detect the globe and extract it from the point cloud
            %  model = pcfitsphere(ptCloud, maxDistance, 'SampleIndices', sampleIndices);
            % 
            %  % Plot the sphere
            %  hold on
            %  plot(model)
            
            currentAxes = validateAndParseInputs(mfilename, varargin{:});
            
            [X, Y, Z] = sphere(30);
            X = this.Radius*X + this.Parameters(1);
            Y = this.Radius*Y + this.Parameters(2);
            Z = this.Radius*Z + this.Parameters(3);
            handle = surf(currentAxes,X,Y,Z);
            if nargout > 0
                H = handle;
            end
        end
    end
    
    methods(Hidden)
        function tf = isempty(this)
            tf = all(this.Parameters == 0);
        end
    end
        
end

%========================================================================== 
function ax = validateAndParseInputs(filename, varargin)
% Parse the PV-pairs

% Setup parser
parser = inputParser;
parser.CaseSensitive = false;
parser.FunctionName  = filename;
parser.addParameter('Parent', [], ...
    @vision.internal.inputValidation.validateAxesHandle);

parser.parse(varargin{:});
ax = parser.Results.Parent;

% Plot to the specified axis, or create a new one
if isempty(ax)
    ax = newplot;
end
end
