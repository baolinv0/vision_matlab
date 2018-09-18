%BRISKPoints Object for storing BRISK interest points
%
%   BRISKPoints object describes BRISK interest points.
%
%   points = BRISKPoints(location, Name, Value, ...) constructs a
%   BRISKPoints object from an M-by-2 array of [x y] coordinates, location,
%   and additional name-value pairs described below. Note that each
%   additional value can be specified as a scalar or a vector whose
%   length matches the number of coordinates in location.
%
%   The available parameters are:
%
%   'Scale'       Specifies scale at which the interest points were
%                 detected. The scale value represents the radius of the
%                 BRISK sampling pattern used during feature extraction.
%                 For single-scale features, the BRISK sampling pattern has
%                 a radius of ~12 pixels.
%
%                 Default: 12
%
%   'Metric'      Value describing the strength of the detected feature.
%                 The BRISK algorithm uses the FAST corner score as a
%                 metric.
%                 
%
%                 Default: 0.0
%
%   'Orientation' Value, in radians, describing orientation of the detected
%                 feature. It is typically set during the detection
%                 process. 
%
%                 Default: 0.0
%
%   Notes:
%   ======
%   - The main purpose of this class is to pass the data between
%     detectBRISKFeatures and extractFeatures functions. It can also be
%     used to manipulate and plot the data returned by these functions.
%     Using the class to fill the points interactively is considered an
%     advanced maneuver. It is useful in situations where you might want to
%     mix a non-BRISK interest point detector with the BRISK descriptor.
%
%   - 'Orientation' is specified as an angle, in radians, as measured
%     counter-clockwise from the X-axis with the origin at 'Location'.
%     'Orientation' should not be set manually. It is typically set during
%     the extraction process. If BRISK interest points are used to extract
%     a non-BRISK descriptor (e.g. SURF, FREAK, etc.), the Orientation
%     values may be altered during the extraction process depending on the
%     selected descriptor.
%     
%   - Note that BRISKPoints is always a scalar object which may hold many
%     points. Therefore, NUMEL(BRISKPoints) always returns 1. This may be 
%     different from LENGTH(BRISKPoints), which returns the true number
%     of points held by the object.
%
%   BRISKPoints methods:
%      selectStrongest  - Select N interest points with strongest metrics
%      selectUniform    - Select N uniformly spaced interest points
%      plot             - Plot BRISK points
%      length           - Return number of stored points
%      isempty          - Return true for empty BRISKPoints object
%      size             - Return size of the BRISKPoints object
%
%   BRISKPoints properties:
%      Count            - Number of points held by the object
%      Location         - Matrix of [X,Y] point coordinates
%      Scale            - Scale at which the feature was detected
%      Metric           - Strength of each feature
%      Orientation      - Orientation assigned to the feature
%
%   Example 1
%   ---------
%   % Detect BRISK features
%   I = imread('cameraman.tif');
%   points = detectBRISKFeatures(I);
%   strongest = points.selectStrongest(10);
%   imshow(I); hold on;
%   plot(strongest);   % show location and scale
%   strongest.Location % display [x y] coordinates
%
% See also detectBRISKFeatures, detectSURFFeatures, extractFeatures,
%          matchFeatures, detectHarrisFeatures, detectMinEigenFeatures,
%          detectFASTFeatures, MSERRegions, cornerPoints

% References
% ----------
% S. Leutenegger, M. Chli and R. Siegwart, BRISK: Binary Robust Invariant
% Scalable Keypoints, to appear in Proceedings of the IEEE International
% Conference on Computer Vision (ICCV) 2011.

classdef BRISKPoints < vision.internal.BRISKPointsImpl & vision.internal.FeaturePoints
       
    methods(Access=public, Static)
        function name = matlabCodegenRedirect(~)
            name = 'vision.internal.BRISKPoints_cg';
        end
    end
    methods
        function this = BRISKPoints(varargin)
            this = this@vision.internal.BRISKPointsImpl(varargin{:});                
        end

        function varargout = plot(this, varargin)
            %plot Plot feature points
            %
            %   BRISKPoints.plot plots feature points in the current axis.
            %
            %   BRISKPoints.plot(AXES_HANDLE,...) plots using axes with
            %   the handle AXES_HANDLE instead of the current axes (gca).
            %
            %   BRISKPoints.plot(AXES_HANDLE, PARAM1, VAL1, PARAM2,
            %   VAL2, ...) controls additional plot parameters:
            %
            %      'showScale'   true or false.  When true, a circle
            %                    proportional to the scale of the detected
            %                    feature is drawn around the point's
            %                    location
            %
            %                    Default: true
            %
            %      'showOrientation' true or false. When true, a line
            %                    corresponding to the point's orientation
            %                    is drawn from the point's location to the
            %                    edge of the circle indicating the scale
            %
            %                    Default: false                       
            %
            %   Example
            %   -------
            %   I = imread('cameraman.tif');
            %   featurePoints = detectBRISKFeatures(I);
            %   imshow(I); hold on;
            %   plot(featurePoints);
            
            nargoutchk(0,1);
            
            supportsScaleAndOrientation = true;
                        
            this.PlotScaleFactor = 1; 
            
            h = plot@vision.internal.FeaturePoints(this, ...
                supportsScaleAndOrientation, varargin{:});
            
            if nargout == 1
                varargout{1} = h;
            end
            
        end
    end
    
    methods (Access = protected)
        %------------------------------------------------------------------
        % Copy data for subsref. This method is used in subsref
        function this = subsref_data(this, option)
            
            this = subsref_data@vision.internal.FeaturePoints(this,option);
            % Scale is a Mx1 vector. When the indices for sub-referencing
            % is a 1-D array, we explicitly specify the size for the second
            % dimension.
            
            if length(option.subs) == 1
                option.subs{2} = 1;
            end
            
            this.pScale = subsref(this.pScale,option);
            this.pOrientation = subsref(this.pOrientation,option);
        end
        
        %------------------------------------------------------------------
        % Copy data for subsasgn. This method is used in subsasgn
        function this = subsasgn_data(this, option, in)
            
            this = subsasgn_data@vision.internal.FeaturePoints(this, option, in);
            
            if isempty(in)
                this.pScale = ...
                    subsasgn(this.pScale, option, in);
                
                this.pOrientation = ...
                    subsasgn(this.pOrientation, option, in);
            else
                this.pScale = ...
                    subsasgn(this.pScale, option, in.pScale);
                
                this.pOrientation = ...
                    subsasgn(this.pOrientation, option, in.pOrientation);
            end
        end
        
        %------------------------------------------------------------------
        % Concatenate data for vertcat. This method is used in vertcat.
        %------------------------------------------------------------------
        function obj = vertcatObj(varargin)
            obj = varargin{1};
             
            for i=2:nargin
                obj.pLocation    = [obj.pLocation; varargin{i}.pLocation];
                obj.pMetric      = [obj.pMetric  ; varargin{i}.pMetric];  
                obj.pScale       = [obj.pScale   ; varargin{i}.pScale];
                obj.pOrientation = [obj.pOrientation ; varargin{i}.pOrientation];
            end
        end        
    end   
end % classdef
