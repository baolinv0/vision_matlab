classdef PointTracker < matlab.System
%PointTracker Track points in video using Kanade-Lucas-Tomasi (KLT) algorithm
% 
%   H = vision.PointTracker returns a System object, H, that
%   tracks a set of points using the Kanade-Lucas-Tomasi feature tracking 
%   algorithm.  To initialize the tracking process, you must use
%   the initialize method to specify the initial locations of the points
%   and the initial video frame. Then, use the step method to track the 
%   points in subsequent video frames.  You can also reset the points
%   at any time by using the setPoints method.
% 
%   H = vision.PointTracker(Name, Value, ...)
%   configures the tracker object properties, specified as one or more 
%   name-value pair arguments. Unspecified properties have default values.
% 
%   initialize method syntax:
%   -------------------------
% 
%   initialize(H, POINTS, I) initializes points to track and sets the
%   initial video frame. The initial locations POINTS, must be an M-by-2
%   array of [x y] coordinates. The initial video frame I, must be a 2-D
%   grayscale or RGB image, and must be the same size and data type as the
%   video frames passed to the step method. 
%
%   step method syntax:
%   -------------------
% 
%   [POINTS, POINT_VALIDITY] = step(H, I) tracks the points in the input
%   frame, I. The output POINTS contain an M-by-2 array of [x y]
%   coordinates that correspond to the new locations of the points in the
%   input frame, I. The output, POINT_VALIDITY provides an M-by-1 logical
%   array, indicating whether or not each point has been reliably tracked.
%   The input frame, I must be the same size and data type as the video
%   frames passed to the initialize method. 
% 
%   [POINTS, POINT_VALIDITY, SCORES] = step(H, I) additionally returns the
%   confidence score for each point. The M-by-1 output array, SCORE,
%   contains values between 0 and 1. These values correspond to the degree
%   of similarity between the neighborhood around the previous location and
%   new location of each point. These values are computed as a function of
%   the sum of squared differences between the previous and new
%   neighborhoods. The greatest tracking confidence corresponds to a
%   perfect match score of 1. 
% 
%   setPoints method syntax:
%   ------------------------
%
%   setPoints(H, POINTS) sets the points for tracking. The method sets the
%   M-by-2 POINTS array of [x y] coordinates with the points to track. This
%   method can be used if the points need to be re-detected because too
%   many of them have been lost during tracking. 
%
%   setPoints(H, POINTS, POINT_VALIDITY) additionally lets you mark points
%   as either valid or invalid. The input logical vector POINT_VALIDITY of
%   length M, contains the true or false value corresponding to the
%   validity of the point to be tracked. The length M corresponds to the
%   number of points. A false value indicates an invalid point that should
%   not be tracked. For example, you can use this method with the
%   estimateGeometricTransform function to determine the transformation
%   between the point locations in the previous and current frames, and
%   then mark the outliers as invalid.
% 
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   PointTracker methods:
%   ---------------------
% 
%   step         - See above description for use of this method
%   initialize   - See above description for use of this method
%   setPoints    - See above description for use of this method
%   release      - Allow property value and input characteristics changes
%   clone        - Create a tracker object with the same property values
%   isLocked     - Locked status (logical)
% 
%   PointTracker properties:
%   ------------------------
% 
%   BlockSize              - The size of the integration window around each point.
%   NumPyramidLevels       - The number of pyramid levels.
%   MaxIterations          - The maximum number of search iterations.
%   MaxBidirectionalError  - Maximum threshold on the forward-backward error. 
%   
%
%   Example: Tracking a face
%   ------------------------
% 
%   % Create System objects for reading and displaying video, and for
%   % drawing a bounding box of the object.
%   videoFileReader = vision.VideoFileReader('visionface.avi');
%   videoPlayer = vision.VideoPlayer('Position', [100, 100, 680, 520]);
%
%   % Read the first video frame which contains the object and then show
%   % the object region
%   objectFrame = step(videoFileReader);  % read the first video frame
% 
%   objectRegion = [264, 122, 93, 93];  % define the object region
%   % You can also use the following commands to select the object region
%   % using a mouse. The object must occupy majority of the region.
%   % figure; imshow(objectFrame); objectRegion=round(getPosition(imrect))
%
%   objectImage = insertShape(objectFrame, 'Rectangle', objectRegion, ...
%                             'Color', 'red');
%   figure; imshow(objectImage); title('Red box shows object region');
% 
%   % Detect interest points in the object region
%   points = detectMinEigenFeatures(rgb2gray(objectFrame), 'ROI', objectRegion);
%   
%   % Display the detected points
%   pointImage = insertMarker(objectFrame, points.Location, '+', ...
%                             'Color', 'white');
%   figure, imshow(pointImage), title('Detected interest points');
% 
%   % Create a tracker object.
%   tracker = vision.PointTracker('MaxBidirectionalError', 1);
% 
%   % Initialize the tracker
%   initialize(tracker, points.Location, objectFrame);
% 
%   % Track and display the points in each video frame
%   while ~isDone(videoFileReader)
%     frame = step(videoFileReader);             % Read next image frame
%     [points, validity] = step(tracker, frame);  % Track the points
%     out = insertMarker(frame, points(validity, :), '+'); % Display points
%     step(videoPlayer, out);                    % Show results
%  end
% 
%  release(videoPlayer);
%  release(videoFileReader);
%
%   See also vision.MarkerInserter, detectHarrisFeatures,
%   detectMinEigenFeatures, detectFASTFeatures, imcrop, imrect,
%   vision.HistogramBasedTracker.    
 
%   Copyright 2011-2016 The MathWorks, Inc.
% 
%   References:
%   -----------
% 
%   Bruce D. Lucas and Takeo Kanade. An Iterative Image Registration 
%   Technique with an Application to Stereo Vision. 
%   International Joint Conference on Artificial Intelligence, 1981.
%
%   Carlo Tomasi and Takeo Kanade. Detection and Tracking of Point Features. 
%   Carnegie Mellon University Technical Report CMU-CS-91-132, 1991.
%
%   Jianbo Shi and Carlo Tomasi.   Good Features to Track. 
%   IEEE Conference on Computer Vision and Pattern Recognition, 1994.
%
%   Zdenek Kalal, Krystian Mikolajczyk and Jiri Matas.  Forward-Backward
%   Error: Automatic Detection of Tracking Failures.
%   International Conference on Pattern Recognition, 2010

%#codegen

%#ok<*EMCA>
  properties(Nontunable)
    % MaxBidirectionalError Forward-backward error threshold 
    %   Specify a numeric scalar for the maximum bidirectional error. If 
    %   the value is less than inf, the object tracks each point from the
    %   previous to the current frame, and then tracks the same points back
    %   to the previous frame. The object calculates the bidirectional 
    %   error, which is the distance in pixels from the original location 
    %   of the points to the final location after the backward tracking. 
    %   The corresponding points are considered invalid when the error is 
    %   greater than the value set for this property. Recommended values 
    %   are between 0 and 3 pixels. 
    %
    %   Using the bidirectional error is an effective way to eliminate 
    %   points that could not be reliably tracked. However, the 
    %   bidirectional error requires additional computation. When you set 
    %   the MaxBidirectionalError property to inf, the object will not 
    %   compute the bidirectional error. 
    %
    %   Default: inf
    MaxBidirectionalError = inf;
    
    % BlockSize Size of integration window 
    %   Specify a two-element vector, [height, width] to represent the
    %   neighborhood around each point being tracked. The height and width
    %   must be odd integers. This neighborhood defines the area for the
    %   spatial gradient matrix computation. The minimum value for 
    %   BlockSize is [5 5]. Increasing the size of the neighborhood, 
    %   increases the computation time. 
    %
    %   Default: [31 31]
    BlockSize = [31, 31];
    
    % NumPyramidLevels Number of pyramid levels
    %   Specify an integer scalar number of pyramid levels. The point 
    %   tracker implementation of the KLT algorithm uses image pyramids. 
    %   The object generates an image pyramid, where each level is reduced 
    %   in resolution by a factor of two compared to the previous level. 
    %   Selecting a pyramid level greater than one, enables the algorithm 
    %   to track the points at multiple levels of resolution, starting at 
    %   the lowest level. Increasing the number of pyramid levels allows 
    %   the algorithm to handle larger displacements of points between 
    %   frames, but also increases computation. Recommended values are 
    %   between 1 and 4. 
    %
    %   Default: 3    
    NumPyramidLevels = 3;
    
    % MaxIterations Maximum number of search iterations
    %   Specify a positive integer scalar for the maximum number of search
    %   iterations for each point. The KLT algorithm performs an iterative
    %   search for the new location of each point until convergence.
    %   Typically, the algorithm converges within 10 iterations. This
    %   property sets the limit on the number of search iterations.
    %   Recommended values are between 10 and 50. 
    %
    %   Default: 30    
    MaxIterations = 30;
  end
  
  properties (Transient, Access=private)
    % C++ wrapper for OpenCV KLT       
    pTracker;   
  end
  
  properties (Hidden, Access=private)    
    %The size of the video frame. Needed for input validation.
    FrameSize = [0 0];
    
    %Number of points
    NumPoints = 0;
        
    % Is the image RGB or grayscale? Needed for input validation.
    IsRGB = false;
    
    % The class of the video frame. Needed for clone
    FrameClassID = 0;

  end
  properties (Nontunable, Hidden, Access=private)  
      
    % Has the object been initialized?
    IsInitialized = false;
      
    % The class of the POINTS array. Needed for clone.
    PointClassID = 0;
  end
  
  methods
    %----------------------------------------------------------------------
    % Constructor
    function obj = PointTracker(varargin)
      setProperties(obj, nargin, varargin{:});
       
      if (isSimMode())
        obj.pTracker = vision.internal.PointTracker;
      else
        obj.pTracker = ...
            vision.internal.buildable.pointTrackerBuildable.pointTracker_construct();          
      end
    end
    
    % Public properties validation    
    %----------------------------------------------------------------------
    function set.MaxBidirectionalError(obj, val)
      validateattributes(val, {'numeric'}, ...
        {'scalar', 'real', 'nonnegative', 'nonnan', 'nonsparse'}, ...
        'PointTracker', 'MaxBidirectionalError');   
      obj.MaxBidirectionalError = val;
    end
    %----------------------------------------------------------------------    
    function set.BlockSize(obj, val)
      validateattributes(val, {'numeric'}, ...
        {'positive', 'nonempty', 'nonsparse', 'numel', 2, 'integer', ...
         'vector',  'odd', '>=', 5}, 'PointTracker', 'BlockSize');
        obj.BlockSize = val(:)';
    end
    %----------------------------------------------------------------------    
    function set.NumPyramidLevels(obj, val)
      validateattributes(val, {'numeric'}, ...
       {'scalar', 'nonnegative', 'integer', 'nonsparse'}, ...
       'PointTracker', 'NumPyramidLevels');    
      obj.NumPyramidLevels = val;
    end
    %----------------------------------------------------------------------    
    function set.MaxIterations(obj, val)
      validateattributes(val, {'numeric'}, ...
       {'scalar', 'positive', 'integer', 'nonsparse'}, ...
       'PointTracker', 'MaxIterations')
       obj.MaxIterations = val;
    end
  end
  
  methods(Access=protected)
    %----------------------------------------------------------------------      
    function [points, pointValidity, scores] = stepImpl(obj, I)

      % step() can only be called after initialize()  
      coder.internal.errorIf(~obj.IsInitialized, ...
        'vision:PointTracker:trackerUninitialized');
    
      coder.assertDefined(obj.IsInitialized);
      coder.assertDefined(obj.PointClassID);
      
      % the class of the frame cannot be changed unless the object
      % is released and re-initialized
      coder.internal.errorIf(getClassID(I) ~= obj.FrameClassID, ...
          'vision:PointTracker:expectedSameImageClassAsInitialized');
    
      Iu8 = im2uint8(I);
          
      % see if the image needs to be converted to grayscale
      if size(I, 3) > 1
          coder.internal.errorIf(~obj.IsRGB, ...
              'vision:PointTracker:expectedGrayscale');
          Iu8_gray = rgb2gray(Iu8);
      else
          Iu8_gray = Iu8;
          coder.internal.errorIf(obj.IsRGB, ...
              'vision:PointTracker:expectedRGB');
      end
      
      % the size of the frame cannot be changed unless the object
      % is released and re-initialized
      coder.internal.errorIf(any(size(Iu8_gray) ~= obj.FrameSize), ...
          'vision:PointTracker:expectedSameImageSizeAsInitialized');
      
      if (isSimMode())
          [pointsTmp, pointValidity, scores] = obj.pTracker.step(Iu8_gray);
      else
          [pointsTmp, pointValidity, scores] = ...
              vision.internal.buildable.pointTrackerBuildable.pointTracker_step(...
              obj.pTracker, Iu8_gray, obj.NumPoints);
      end
      % conversion from 0-based to 1-based is done in
      % vision.internal.PointTracker
      
      % mark the points that fell outside the image as invalid
      badPoints = pointsOutsideImage(obj, pointsTmp);
      pointValidity(badPoints) = false;
      
      scores = normalizeScores(obj, scores, pointValidity);
      if isSimMode()
          % data type locked in codegen; so no cast required
          points = cast(pointsTmp, getClassFromID(obj.PointClassID));
      else
          points = castFromID(pointsTmp,coder.internal.const(obj.PointClassID));
      end
    end    
        
    %----------------------------------------------------------------------
    function validateInputsImpl(obj, I)
      obj.validateImage(I);
    end

    %----------------------------------------------------------------------
    function num = getNumOutputsImpl(~)
        num = 3;
    end
    
    %----------------------------------------------------------------------
    function flag = isInputComplexityLockedImpl(~,~)
        flag = true;
    end
    
    %----------------------------------------------------------------------
    function flag = isOutputComplexityLockedImpl(~,~)
        flag = true;
    end
    
    %----------------------------------------------------------------------
    function s = saveObjectImpl(obj)
        % public properties
        s.MaxBidirectionalError = obj.MaxBidirectionalError;
        s.BlockSize = obj.BlockSize;
        s.NumPyramidLevels = obj.NumPyramidLevels;
        s.MaxIterations = obj.MaxIterations;
        
        % private properties
        s.IsInitialized = obj.IsInitialized;
        s.IsRGB = obj.IsRGB;
        s.PointClassID = obj.PointClassID;
        s.FrameClassID = obj.FrameClassID;
        
        % internal state
        if obj.IsInitialized
            if isSimMode()
                s.Frame = getPreviousFrame(obj.pTracker);
                [points, validity] = getPointsAndValidity(obj.pTracker);
            else
                s_Frame = vision.internal.buildable.pointTrackerBuildable.pointTracker_getPreviousFrame(obj.pTracker, obj.FrameSize);
                if coder.isColumnMajor
                   s.Frame = s_Frame';
                end
                [points, validity] = vision.internal.buildable.pointTrackerBuildable.pointTracker_getPointsAndValidity(obj.pTracker, obj.NumPoints);
            end
            
            s.Points = points;
            s.Validity = validity;
        end
    end
    
    %----------------------------------------------------------------------
    function loadObjectImpl(obj,s,~)
        % public properties
        obj.MaxBidirectionalError = s.MaxBidirectionalError;
        obj.BlockSize = s.BlockSize;
        obj.NumPyramidLevels = s.NumPyramidLevels;
        obj.MaxIterations = s.MaxIterations;
        
        % private properties
        obj.IsInitialized = s.IsInitialized;
        obj.IsRGB = s.IsRGB;
        if isfield(s, 'PointClass')
           % Backwards compatibility - saved before R2016a
           s = rmfield(s, 'PointClass');
        end
        if isfield(s, 'PointClassID')
           obj.PointClassID = s.PointClassID;    
        end
        if isfield(s, 'FrameClass')
          % Backwards compatibility - saved before R2016a
          s = rmfield(s, 'FrameClass');
        end
        if isfield(s, 'FrameClassID')
           obj.FrameClassID = s.FrameClassID;
        end

        % internal state
        if s.IsInitialized
          obj.FrameSize = size(s.Frame);        
          obj.NumPoints = size(s.Points,1);
          points = cast(s.Points, 'single');
          if isSimMode()
            obj.pTracker.initialize(getKLTParams(obj), s.Frame, points);
            
          else
            vision.internal.buildable.pointTrackerBuildable.pointTracker_initialize( ...
                obj.pTracker, getKLTParams(obj), s.Frame, points);
          end
          obj.IsInitialized = true;
          setPoints(obj, points, s.Validity);
          
        end
    end
    
    %----------------------------------------------------------------------
    function releaseImpl(obj)        

        if isSimMode()
            % after release the object must be re-initialized
            obj.IsInitialized = false;
        else            
            vision.internal.buildable.pointTrackerBuildable.pointTracker_deleteObj( ...
                obj.pTracker);
        end
    end
  end    
  
  methods
    function initialize(obj, points, I)
      % initialize Sets the points to track and the initial video frame
      %   initialize(H, POINTS, I) sets the points to track in an image I.
      %   POINTS must be an N-by-2 array of [x y] coordinates, and I must 
      %   be a grayscale or RGB image representing the first video frame.
      coder.internal.errorIf(nargin<3, ...
         'vision:PointTracker:invalidInputsToInitialize');
      
      if isSimMode()
        coder.internal.errorIf(isLocked(obj), ...
          'vision:PointTracker:initializeWhenLocked');
      %else
        % in codegen, the isLocked method cannot be called after calling
        % the release method.
      end
     
      obj.validatePoints(points);
      obj.validateImage(I);
      
      % Calling setup is nessary in codegen to prevent the possibility of
      % the step() method taking an image that has a different size or
      % datatype from the one passed into the initialize() method.
      if ~isSimMode()
        setup(obj, I);
      end
      
      obj.PointClassID = coder.internal.const(getClassID(points));
      
      % conversion from 1-based to 0-based is done in
      % vision.internal.PointTracker
      points = single(points);
      
      obj.FrameClassID = getClassID(I);

      Iu8 = im2uint8(I);
      
      if size(Iu8, 3) > 1
          obj.IsRGB = true;          
          Iu8_gray = rgb2gray(Iu8);
      else
          Iu8_gray = Iu8; 
      end
      
      obj.FrameSize = size(Iu8_gray);
      obj.NumPoints = size(points,1);
      
      
      if isSimMode()
        obj.pTracker.initialize(getKLTParams(obj), Iu8_gray, points);
      else
        vision.internal.buildable.pointTrackerBuildable.pointTracker_initialize( ...
            obj.pTracker, getKLTParams(obj), Iu8_gray, points);
      end      
      obj.IsInitialized = true;
    end

    %----------------------------------------------------------------------
    function setPoints(obj, points, pointValididty)
      % setPoints Sets the points to track.
      %   setPoints(H, POINTS, PointValididty) sets the points to be 
      %   tracked. POINTS must be an N-by-2 array of [x y] coordinates. 
      %   PointValididty must be an N-element logical vector, in which the 
      %   value of true indicates that the corresponding point is currently 
      %   visible and should be tracked. This method can be used to 
      %   re-initialize the points when too many points are lost during 
      %   tracking. It can also be used to modify the locations of 
      %   previously tracked points, or to mark certain points as invalid. 
    
      coder.internal.errorIf(~obj.IsInitialized, ...
        'vision:PointTracker:trackerUninitialized');
      coder.assertDefined(obj.IsInitialized);
      coder.assertDefined(obj.PointClassID);
      
      obj.validatePoints(points);  
      if isSimMode()
        coder.internal.errorIf(isLocked(obj) && ...
            (obj.PointClassID ~= getClassID(points)),...
            'vision:PointTracker:pointsClassChangedWhenLocked');
      %else
        % in codegen, the isLocked method cannot be called after calling
        % the release method.
      end
      
      % conversion from 1-based to 0-based is done in
      % vision.internal.PointTracker
      points = single(points);
      
      if nargin > 2
        % check  pointValidity
        validateattributes(pointValididty, {'logical', 'numeric'}, ...
        {'vector', 'nonsparse', 'nonnegative', 'integer'}, ...
         'PointTracker', 'PointValididty');
      
        % make sure the number of elements in pointValidity is the same
        % as the number of points
        coder.internal.errorIf(size(points, 1) ~= length(pointValididty),...
            'vision:PointTracker:pointsPointValiditySizeMismatch');
        pointValidity = logical(pointValididty);        
      else
        pointValidity = true(size(points, 1), 1);
      end
      if isSimMode()
        obj.pTracker.setPoints(points, pointValidity);
      else
        obj.NumPoints = size(points, 1); 
        vision.internal.buildable.pointTrackerBuildable.pointTracker_setPoints( ...
            obj.pTracker, points, pointValidity);
      end
    end
  end

  methods(Access=protected)
    %----------------------------------------------------------------------      
    % Normalizes the error values returned by OpenCV to be a score
    % with the value between 0 and 1, where 1 means perfect match.
    function scores = normalizeScores(obj, scores, validity)
      maxError = sqrt(prod(obj.BlockSize) * 255^2);
      scores = 1 - scores ./ maxError;
      scores(~validity) = 0;
    end
   
    %----------------------------------------------------------------------
    % returns a struct containing parameters for the initialization
    % of pTracker
    function kltParams = getKLTParams(obj)
      kltParams = struct(...
        'BlockSize', double(obj.BlockSize),...
        'NumPyramidLevels', getNumPyramidLevels(obj), ...
        'MaxIterations', double(obj.MaxIterations), ...
        'Epsilon', 0.01, ...
        'MaxBidirectionalError', double(obj.MaxBidirectionalError));
      
      if isinf(kltParams.MaxBidirectionalError)
         kltParams.MaxBidirectionalError = -1;
      end
    end
    
    %----------------------------------------------------------------------
    % clips numPyramidLevels
    function level = getNumPyramidLevels(obj)
      % Set NumPyramidLevels so that the top level of the pyramid
      % has the size of at least 3x3, which is the minimum permissible
      % size for the KLT algorithm.
      topOfPyramid = floor(log2(min(obj.FrameSize)) - 2);
      level = max(0, min(topOfPyramid, double(obj.NumPyramidLevels)));
    end
    
    %----------------------------------------------------------------------
    % returns logical index of points that fall outside the video frame
    function inds = pointsOutsideImage(obj, points)
      x = points(:, 1);
      y = points(:, 2);
      inds = (x < 1) | (y < 1) | ...
          (x > obj.FrameSize(2)) | (y > obj.FrameSize(1));
    end
  end
   
  methods (Static, Access=protected)    
    %----------------------------------------------------------------------
    function [] = validateImage(I)
      validateattributes(I, {'uint8', 'uint16', 'int16', 'single', 'double'}, ...
        {'real', 'nonempty', 'nonsparse'}, 'PointTracker', 'I');

      coder.internal.errorIf(~(ismatrix(I) || ...
          (ndims(I) == 3 && size(I, 3) == 3)), ...
          'vision:dims:imageNot2DorRGB');
    end      

    %----------------------------------------------------------------------    
    function validatePoints(points)
      validateattributes(points, {'single', 'double'}, ...
        {'real', 'nonsparse', 'positive', 'finite', '2d', 'ncols', 2,...
         'nonempty'}, 'PointTracker', 'POINTS');
    end   
  end
end

%==========================================================================
function flag = isSimMode()
    flag = isempty(coder.target);
end

%==========================================================================
function id = getClassID(img)
    id = 5;
    if isa(img,'double')
        id = 0;
    elseif isa(img,'single')
        id = 1;
    elseif isa(img,'uint8')
        id = 2;
    elseif isa(img,'uint16')
        id = 3;
    elseif isa(img,'int16')
        id = 4;
    end
    id = coder.internal.const(id);
end

%==========================================================================
function pointsOut = castFromID(pointsIn, pointClassID)

    switch (pointClassID)
        case coder.internal.const(0)
            pointsOut = double(pointsIn);
        case coder.internal.const(1)
            pointsOut = single(pointsIn);
        case coder.internal.const(2)
            pointsOut = uint8(pointsIn);
        case coder.internal.const(3)
            pointsOut = uint16(pointsIn);
        case coder.internal.const(4)
            pointsOut = int16(pointsIn);            
        otherwise
            pointsOut = double(pointsIn);               
    end
end
%==========================================================================
function class = getClassFromID(id)
    class = 'unknown';
    switch id
        case 0
           class = 'double';
        case 1
           class = 'single';
        case 2
           class = 'uint8';
        case 3
           class = 'uint16';    
        case 4
           class = 'int16';        
    end
end
