%KAZEPoints Object for storing KAZE interest points
%
%   KAZEPoints object describes KAZE interest points.
%
%   POINTS = KAZEPoints(LOCATION, Name, Value)
%   constructs a KAZEPoints object from an M-by-2 array of [x y]
%   coordinates, LOCATION, and optional input parameters listed below.
%   Note that each additional parameter can be specified as a scalar or
%   a vector whose length matches the number of coordinates in LOCATION.
%   The available parameters are:
%
%
%   'Scale'             Value greater than or equal to 1.6. Specifies size
%                       at which the interest points were detected.
%
%                       Default: 1.6
%
%   'Metric'            Value describing response of detected points. KAZE
%                       algorithm uses a Hessian determinant based
%                       response.
%
%                       Default: 0.0
%
%   'Orientation'       Value, in radians, describing orientation of the
%                       detected feature. It is typically set during the
%                       descriptor extraction process. extractFeatures
%                       function modifies the default value of 0. See
%                       extractFeatures for further details.
%
%                       Default: 0.0
%
%   Notes:
%   ======
%   - The main purpose of this class is to pass the data between
%     detectKAZEFeatures and extractFeatures functions. It can also be used
%     to manipulate and plot the data returned by these functions.
%     Using the class to fill the points interactively is considered an
%     advanced maneuver. It is useful in situations where you might want to
%     mix a non-KAZE interest point detector with a KAZE descriptor.
%   - 'Orientation' is specified as an angle, in radians, as measured from
%     the X-axis with the origin at 'Location'.  'Orientation' should not
%     be set manually.  You should rely on the call to extractFeatures for
%     filling this value. 'Orientation' is mainly useful for visualization
%     purposes.
%   - Note that KAZEPoints is always a scalar object which may hold many
%     points. Therefore, NUMEL(KAZEPoints) always returns 1. This may be
%     different from LENGTH(KAZEPoints), which returns the true number
%     of points held by the object.
%
%   KAZEPoints methods:
%      selectStrongest  - Select N interest points with strongest responses
%      selectUniform    - Select N uniformly spaced interest points
%      plot             - Plot KAZE points
%      length           - Return number of stored points
%      isempty          - Return true for empty KAZEPoints object
%      size             - Return size of the KAZEPoints object
%
%   KAZEPoints properties:
%      Count            - Number of points held by the object
%      Location         - Matrix of [X,Y] point coordinates
%      Scale            - Scale at which the feature was detected
%      Metric           - Strength of each feature
%      Orientation      - Orientation assigned to the feature during
%                         the descriptor extraction process
%
%   Example 1
%   ---------
%   % Detect KAZE features and display 10 strongest points
%   I = imread('cameraman.tif');
%   points = detectKAZEFeatures(I);
%
%   % Display 10 strongest points
%   strongest = selectStrongest(points, 10);
%   imshow(I);
%   hold on;
%   plot(strongest);   % show location and scale
%   hold off;
%   strongest.Location % display [x y] coordinates
%
%   Example 2
%   ---------
%   % Detect KAZE features and display selected points
%   I = imread('cameraman.tif');
%   points = detectKAZEFeatures(I);
%
%   % Display the last 5 points
%   imshow(I);
%   hold on;
%   plot(points(end-4:end));
%   hold off;
%
% See also detectKAZEFeatures, extractFeatures, matchFeatures

% Copyright 2017 The MathWorks, Inc.

classdef KAZEPoints < vision.internal.FeaturePoints & vision.internal.KAZEPointsImpl

    methods (Access='public')
        function this = KAZEPoints(varargin)
            this = this@vision.internal.KAZEPointsImpl(varargin{:});
        end

        %-------------------------------------------------------------------
       function varargout = plot(this, varargin)
           %plot Plot KAZE points
           %
           %   plot plots KAZE points in the current axis.
           %
           %   plot(ax, ~) plots using axes with
           %   the handle ax instead of the current axes (gca).
           %
           %   plot(~, Name, Value) controls
           %   additional plot parameters:
           %
           %      'ShowScale'   true or false.  When true, a circle
           %                    proportional to the scale of the detected
           %                    feature is drawn around the point's
           %                    location.
           %
           %                    Default: true
           %
           %      'ShowOrientation' true or false. When true, a line
           %                    corresponding to the point's orientation
           %                    is drawn from the point's location to the
           %                    edge of the circle indicating the scale.
           %
           %                    Default: false
           %
           %   Notes
           %   -----
           %   - Scale of the feature is represented by a circle of
           %     6*Scale radius, which is equivalent to the size of
           %     circular area used by the KAZE algorithm to compute
           %     orientation of the feature.
           %
           %   Example
           %   -------
           %   % Extract KAZE features
           %   I = imread('cameraman.tif');
           %   points = detectKAZEFeatures(I);
           %   [features, valid_points] = extractFeatures(I, points);
           %   % Visualize 10 strongest KAZE features, including their
           %   % scales and orientation which were determined during the
           %   % descriptor extraction process.
           %   imshow(I);
           %   hold on;
           %   strongestPoints = selectStrongest(valid_points, 10);
           %   plot(strongestPoints, 'showOrientation',true);

           nargoutchk(0,1);

           supportsScaleAndOrientation = true;
           this.PlotScaleFactor = 6;

           h = plot@vision.internal.FeaturePoints(this, ...
               supportsScaleAndOrientation, varargin{:});

           if nargout == 1
               varargout{1} = h;
           end

       end
    end

	methods (Access='public', Hidden=true)
       %-------------------------------------------------------------------
       function this = append(this,varargin)
           %append Appends additional KAZE points
           indexS = this.Count + 1;
           inputs = KAZEPoints(varargin{:});
           checkCompatibility(this, inputs);
           indexE = indexS + size(inputs.Location,1) - 1;
           
           this.pLocation(indexS:indexE, 1:2)     = inputs.Location;
           this.pScale(indexS:indexE, 1)          = inputs.Scale;
           this.pMetric(indexS:indexE, 1)         = inputs.Metric;
           this.pOrientation(indexS:indexE, 1)    = inputs.Orientation;
           this.pLayerID(indexS:indexE, 1)        = inputs.getLayerID;
       end
    end														  
   methods (Access='protected')
       %-------------------------------------------------------------------
       % Copy data for subsref. This method is used in subsref
       function this = subsref_data(this, option)
           this = subsref_data@vision.internal.FeaturePoints(this, option);

           % Scale and Orientation are Mx1 matrices. When
           % the indices for sub-referencing is a 1-D array, we explicitly
           % specify the size for the second dimension.
           if length(option.subs) == 1
               option.subs{2} = 1;
           end

           this.pScale           = subsref(this.pScale,option);
           this.pOrientation     = subsref(this.pOrientation,option);
           this.pLayerID         = subsref(this.pLayerID,option);
       end

       %-------------------------------------------------------------------
       % Copy data for subsasgn. This method is used in subsasgn
       function this = subsasgn_data(this, option, in)
           this = subsasgn_data@vision.internal.FeaturePoints(this, option, in);

           if isempty(in)
               this.pScale = ...
                   subsasgn(this.pScale, option, in);
               this.pOrientation = ...
                   subsasgn(this.pOrientation, option, in);
               this.pLayerID = ...
                   subsasgn(this.pLayerID, option, in);
           else
               this.pScale = ...
                   subsasgn(this.pScale, option, in.pScale);
               this.pOrientation = ...
                   subsasgn(this.pOrientation, option, in.pOrientation);
               this.pLayerID = ...
                   subsasgn(this.pLayerID, option, in.pLayerID);
           end
       end
       %------------------------------------------------------------------
       % Concatenate data for vertcat. This method is used in vertcat.
       %------------------------------------------------------------------
       function obj = vertcatObj(varargin)
           obj = varargin{1};

           for i=2:nargin
               obj.checkCompatibility(varargin{i});
               obj.pLocation    = [obj.pLocation; varargin{i}.pLocation];
               obj.pMetric      = [obj.pMetric  ; varargin{i}.pMetric];
               obj.pScale       = [obj.pScale   ; varargin{i}.pScale];
               obj.pOrientation = [obj.pOrientation ; varargin{i}.pOrientation];
               obj.pLayerID     = [obj.pLayerID; varargin{i}.pLayerID];
           end
       end
   end

   methods (Access='private')
       function checkCompatibility(this, scndObj)
           pass = true;
           errMsg = 'KAZEPoints: Cannot concatenate because points are detected with differences in the following setting(s):';
           if ~strcmp(this.pDiffusion,scndObj.pDiffusion)
               errMsg = [errMsg, '\n- diffusion method'];
               pass = false;
           end
           if(this.pNumOctaves ~= scndObj.pNumOctaves)
               errMsg = [errMsg, '\n- number of octave'];
               pass = false;
           end
           if(this.pNumScaleLevels ~= scndObj.pNumScaleLevels)
               errMsg = [errMsg, '\n- number of scale levels\n'];
               pass = false;
           end
           if ~pass
               error([errMsg,'%s'],'');
           end
       end
	end
end

% LocalWords: OpenCV
