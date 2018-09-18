function ax = showReprojectionErrors(cameraParams, varargin)
% showReprojectionErrors Visualize calibration errors.
%   showReprojectionErrors(cameraParams) displays a bar graph that 
%   represents the calibration accuracy for a single camera, a stereo pair
%   or a fisheye camera. The bar graph displays the mean reprojection error
%   per image. cameraParams is either a cameraParameters object, or a
%   stereoParameters object returned from the estimateCameraParameters
%   function, or a fisheyeParameters object returned from the
%   estimateFisheyeParameters function.
%
%   showReprojectionErrors(cameraParams, view) displays the
%   errors using the visualization style specified by the view
%   input.
%   Valid values of view:
%   'BarGraph':    Displays mean error per image as a bar graph.
%
%   'ScatterPlot': Displays the error for each point as a scatter plot.
%                  This option is available only for a single camera.
%
%                  Default: 'BarGraph'
%
%   ax = showReprojectionErrors(...) returns the plot's axes handle.
%
%   showReprojectionErrors(...,Name,Value) specifies additional
%   name-value pair arguments described below:
%
%   'HighlightIndex' Indices of selected images, specified as a
%   vector of integers. For the 'BarGraph' view, bars corresponding
%   to the selected images are highlighted. For 'ScatterPlot' view,
%   points corresponding to the selected images are displayed with
%   circle markers.
%
%   Default: []
%
%   'Parent'         Axes for displaying plot.
%
%   Class Support
%   -------------
%   cameraParameters must be a cameraParameters object, a stereoParameters
%   object or a fisheyeParameters object.
%
%   Example 1 - Single camera
%   -------------------------
%   % Create a set of calibration images.
%   images = imageDatastore(fullfile(toolboxdir('vision'), 'visiondata', ...
%     'calibration', 'webcam'));
%   imageFileNames = images.Files(1:5);
%
%   % Detect calibration pattern.
%   [imagePoints, boardSize] = detectCheckerboardPoints(imageFileNames);
%
%   % Generate world coordinates of the corners of the squares.
%   squareSize = 25; % millimeters
%   worldPoints = generateCheckerboardPoints(boardSize, squareSize);
%
%   % Calibrate the camera.
%   I = readimage(images,1); 
%   imageSize = [size(I, 1), size(I, 2)];
%   params = estimateCameraParameters(imagePoints, worldPoints, ...
%                                     'ImageSize', imageSize);
%
%   % Visualize the errors as a bar graph.
%   subplot(1, 2, 1);
%   showReprojectionErrors(params);
%
%   % Visualize the errors as a scatter plot.
%   subplot(1, 2, 2);
%   showReprojectionErrors(params, 'ScatterPlot');
%
%
%   Example 2 - Stereo camera
%   -------------------------
%   % Specify calibration images
%   imageDir = fullfile(toolboxdir('vision'), 'visiondata', ...
%       'calibration', 'stereo');
%   leftImages = imageDatastore(fullfile(imageDir, 'left'));
%   rightImages = imageDatastore(fullfile(imageDir, 'right'));
%
%   % Detect the checkerboards.
%   [imagePoints, boardSize] = detectCheckerboardPoints(...
%        leftImages.Files, rightImages.Files);
%
%   % Specify world coordinates of checkerboard keypoints.
%   squareSize = 108; % millimeters
%   worldPoints = generateCheckerboardPoints(boardSize, squareSize);
%
%   % Calibrate the stereo camera system. Here both cameras have the same
%   % resolution.
%   I = readimage(leftImages,1); 
%   imageSize = [size(I, 1), size(I, 2)];
%   params = estimateCameraParameters(imagePoints, worldPoints, ...
%                                     'ImageSize', imageSize);
%
%   % Visualize calibration accuracy.
%   showReprojectionErrors(params);
%
%   See also showExtrinsics, estimateCameraParameters, cameraCalibrator, 
%     stereoCameraCalibrator, cameraParameters, stereoParameters,
%     fisheyeParameters

%   Copyright 2014-2017 The MathWorks, Inc.

[view, hAxes, highlightIndex] = parseInputs(cameraParams, varargin{:});


h = showReprojectionErrorsImpl(cameraParams, view, hAxes, highlightIndex);

if nargout > 0
    ax = h;
end
end

%--------------------------------------------------------------------------
function [view, hAxes, highlightIndex] = ...
    parseInputs(cameraParams, varargin)

validateattributes(cameraParams, {'cameraParameters', ...
    'stereoParameters', 'fisheyeParameters'}, {}, mfilename, 'cameraParams');

parser = inputParser;
parser.addOptional('View', 'BarGraph', @checkView);
parser.addParameter('HighlightIndex', [], @checkPatternIndex);
parser.addParameter('Parent', [], ...
    @vision.internal.inputValidation.validateAxesHandle);
parser.parse(varargin{:})

view = parser.Results.View;
hAxes = parser.Results.Parent;

% turn highlightIndex into a logical vector
highlightIndex = false(1,cameraParams.NumPatterns);
highlightIndex(unique(parser.Results.HighlightIndex)) = true;

    %----------------------------------------------------------------------
    function tf = checkView(view)
        validatestring(view, {'barGraph', 'scatterPlot'}, ...
            'showReprojectionErrors', 'View');
        tf = true;
        if isa(cameraParams, 'stereoParameters') && ...
                strcmpi(view, 'scatterPlot')
            error(message('vision:calibrate:noStereoScatterPlot'));
        end
    end

    %----------------------------------------------------------------------
    % share this function between showReprojectionErrors and
    % showExtrinsics
    function r = checkPatternIndex(in)
        r = true;
        if isempty(in) % empty is allowed
            return;
        end
        
        validateattributes(in, {'numeric'},...
            {'integer','vector', 'positive', '<=', cameraParams.NumPatterns}, ...
            'showReprojectionErrors', 'HighlightIndex');
    end
end
