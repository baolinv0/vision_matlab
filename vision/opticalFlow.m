%opticalFlow Object for storing optical flow.
%
%   opticalFlow object describes optical flow.
%
%   flow = opticalFlow(Vx, Vy) constructs an opticalFlow object from two
%   equal-sized matrices, Vx and Vy. Vx and Vy are the x and y components
%   of velocity.
%
%   opticalFlow properties:
%      Vx          - x component of velocity
%      Vy          - y component of velocity
%      Orientation - Phase angles of flow in radians of size M-by-N, where 
%                    M-by-N is the size of Vx or Vy
%      Magnitude   - Magnitude of flow of size M-by-N
%
%   opticalFlow methods:
%      plot   - Plots the velocity.
%
%   Class Support
%   -------------
%   Vx and Vy can be double or single.
%
%   Example
%   -------
%   % Construct object
%   flow = opticalFlow(randn(100,100),randn(100,100));
%   % Plot velocity as quiver plot
%   plot(flow, 'ScaleFactor', 5);
%
% See also opticalFlowHS, opticalFlowLK, opticalFlowLKDoG, quiver

% Copyright 2014 The MathWorks, Inc.

classdef opticalFlow
%#codegen
   
    properties (SetAccess='private', GetAccess='public', Dependent = true)
        %Vx x component of velocity
        Vx; 
        %Vy y component of velocity
        Vy;  
        %Orientation Phase angles of flow in radians of size M-by-N, where 
        %            M-by-N is the size of Vx or Vy
        Orientation;
        %Magnitude Magnitude of flow of size M-by-N
        Magnitude;
    end   
    
    properties (Access='private')
        pVx;
        pVy;
    end
    
    methods % Accessors for Dependent properties
        %-------------------------------------------------
        function this = set.Vx(this, in)
            this.pVx = in;            
        end
        %-----------------------------------------------
        function out = get.Vx(this)
            out = this.pVx;
        end        
        %-------------------------------------------------
        function this = set.Vy(this, in)
            this.pVy = in;
        end
        %-----------------------------------------------
        function out = get.Vy(this)
            out = this.pVy;
        end  
        %-----------------------------------------------
        function out = get.Orientation(this)
            out = computeAngle(this.pVx, this.pVy);
        end     
        %-----------------------------------------------
        function out = get.Magnitude(this)
            out = computeMagnitude(this.pVx, this.pVy);
        end       
    end 
    
    %-----------------------------------------------------------------------
    methods (Access='public')
        function this = opticalFlow(varargin)
            %MSERRegions constructor
            if (nargin ~= 0) && (nargin ~= 2)
                % user specified one of Vx, Vy, or only either param name
                % or value => all these are error case
                coder.internal.errorIf((nargin ~= 0) && (nargin ~= 2), ...
                    'vision:OpticalFlow:numArgInvalid');
            elseif (nargin == 0)
                this.pVx = zeros(0,1);
                this.pVy = zeros(0,1);
            elseif nargin == 2
                % first argument must be Vx or Param name of a P-V pair
                checkVelocityComponent(varargin{1}, 'Vx', 1);
                checkVelocityComponent(varargin{2}, 'Vy', 2);
                crossCheckVelocityComponents(varargin{1}, varargin{2});
                this.pVx = varargin{1};
                this.pVy = varargin{2};
            end
        end
        
        %------------------------------------------------------------------
        function varargout = plot(this, varargin)
            % plot Plots the velocity
            %   plot(flow) plots the flow vectors
            %
            %   plot(..., Name, Value) specifies additional name-value pairs
            %   described below: 
            %
            %   'DecimationFactor'  A two element vector, [XDecimFactor YDecimFactor] 
            %                       specifies the decimation factor of velocity vectors
            %                       along x and y directions. Use larger values
            %                       to get less-cluttered quiver plot.
            %
            %                       Default: [1 1]
            %
            %   'ScaleFactor'       Scaling factor for velocity vector display. Use 
            %                       larger values to get longer vectors in display.
            %
            %                       Default: 1
            %
            %   'Parent'            Specify an output axes for displaying the visualization.
            %
            %                       Default: gca      
            
            coder.internal.errorIf(~isSimMode(), 'vision:OpticalFlow:plotNotSupported');
            nargoutchk(0,1);
            [h, inputs] = parsePlotInputs(varargin{:});
            XDecimationFactor = inputs.DecimationFactor(1);
            YDecimationFactor = inputs.DecimationFactor(2);

            borderOffset = 1; % this could be user input

            [R, C] = size(this.Vx);
            RV = borderOffset:YDecimationFactor:(R-borderOffset+1);   
            CV = borderOffset:XDecimationFactor:(C-borderOffset+1);   
            [X, Y] = meshgrid(CV,RV);

            velocityX = this.Vx;
            velocityY = this.Vy;
            
            tmpVx = velocityX(RV,CV);
            tmpVy = velocityY(RV,CV);
            tmpVx = tmpVx.*inputs.ScaleFactor;
            tmpVy = tmpVy.*inputs.ScaleFactor;
 
            quiver(h, X(:), Y(:), tmpVx(:), tmpVy(:), 0); 
            
            if nargout == 1
                varargout{1} = h;
            end            
        end        
    end
end    

%--------------------------------------------------------------------------
% Plot input parser
%--------------------------------------------------------------------------
function [h, inputs] = parsePlotInputs(varargin)

% Parse the PV pairs
parser = inputParser;

parser.addParameter('Parent', [], ...
    @vision.internal.inputValidation.validateAxesHandle)

parser.addParameter('DecimationFactor', [1 1], @checkDecimationFactor);
parser.addParameter('ScaleFactor', 1, @checkScaleFactor);

% Parse input
parser.parse(varargin{:});

% Assign return values
h = parser.Results.Parent;

if isempty(h)
    h = gca;
end

inputs.DecimationFactor = parser.Results.DecimationFactor;
inputs.ScaleFactor  = parser.Results.ScaleFactor;

end

function crossCheckVelocityComponents(Vx, Vy)
    crossCheckSizes(Vx, Vy);
    crossCheckDataTypes(Vx, Vy);
end

function  crossCheckSizes(Vx, Vy)
    coder.internal.errorIf(~isequal(size(Vx), size(Vy)), ...
        'vision:OpticalFlow:VxVySizeMismatch');
end

function  checkVelocityComponent(V, name, id)
   validateattributes(V,{'double','single'}, ...
    {'real','nonsparse','2d'}, mfilename, name, id);
end

function  crossCheckDataTypes(Vx, Vy)
    coder.internal.errorIf(~isequal(class(Vx), class(Vy)), ...
        'vision:OpticalFlow:VxVyClassMismatch');
end

function  checkDecimationFactor(decimFactor)
    validateattributes(decimFactor, {'numeric'}, ...
    {'nonempty', 'integer', 'nonsparse', 'vector', 'numel', 2, '>', 0}, ...
    mfilename, 'DecimationFactor'); %#ok<*EMCA>
end

function  checkScaleFactor(scaleFactor)
    validateattributes(scaleFactor, {'numeric'}, ...
    {'nonempty', 'integer', 'nonsparse', 'scalar', '>=', 1}, ...
    mfilename, 'ScaleFactor');
end
            
function ang = computeAngle(Vx, Vy)
    % ang = angle(Vx + sqrt(-1)*Vy);
    % To avoid 'Domain Error' in codegen, use atan2 directly (instead of
    % angle function)
    ang = atan2(Vy, Vx);
end

function mag = computeMagnitude(Vx, Vy)
    mag = sqrt(Vx.*Vx + Vy.*Vy);
end

function flag = isSimMode()

    flag = isempty(coder.target);
end
