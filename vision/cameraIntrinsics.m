%cameraIntrinsics Object for storing intrinsic camera parameters.
%   cameraIntrinsics object holds information about camera's intrinsic 
%   calibration parameters, including the lens distortion parameters.
%
%   intrinsics = cameraIntrinsics(focalLength, principalPoint, imageSize)
%   returns cameraIntrinsics object with camera's focal length specified as
%   [fx, fy] or simply f, camera's principal point specified as [cx, cy], 
%   and size of the image produced by the camera as [mrows, ncols].
%   See <a href="matlab:doc('cameraParameters')">cameraParameters</a> for more details.
%
%   intrinsics = cameraIntrinsics(...,Name,Value) specifies additional 
%   name-value pair arguments described below:
%
%   'RadialDistortion'     A 2-element vector [k1,k2] or a 3-element vector
%                          [k1,k2,k3] describing radial lens distortion.
%
%                          Default: [0,0]
%
%   'TangentialDistortion' A 2-element vector [p1,p2] of coefficients 
%                          describing tangential distortion which occurs
%                          when the lens and the image plane are not parallel.
%
%                          Default: [0,0]
%
%   'Skew'                 Skew of the camera axes. 0 if X and Y axis are
%                          exactly perpendicular. Skew is expressed as 
%                          fy*tan(<skew angle>).
%
%                          Default: 0
%
%   cameraIntrinsics properties (read only):
%      FocalLength          - Camera's focal length in pixels
%      PrincipalPoint       - Camera's optical center in pixels
%      ImageSize            - Image size produced by the camera
%      RadialDistortion     - Radial distortion coefficients
%      TangentialDistortion - Tangential distortion coefficients
%      Skew                 - Camera axes skew
%      IntrinsicMatrix      - A 3-by-3 projection matrix
%
%   Example
%   -------
%   % Define fundamental camera parameters while ignoring lens distortion 
%   % and skew.
%   focalLength    = [800, 800]; % specified in units of pixels
%   principalPoint = [320, 240]; % in pixels [x, y]
%   imageSize      = [480, 640]; % in pixels [mrows, ncols]
%
%   intrinsics = cameraIntrinsics(focalLength, principalPoint, imageSize)
%
%   See also cameraParameters, undistortImage

% Copyright 2016-2017 MathWorks, Inc.

%#codegen

classdef cameraIntrinsics < vision.internal.EnforceScalarValue
    
    properties (SetAccess='private', GetAccess='public')
        
        %FocalLength Focal length in pixels.
        %   FocalLength is a vector [fx, fy].  fx = F * sx and fy = F * sy,
        %   where F is the focal length in world units, typically
        %   millimeters, and [sx, sy] are the number of pixels per world
        %   unit in the x and y direction respectively. Thus, fx and fy are
        %   in pixels.
        FocalLength;
        
        %PrincipalPoint Optical center of the camera.
        %   PrincipalPoint is a vector [cx, cy], containing the
        %   coordinates of the optical center of the camera in pixels.
        PrincipalPoint;
        
        %ImageSize Image size produced by the camera.
        %   ImageSize is a vector [mrows, ncols] corresponding to the image
        %   size produced by the camera.
        ImageSize;        
        
        %RadialDistortion Radial distortion coefficients.
        %   Radial distortion is a 2-element vector [k1 k2] or a 3-element 
        %   vector [k1 k2 k3]. Radial lens distortion is caused by light
        %   rays bending more, the farther away they are from the optical center.
        RadialDistortion;

        %TangentialDistortion Tangential distortion coefficients.
        %   TangentialDistortion is a 2-element vector [p1 p2]. Tangential
        %   distortion is caused by the lens not being exactly parallel to
        %   to the image plane.
        TangentialDistortion;
        
        %Skew Represents skew of the camera axes. 
        %   Skew coefficient is non-zero if X and Y axis are not perpendicular. 
        Skew;
        
        %IntrinsicMatrix A 3-by-3 projection matrix.
        %   IntrinsicMatrix is of the form [fx 0 0; s fy 0; cx cy 1], where
        %   [cx, cy] are the coordinates of the optical center (the
        %   principal point) in pixels and s is the skew parameter which is
        %   0 if the x and y axes are exactly perpendicular. fx = F * sx
        %   and fy = F * sy, where F is the focal length in world units,
        %   typically millimeters, and [sx, sy] are the number of pixels
        %   per world unit in the x and y direction respectively. Thus, fx
        %   and fy are in pixels.
        IntrinsicMatrix;
    end
    
    properties (SetAccess='private', GetAccess='public', Hidden)
       CameraParameters;
    end

    properties (Access=protected, Hidden)
       Version = ver('vision');
    end

    
    methods
        %------------------------------------------------------------------
        % Constructor
        %------------------------------------------------------------------
        function this = cameraIntrinsics(varargin)
            narginchk(3, inf);
            
            r = parseInputs(varargin{:});
            
            % Required parameters
            if isscalar(r.focalLength) % scalar expand
                this.FocalLength   = [r.focalLength, r.focalLength];
            else
                this.FocalLength   = r.focalLength;
            end
            this.PrincipalPoint    = r.principalPoint;
            this.ImageSize         = r.imageSize;
            
            % Parameters from N-V pairs
            this.RadialDistortion     = r.RadialDistortion;
            this.TangentialDistortion = r.TangentialDistortion;
            this.Skew                 = r.Skew;
                        
            % Derived parameters
            this.IntrinsicMatrix  = this.intrinsicMatrix();        
            this.CameraParameters = this.cameraParameters();
            
            % NOTE: classes for the above quantities can be mixed. Use
            % MATLAB rules for choosing the class of intrinsicMatrix, 
            % i.e. single wins.
        end        
    end

    %----------------------------------------------------------------------
    %
    %----------------------------------------------------------------------
    methods (Access='private', Hidden=true)
        
        %------------------------------------------------------------------
        function intrinsicMat = intrinsicMatrix(this)
            intrinsicMat = ...
                [this.FocalLength(1)  , 0                     , 0; ...
                this.Skew             , this.FocalLength(2)   , 0; ...
                this.PrincipalPoint(1), this.PrincipalPoint(2), 1];
        end
        
        %------------------------------------------------------------------
        function camParams = cameraParameters(this)
            camParams = ...
                cameraParameters('IntrinsicMatrix', this.IntrinsicMatrix, ...
                'RadialDistortion',     this.RadialDistortion,...
                'TangentialDistortion', this.TangentialDistortion);
        end                
    end
    
    %----------------------------------------------------------------------
    % Static methods
    %----------------------------------------------------------------------
    methods(Static, Hidden)
        
        %------------------------------------------------------------------
        function checkFocalLength(focalLength)
            inputName = 'focalLength';
            validateattributes(focalLength, {'double', 'single'}, ...
                {'vector','real', 'nonsparse', 'finite', 'positive'}, ...
                mfilename, inputName);
            
            ne = numel(focalLength);            
            coder.internal.errorIf(ne ~= 1 &&  ne ~= 2, ...
                'vision:dims:twoElementVector',inputName);
        end
        
        %------------------------------------------------------------------
        function checkPrincipalPoint(principalPoint)
            validateattributes(principalPoint, {'double', 'single'}, ...
                {'vector','real', 'nonsparse','numel', 2, 'finite', 'positive'}, ...
                mfilename, 'principalPoint');
        end

        %------------------------------------------------------------------
        function checkImageSize(imageSize)
            validateattributes(imageSize, {'double', 'single'}, ...
                {'vector','real', 'nonsparse','numel', 2, 'integer', 'positive'}, ...
                mfilename, 'imageSize');
        end        
        
        %------------------------------------------------------------------
        function checkSkew(skew)
            validateattributes(skew, {'double', 'single'}, ...
                {'scalar','real', 'nonsparse', 'finite'}, mfilename, 'Skew');
        end
        
        %------------------------------------------------------------------
        function this = loadobj(that)
            this = cameraIntrinsics(...
                that.FocalLength,...
                that.PrincipalPoint,...
                that.ImageSize,...
                'RadialDistortion', that.RadialDistortion,...
                'TangentialDistortion', that.TangentialDistortion,...
                'Skew', that.Skew);
        end
        
    end
    
    %----------------------------------------------------------------------
    % saveobj is implemented to ensure compatibility across releases by
    % converting the class to a struct prior to saving it. It also contains
    % a version number, which can be used to customize the loading process.
    methods (Hidden)
       
        function that = saveobj(this)
            that.FocalLength          = this.FocalLength;
            that.PrincipalPoint       = this.PrincipalPoint;
            that.ImageSize            = this.ImageSize;
            that.RadialDistortion     = this.RadialDistortion;
            that.TangentialDistortion = this.TangentialDistortion;
            that.Skew                 = this.Skew;
            that.Version              = this.Version;
        end
        
    end    
    
end

function r = parseInputs(varargin)
% Define default values
defaultParams = struct(...
    'RadialDistortion', [0 0], ...
    'TangentialDistortion', [0 0], ...
    'Skew', 0);

if coder.target('MATLAB') % MATLAB
    r = parseInputsSimulation(defaultParams,varargin{:});
else % Code generation
    r = parseInputsCodegen(defaultParams,varargin{:});
end
end

function r = parseInputsSimulation(defaultParams,varargin)

parser = inputParser;

parser.addRequired('focalLength', @cameraIntrinsics.checkFocalLength);
parser.addRequired('principalPoint', @cameraIntrinsics.checkPrincipalPoint);
parser.addRequired('imageSize', @cameraIntrinsics.checkImageSize);

parser.addParameter('RadialDistortion', defaultParams.RadialDistortion, ...
    @vision.internal.calibration.CameraParametersImpl.checkRadialDistortion);
parser.addParameter('TangentialDistortion', defaultParams.TangentialDistortion,...
    @vision.internal.calibration.CameraParametersImpl.checkTangentialDistortion);

parser.addParameter('Skew', defaultParams.Skew, @cameraIntrinsics.checkSkew);

% Parse and check optional parameters
parser.parse(varargin{:});
r = parser.Results;
end

function r = parseInputsCodegen(defaultParams,varargin)
focalLength = varargin{1};
cameraIntrinsics.checkFocalLength(focalLength);

principalPoint = varargin{2};
cameraIntrinsics.checkPrincipalPoint(principalPoint);

imageSize = varargin{3};
cameraIntrinsics.checkImageSize(imageSize);

parms = struct( ...
    'RadialDistortion', uint32(0), ...
    'TangentialDistortion', uint32(0), ...
    'Skew', uint32(0));

popt = struct( ...
    'CaseSensitivity', false, ...
    'StructExpand', true, ...
    'PartialMatching', false);

optarg = eml_parse_parameter_inputs(parms, popt, varargin{4:end});

radialDistortion = eml_get_parameter_value(optarg.RadialDistortion,...
    defaultParams.RadialDistortion, varargin{4:end});
vision.internal.calibration.CameraParametersImpl.checkRadialDistortion(radialDistortion);

tangentialDistortion = eml_get_parameter_value(optarg.TangentialDistortion,...
    defaultParams.TangentialDistortion, varargin{4:end});
vision.internal.calibration.CameraParametersImpl.checkTangentialDistortion(tangentialDistortion);

skew = eml_get_parameter_value(optarg.Skew,...
    defaultParams.Skew, varargin{4:end});
cameraIntrinsics.checkSkew(skew);

r = struct( ...
    'focalLength', focalLength, ...
    'principalPoint', principalPoint, ...
    'imageSize', imageSize, ...
    'RadialDistortion', radialDistortion, ...
    'TangentialDistortion', tangentialDistortion, ...
    'Skew', skew);
end
