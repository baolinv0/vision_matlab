function cameraCalibrator(varargin)
%cameraCalibrator Single camera calibration app.
%
%   cameraCalibrator invokes a camera calibration app. The app
%   can be used to estimate camera intrinsic and extrinsic parameters,
%   and to compute parameters needed to remove the effects of lens 
%   distortion from an image.
%
%   cameraCalibrator(imageFolder, squareSize) invokes the app and
%   immediately loads the calibration images from imageFolder. squareSize
%   is a scalar specifying the size of the checkerboard square in the
%   calibration pattern in millimeters.
%
%   cameraCalibrator(imageFolder, squareSize, squareSizeUnits) additionally
%   specifies the unis of the square size as a string. The valid units are
%   'millimeters' (default), 'centimeters', and 'inches'.
%
%   cameraCalibrator(sessionFile) invokes the app and immediately loads a
%   saved camera calibration session. sessionFile is the path to the MAT file
%   containing the saved session.
%
%   See also detectCheckerboardPoints, estimateCameraParameters,
%     showExtrinsics, showReprojectionErrors, undistortImage, 
%     cameraParameters

%   Copyright 2012 The MathWorks, Inc.

import vision.internal.calibration.tool.*;
shouldAddImages = false;
shouldOpenSession = false;

% A single argument means either 'close' or load a session.
if nargin == 1 
    if strcmpi(varargin{1}, 'close')
        % Handle the 'close' request
        CameraCalibrationTool.deleteAllTools();    
        return;
    elseif exist(varargin{1}, 'file') || exist([varargin{1}, '.mat'], 'file')
        % Load a session
        sessionFileName = varargin{1};
        [sessionPath, sessionFileName] = parseSessionFileName(sessionFileName);  
        shouldOpenSession = true;
    end
end

if nargin > 0 && ~shouldOpenSession
    % Adding images from folders
    narginchk(2, 3);
    [fileNames, squareSize, units] = parseInputs(varargin{:});
    shouldAddImages = true;
end

% Create a new Camera Calibrator
tool = vision.internal.calibration.tool.CameraCalibrationTool;
tool.show();

if shouldAddImages
    addImagesToNewSession(tool, fileNames, squareSize, units);
elseif shouldOpenSession
    processOpenSession(tool, sessionPath, sessionFileName);
end

%--------------------------------------------------------------------------
function [fileNames, squareSize, units] = parseInputs(varargin)
import vision.internal.calibration.tool.*;

folder = varargin{1};
validateattributes(folder, {'char'}, {'vector'}, mfilename, 'folder');
if ~exist(folder, 'dir')
    error(message('vision:caltool:stereoFolderDoesNotExist', folder));
end
folder = vision.internal.getFullPath(folder);

squareSize = varargin{2};
vision.internal.calibration.checkSquareSize(squareSize, mfilename);

if nargin < 3
    units = 'mm';
else
    units = checkSquareSizeUnits(varargin{3});
end

fileNames = vision.internal.getAllImageFilesFromFolder(folder);
if isempty(fileNames)
    error(message('vision:caltool:noImagesFound', folder));
end

%--------------------------------------------------------------------------
function squareSizeUnits = checkSquareSizeUnits(squareSizeUnits)
squareSizeUnits = validatestring(squareSizeUnits, {'mm', 'cm', 'in',...
    'millimeters', 'centimeters', 'inches'}, mfilename, 'units');

% In 17a we switched from short unit names to full unit names
% to better support translation of the tool.  Substitute new strings
% upon loading of an old session file.
switch squareSizeUnits
    case {'mm'}
        squareSizeUnits = 'millimeters';
    case {'cm'}
        squareSizeUnits = 'centimeters';
    case {'in'}
        squareSizeUnits = 'inches';
end
