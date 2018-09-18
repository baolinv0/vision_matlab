classdef cylinderModel < vision.internal.EnforceScalarHandle
%cylinderModel Object for storing a parametric cylinder model.
%   model = cylinderModel(params) constructs a parametric cylinder model
%   from a 1-by-7 vector, params. Params has seven parameters [x1, y1,
%   z1, x2, y2, z2, r] to describe a cylinder, where [x1, y1, z1] and [x2,
%   y2, z2] are centers of two end caps, respectively. r is the
%   radius of the cylinder.
%
%   cylinderModel properties (read only):
%      Parameters       - Cylinder model parameters
%      Center           - Center of the cylinder
%      Orientation      - Orientation vector of the cylinder
%      Height           - Height of the cylinder
%      Radius           - Radius of the cylinder
%
%   cylinderModel methods:
%      plot             - plot a cylinder
%
%   See also cylinderModel>plot, pcfitcylinder, pointCloud, surf,
%            planeModel, sphereModel, pcshow
 
%  Copyright 2015 The MathWorks, Inc.
    properties (GetAccess = public, SetAccess = private)
        % Parameters is a 1-by-7 vector [x1, y1, z1, x2, y2, z2, r] to
        % describe a cylinder, where [x1, y1, z1] and [x2, y2, z2] are
        % centers of two ending surfaces, respectively. r is the radius of
        % the cylinder.
        Parameters;
    end
    
    properties(Dependent)
        % Center is a 1-by-3 vector that specifies the center of the cylinder.
        Center;
        % Orientation is a 1-by-3 vector that points from [x1,y1,z1] to
        % [x2,y2,z2], which are the centers of the cylinder end caps.
        Orientation;
        % Height specifies the height of the cylinder.
        Height;
        % Radius specifies the radius of the cylinder.
        Radius;
    end
       
    methods
        %==================================================================
        % Constructor
        %==================================================================
        % model = cylinderModel(params);
        function this = cylinderModel(params)
            if nargin == 0
                this.Parameters = zeros(1,7);
            else
                % Validate the inputs
                validateattributes(params, {'single', 'double'}, ...
                    {'real', 'nonsparse', 'finite', 'vector', 'numel', 7}, mfilename, 'params');
                
                validateattributes(params(7), {'single', 'double'}, ...
                    {'scalar','positive'}, mfilename, 'Radius, params(7),');
                
                this.Parameters = params;
            end
        end
        
        %==================================================================
        % Dependent properties
        %==================================================================
        function center = get.Center(this)
            center = (this.Parameters(1:3)+this.Parameters(4:6))/2;
        end 
        
        function orientation = get.Orientation(this)
            orientation = this.Parameters(4:6)-this.Parameters(1:3);
        end 
        
        function height = get.Height(this)
            p1 = this.Parameters(1:3);
            p2 = this.Parameters(4:6);
            height = norm(p1 - p2);
        end
        
        function radius = get.Radius(this)
            radius = this.Parameters(7);
        end
        
        %==================================================================
        % Plot a cylinder
        %==================================================================
        function H = plot(this, varargin)
            %plot plot a cylinder in a figure window.
            %  H = plot(model) plots a cylinder and returns a handle to
            %  <a href="matlab:doc('surf')">surface plot object</a>.
            %
            %  H = plot(..., 'Parent', ax) additionally allows you to
            %  specify an output axes. By default, ax is set to gca.
            %
            %  Example: Detect a cylinder in a point cloud
            %  -------------------------------------------
            %  load('object3d.mat');
            %    
            %  figure
            %  pcshow(ptCloud)
            %  xlabel('X(m)')
            %  ylabel('Y(m)')
            %  zlabel('Z(m)')
            %  title('Detect a cylinder in a point cloud')
            %  
            %  % Set the maximum point-to-cylinder distance (5mm) for cylinder fitting
            %  maxDistance = 0.005;
            %   
            %  % Set the roi to constrain the search
            %  roi = [0.4, 0.6; -inf, 0.2; 0.1, inf];
            %  sampleIndices = findPointsInROI(ptCloud, roi);
            %  
            %  % Set the orientation constraint
            %  referenceVector = [0, 0, 1];
            %   
            %  % Detect the cylinder and extract it from the point cloud
            %  model = pcfitcylinder(ptCloud, maxDistance, referenceVector, 'SampleIndices', sampleIndices);
            %   
            %  % Plot the cylinder
            %  hold on
            %  plot(model)
            
            currentAxes = validateAndParseInputs(mfilename, varargin{:});
            
            [X, Y, Z] = cylinder(this.Radius, 30);            
            [X, Y, Z] = this.transformCylinder(X, Y, Z);
            
            handle = surf(currentAxes, X, Y, Z);
            if nargout > 0
                H = handle;
            end
        end
    end
    
    methods (Access = protected)        
        %==================================================================
        % helper function to transform the data
        %==================================================================
        function [X, Y, Z] = transformCylinder(this, X, Y, Z)
            a = cast([0, 0, 1], 'like', this.Parameters);
            h = this.Height;
            % Rescale the height
            Z(2, :) = Z(2, :) * h;

            if h == 0
                b = [0, 0, 1];
            else
                b = (this.Parameters(4:6) - this.Parameters(1:3)) / h;
            end
            
            % Rotate the points to the desired axis direction
            v = cross(a, b);
            s = dot(v, v);
            if abs(s) > eps(class(s))
                Vx = [     0, -v(3),  v(2); ...
                        v(3),     0, -v(1); ...
                       -v(2),  v(1),    0];
                R = transpose(eye(3) + Vx + Vx*Vx*(1-dot(a, b))/s);

                T = this.Parameters(1:3);
                if iscolumn(T)
                    T = T';
                end

                XYZ = bsxfun(@plus, [X(:), Y(:), Z(:)] * R, T);
                X = reshape(XYZ(:, 1), 2, []);
                Y = reshape(XYZ(:, 2), 2, []);
                Z = reshape(XYZ(:, 3), 2, []);
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
