classdef HistogramBasedTracker < matlab.System
%HistogramBasedTracker Track object in video based on histogram
% 
%   H = vision.HistogramBasedTracker returns a System object, H, that
%   tracks an object by using the Continuously Adaptive Mean Shift
%   (CAMShift) algorithm. It uses the histogram of pixel values to identify
%   the tracked object. To initialize the tracking process, you must use
%   the initializeObject method to specify an exemplar image of the object.
%   Then, use the step method to track the object in consecutive video
%   frames.
% 
%   H = vision.HistogramBasedTracker('PropertyName', PropertyValue, ...)
%   returns a tracker System object, H, with each specified property set to
%   the specified value.
% 
%   initializeObject method syntax:
% 
%   initializeObject(H, I, R) sets the object to track by extracting it
%   from the [x y width height] region R, in an M-by-N image I. I can be
%   any 2-D feature map that distinguishes the object from the background.
%   For example, I can be a hue channel of the HSV color space. R also
%   represents the initial search window for the next call to the step
%   method. Typically, I is the first frame of a video in which the object
%   appears. For best results, the object must occupy the majority of R.
% 
%   initializeObject(H, I, R, N) additionally, lets you specify N, the
%   number of histogram bins. By default, N is set to 16. Increasing N
%   enhances the ability of the tracker to discriminate the object.
%   However, it also narrows the range of changes to the object's visual
%   characteristics that the tracker can accommodate, making it more
%   susceptible to losing track.
%
%   step method syntax:
% 
%   BBOX = step(H, I) returns the [x y width height] bounding box, BBOX, of
%   the tracked object. Before calling the step method, use the
%   initializeObject method to identify the object to track, and to set the
%   initial search window.
% 
%   [BBOX, ORIENTATION] = step(H, I) additionally returns the angle between
%   the x-axis and the major axis of the ellipse, which has the same second
%   order moments as the object. The returned angle ranges from -pi/2 to
%   pi/2.
% 
%   [BBOX, ORIENTATION, SCORE] = step(H, I) additionally returns the
%   confidence score indicating whether the returned bounding box, BBOX,
%   contains the tracked object. SCORE is between 0 and 1, with the
%   greatest confidence equal to 1.
% 
%   initializeSearchWindow method syntax:
% 
%   initializeSearchWindow(H, R) sets the initial search  window, R,
%   specified as [x y width height]. The next call to the step method will
%   use R as the initial window to search for the object. This method is
%   useful when you lose track of the object. You can use it to
%   re-initialize object's initial location and size.
% 
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   HistogramBasedTracker methods:
% 
%   step                   - See above description for use of this method
%   initializeObject       - See above description for use of this method
%   initializeSearchWindow - See above description for use of this method
%   release                - Allow property value and input characteristics changes
%   clone                  - Create a tracker object with the same property values
%   isLocked               - Locked status (logical)
% 
%   HistogramBasedTracker properties:
% 
%   ObjectHistogram - Normalized pixel value histogram
% 
%   Notes:
% 
%   - The HistogramBasedTracker is most suitable for tracking a single
%     object. 
%   - You can improve the computational speed of the HistogramBasedTracker
%     by setting the class of the image, I, to uint8.
% 
%   Example: Tracking a face
% 
%   % Create System objects for reading and displaying video, and for
%   % drawing bounding box of the object.
%   videoFileReader = vision.VideoFileReader('vipcolorsegmentation.avi');
%   videoPlayer = vision.VideoPlayer();
% 
%   % Read the first video frame which contains the object and then show
%   % the object region
%   objectFrame = step(videoFileReader);  % read the first video frame
%   objectHSV = rgb2hsv(objectFrame); % convert to HSV color space
%   objectRegion = [40, 45, 25, 25];  % define the object region
%   objectImage = insertShape(objectFrame, 'Rectangle', objectRegion, ...
%                            'Color', [1 0 0]);
%   figure; imshow(objectImage); title('Red box shows object region');
%   % You can also use the following commands to select the object region
%   % using a mouse. The object must occupy majority of the region.
%   % figure; imshow(objectFrame); objectRegion=round(getPosition(imrect))
% 
%   % Set the object based on the hue channel of the first video frame
%   tracker = vision.HistogramBasedTracker;
%   initializeObject(tracker, objectHSV(:,:,1) , objectRegion);
% 
%   % Track and display the object in each video frame
%   while ~isDone(videoFileReader)
%     frame = step(videoFileReader);          % Read next image frame
%     hsv = rgb2hsv(frame);                   % Convert to HSV color space
%     bbox = step(tracker, hsv(:,:,1));       % Track object in hue channel
%                                             % where it's distinct from
%                                             % the background
%     out = insertShape(frame, 'Rectangle', ...
%                   bbox, 'Color', 'red');  % Draw a box around the object
%     step(videoPlayer, out);                 % Show results
%   end
% 
%   release(videoPlayer);
%   release(videoFileReader);

%   Copyright 2011-2016 The MathWorks, Inc.
% 
%   References:
% 
%   G.R. Bradski "Computer Vision Face Tracking for Use in a Perceptual
%   User Interface," Intel, 1998.
%
%   See also insertShape, imrect, rgb2hsv.

%#codegen
%#ok<*EMCLS>
%#ok<*EMCA>

  properties
    %ObjectHistogram Normalized pixel value histogram
    %   Set this property to an N-element vector which is the normalized
    %   histogram of the object's pixel values. Histogram values must be
    %   normalized to between 0 and 1. You can use the initializeObject
    %   method to set this property. This property is tunable.
    %
    %   Default: []
    ObjectHistogram = single([]);
  end
  
  properties (Hidden, Access=private)
    %InitialWindow Initial window for searching the object
    %   Specifies the object's initial location and size prior to refining
    %   them through an iterative search. Format of InitialWindow is [x y
    %   width height], where x and y specify the location of the upper-left
    %   corner of the bounding box.
    % 
    %   This property is initialized by the initializeObject or
    %   initializeSearchWindow method. The algorithm updates this property
    %   every time it processes an image.
    InitialWindow = [];
  end
  
  properties (Nontunable, Access=private)
    %ExpansionRatio Percentage that the object's size may increase between frames
    %   Specifies the percentage that the object's size may increase between
    %   frames. The percentage is defined as the ratio of the change of size
    %   relative to its original size. For example, value of 5 means that
    %   the object may increase its size by 0.05 * max(width, height) in
    %   each dimension in the next video frame.
    %
    %   A small value is preferred if the object has consistent size, while
    %   a large value can be used if the object changes size rapidly. If
    %   this parameter is too small, the returned bounding box will not be
    %   able to cover the whole object when the object expands quickly; on
    %   the other hand, if this parameter is too large, the returned
    %   bounding box may include too much non-object area.
    % 
    %   The actual change of the object's size is affected by, but can be
    %   greater than this property.
    ExpansionRatio = 5;
    %MaximumIterations Maximum number of iterations
    %   Specifies the maximum number of iterations for searching the object
    %   in the image. The actual number of iterations may be less than this
    %   property, if the change of the object's center location is less
    %   than the 'MaximumStepSize' property.
    MaximumIterations = 20;
    %MaximumStepSize Minimum change of the object's center location
    %   Specifies the minimum change of the object's center location for
    %   searching the object in an image. The System object may stop
    %   searching for more accurate location of the object even when the
    %   change of center location is greater than this property, if the
    %   number of iteration is equal to the 'MaximumIterations' property.
    MaximumStepSize = 0.5;
  end

  methods
    function obj = HistogramBasedTracker(varargin)
      setProperties(obj, nargin, varargin{:});
    end
  end
  
  methods(Access=protected)
    function [bbox, orientation, score] = stepImpl(obj, I)
      coder.internal.errorIf(isempty(obj.ObjectHistogram), ...
        'vision:histogramBasedTracker:objectNotSet');
      
      % Determine initial window for search the object
      [h, w] = size(I);
      initialWindow = obj.clipROI([w,h], obj.InitialWindow);
      
      if all(initialWindow(3:4) > 0)
        % Compute location and size of the object
        P = obj.backProject(I, obj.ObjectHistogram);
        window = meanShift(obj, P, initialWindow);
        [bbox, orientation] = computeBoundingBox(obj, P, window);

        % Compute confidence score
        bboxArea = bbox(3) * bbox(4);
        if bboxArea > 0
          score = double(sum(sum(obj.cropImage(P, bbox), 1), 2) / bboxArea);
        else
          score = 0;
        end
      else  % The initial window is empty
        bbox = [initialWindow(1:2), 0, 0];
        obj.InitialWindow = bbox;
        orientation = 0;
        score = 0;
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
        s.ObjectHistogram = obj.ObjectHistogram;
        s.InitialWindow = obj.InitialWindow;
    end
    
    %----------------------------------------------------------------------
    function loadObjectImpl(obj,s, ~)
        if ~isempty(s.ObjectHistogram)
          obj.ObjectHistogram = s.ObjectHistogram;
        end
        
        if ~isempty(s.InitialWindow)
          obj.InitialWindow = s.InitialWindow;
        end
    end
  end
  
  methods
    function initializeObject(obj, I, roi, varargin)
      % initializeObject Sets the object to track
      %   initializeObject(H, I, R) sets the object to track by extracting
      %   it from the [x y width height] region R, in an M-by-N image I. I
      %   can be any 2-D feature map that distinguishes the object from the
      %   background. For example, I can be a hue channel of the HSV color
      %   space. R also represents the initial search window for the next
      %   call to the step method. Typically, I is the first frame of a
      %   video in which the object appears. For best results, the object
      %   must occupy the majority of R.
      % 
      %   initializeObject(H, I, R, N) additionally, lets you specify the
      %   number of histogram bins N. By default, N is set to 16. N must be
      %   chosen according to the image data. A larger N does not always
      %   produce better result.
      coder.internal.errorIf(nargin<3 || nargin>4, ...
        'vision:histogramBasedTracker:invalidInputsToSetObject');
    
      obj.validateImage(I);
      
      validateattributes(roi, {'numeric'}, ...
        {'real', 'nonsparse', 'integer', 'positive', 'finite', ...
        'size', [1, 4]}, 'HistogramBasedTracker', 'R');
      
      [h, w] = size(I);
      roi = obj.clipROI([w, h], double(roi));
      coder.internal.errorIf(any(roi(3:4) <= 0), ...
        'vision:histogramBasedTracker:invalidObjectRegion');

      if nargin < 4
        N = 16;
      else
        N = varargin{1};
        validateattributes(N, {'numeric'}, ...
          {'real', 'scalar', 'finite', 'positive', 'integer'},...
          'HistogramBasedTracker', 'N');
      end

      Isub = obj.cropImage(I, roi);
      objectHistogram = obj.hist2D(Isub, N);
      obj.ObjectHistogram = objectHistogram / max(objectHistogram);
      initializeSearchWindow(obj, roi);
    end

    %----------------------------------------------------------------------
    function initializeSearchWindow(obj, value)
      % initializeSearchWindow Sets the initial search window
      %   initializeSearchWindow(H, R) sets the initial search  window, R,
      %   specified as [x y width height]. The next call to the step method
      %   will use R as the initial window to search for the object. This
      %   method is useful when you lose track of the object. You can use
      %   it to re-initialize object's initial location and size.
      obj.InitialWindow = value;
    end
  end
  
  methods
    function set.ObjectHistogram(obj, value)
      validateattributes(value, {'numeric'}, ...
        {'vector', 'real', 'nonsparse', 'nonnegative', '<=', 1}, ...
        'HistogramBasedTracker', 'ObjectHistogram');
      
      obj.ObjectHistogram = single(value);
    end
    
    %----------------------------------------------------------------------
    function set.InitialWindow(obj, value) %#ok<*MCSGA>
      validateattributes(value, {'numeric'}, ...
        {'real', 'nonsparse', 'integer', 'finite', 'nonnegative', ...
        'size', [1, 4]}, 'HistogramBasedTracker', 'InitialWindow');

      obj.InitialWindow = double(value);
    end
  end

  methods (Static, Access=protected)
    function out = cropImage(in, roi)
      out = in(roi(2):roi(2)+roi(4)-1, roi(1):roi(1)+roi(3)-1, :);
    end
    
    %----------------------------------------------------------------------
    function out = clipROI(imageSize, in)
      upperLeft = in(1:2);
      bottomRight = in(1:2) + in(3:4) - 1;
      
      if all(upperLeft <= imageSize) && all(bottomRight >= [1,1])
        upperLeft = max(upperLeft, [1, 1]);
        bottomRight = min(bottomRight, imageSize);
        out = [upperLeft, bottomRight-upperLeft+1];
      else % The object is completely outside the image
        if all(upperLeft <= imageSize)
          out = [1, 1, 0, 0];
        else
          out = [imageSize, 0, 0];
        end
      end
    end
    
    %----------------------------------------------------------------------
    function h = hist2D(I, N)
      if isfloat(I)
        binWidth = 1 / N;
        edge = 0: binWidth: 1;
        edge(1) = -inf;
        edge(end) = inf;
      else
        edge = 0 : 255/N : 256;
      end
      h = single(histc(I(:), edge, 1));
      h(end-1) = h(end-1) + h(end);
      h = h(1:end-1);
    end
    
    %----------------------------------------------------------------------
    function P = backProject(I, h)
      N = length(h);
      switch class(I)
        case 'uint8'
          scale = N / 256;
          bin = floor(double(I) * scale) + 1;
        case {'double', 'single'}
          bin = floor(I * N) + 1;
          bin = max(bin, 1);
          bin = min(bin, N);
        otherwise
          classToUse = class(I);
          scale = N ...
            / (double(intmax(classToUse)) - double(intmin(classToUse)) + 1);
          bin = floor((double(I) - double(intmin(classToUse))) * scale) + 1;
      end
      if size(bin, 1) == 1
        ht = h'; % Transpose the histogram in order to keep the shape
                 % of image after matrix indexing.
        P = ht(bin);
      else
        P = h(bin);
      end
    end
    
    %----------------------------------------------------------------------
    function m = moment2D(P, mode)
      switch(mode)
        case 'm'
          m = sum(sum(P, 1), 2);
        case 'mx'
          ms = sum(P, 1);
          m = sum(ms .* (1: length(ms)));
        case 'my'
          ms = sum(P, 2);
          m = sum(ms .* (1: length(ms))');
        case 'mxy'
          m = sum(sum(P .* ((1:size(P,1))' * (1:size(P,2))), 1), 2);
        case 'mxx'
          ms = sum(P, 1);
          m = sum(ms .* ((1: length(ms)).^2));
        case 'myy'
          ms = sum(P, 2);
          m = sum(ms .* ((1: length(ms)).^2)');
      end
      m = double(m);
    end
    
    %----------------------------------------------------------------------
    function validateImage(I)
      validateattributes(I, ...
        {'uint8', 'single', 'double'}, ...
        {'real', 'nonempty', 'nonsparse', '2d'},...
        'HistogramBasedTracker', 'I');
    end
  end
  
  methods(Access=protected)
    function bbox = meanShift(obj, P, roi)
      idx = 0;
      dis = obj.MaximumStepSize;
      [h, w] = size(P);
      r = double(roi);
      while idx < obj.MaximumIterations && dis >= obj.MaximumStepSize
        Psub = obj.cropImage(P, r);
        m = obj.moment2D(Psub, 'm');
        my = obj.moment2D(Psub, 'my');
        mx = obj.moment2D(Psub, 'mx');
        if m == 0
          % All pixels in roi are zeros
          dis = 0;
          r(3:4) = [0,0];
        else
          % Shift bounding box to mass center
          halfSize = (r(3:4) - 1) / 2;
          oldCent = r(1:2) + halfSize;
          newCent = r(1:2) - 1 + [mx, my] / m;
          dis = norm(newCent - oldCent);
          r(1:2) = round(newCent - halfSize);
          r = obj.clipROI([w, h], r);
        end
        idx = idx + 1;
      end
      bbox = r;
    end
    
    %----------------------------------------------------------------------
    function [cent, orientation, majorAxis, minorAxis]...
        = fitEllipse(obj, P, roi)
      
      % Compute the moments of the probability map in the extended ROI.
      Psub = obj.cropImage(P, roi);
      m = obj.moment2D(Psub, 'm') + eps;
      my = obj.moment2D(Psub, 'my');
      mx = obj.moment2D(Psub, 'mx');
      mxy = obj.moment2D(Psub, 'mxy');
      myy = obj.moment2D(Psub, 'myy');
      mxx = obj.moment2D(Psub, 'mxx');
      uyy = myy / m - (my / m)^2;
      uxx = mxx / m - (mx / m)^2;
      % The angle of the major axis is measured in the counter-clockwise
      % direction, so uxy is computed in the following method.
      uxy = -mxy / m + my * mx / m^2;

      % Calculate major axis length, minor axis length, and eccentricity.
      common = sqrt((uxx - uyy)^2 + 4*uxy^2);
      majorAxis = 2 * sqrt(2) * sqrt(uxx + uyy + common);
      minorAxis = 2 * sqrt(2) * sqrt(uxx + uyy - common);

      % Calculate orientation.
      if (uyy > uxx)
          num = uyy - uxx + sqrt((uyy - uxx)^2 + 4*uxy^2);
          den = 2*uxy;
      else
          num = 2*uxy;
          den = uxx - uyy + sqrt((uxx - uyy)^2 + 4*uxy^2);
      end
      if (num == 0) && (den == 0)
          orientation = 0;
      else
          orientation = atan(num/den);
      end
      cent = [mx, my] / m + roi(1:2) - 1;
    end
    
    %----------------------------------------------------------------------
    function [bbox, orientation] = computeBoundingBox(obj, P, roi)
      expansionRatio = obj.ExpansionRatio / 200;
      [h, w] = size(P);
      imageSize = [w, h];
      expandedSize = ceil(max(roi(3:4)) * expansionRatio);
      expandedROI = zeros(1, 4);
      expandedROI(1:2) = max(roi(1:2) - expandedSize * [1, 1], [1, 1]);
      expandedROI(3:4) = min(roi(3:4) + 2 * expandedSize * [1, 1], ...
                         imageSize - expandedROI(1:2) + 1);

      % Estimate size of the bounding box of the object based on the
      % orientation and axis of the ellipse.
      [cent, orientation, majorAxis, minorAxis]...
        = fitEllipse(obj, P, expandedROI);
      sn = abs(sin(orientation));
      cs = abs(cos(orientation));
      newWidth  = max(majorAxis * cs, minorAxis * sn);
      newHeight = max(majorAxis * sn, minorAxis * cs);
      
      % Compute the new bounding box
      halfSize = [newWidth, newHeight] / 2;
      bbox = round([cent - halfSize, newWidth, newHeight]);
      bbox = obj.clipROI([w, h], bbox);
      initializeSearchWindow(obj, bbox);
    end
  end
end
