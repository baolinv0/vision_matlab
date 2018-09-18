function stereoCameraCalibrator(varargin)
% stereoCameraCalibrator Stereo camera calibration app.
%
%   stereoCameraCalibrator invokes a stereo calibration app. The app
%   can be used to estimate the intrinsic and extrinsic parameters,
%   of each camera in the stereo pair, and to estimate the translation
%   and rotation between the two cameras.
%
%   stereoCameraCalibrator(folder1, folder2, squareSize) invokes the app and
%   immediately loads stereo calibration images. folder1 is the path to the
%   folder containing images from camera 1, specified as a string.
%   folder2 is the path to the folder containing images from camera 2,
%   specified as a string. squareSize is a scalar specifying the size of
%   the checkerboard square in calibration pattern in millimeters.
%
%   stereoCameraCalibrator(folder1, folder2, squareSize, squareSizeUnits) 
%   additionally specifies the units of the square size as a string. The 
%   valid units are 'millimeters' (default), 'centimeters', and 'inches'.
%
%   stereoCameraCalibrator(sessionFile) invokes the app and immediately loads a
%   saved stereo calibration session. sessionFile is the path to the MAT file
%   containing the saved session.
%
%   See also detectCheckerboardPoints, estimateCameraParameters,
%     showExtrinsics, showReprojectionErrors, undistortImage, 
%     rectifyStereoImages, stereoParameters, cameraParameters,
%     cameraCalibrator

%   Copyright 2014 The MathWorks, Inc.

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
    narginchk(3, 4);
    [fileNames, squareSize, units] = parseInputs(varargin{:});
    shouldAddImages = true;
end

% Create a new Stereo Calibrator
isStereo = true;
tool = CameraCalibrationTool(isStereo);
tool.show();

if shouldAddImages
    addImagesToNewSession(tool, fileNames, squareSize, units);
elseif shouldOpenSession
    processOpenSession(tool, sessionPath, sessionFileName);
end

%--------------------------------------------------------------------------
function [fileNames, squareSize, units] = parseInputs(varargin)
import vision.internal.calibration.tool.*;
folder1 = varargin{1};
folder2 = varargin{2};

validateattributes(folder1, {'char'}, {'vector'}, mfilename, 'folder1');
validateattributes(folder2, {'char'}, {'vector'}, mfilename, 'folder2');
errorMsg = checkStereoFolders(folder1, folder2);

if ~isempty(errorMsg)
    error(errorMsg);
end

folder1 = vision.internal.getFullPath(folder1);
folder2 = vision.internal.getFullPath(folder2);

squareSize = varargin{3};
vision.internal.calibration.checkSquareSize(squareSize, mfilename);

if nargin < 4
    units = 'mm';
else
    units = checkSquareSizeUnits(varargin{4});
end

fileNames1 = vision.internal.getAllImageFilesFromFolder(folder1);
fileNames2 = vision.internal.getAllImageFilesFromFolder(folder2);

errorMsg = checkStereoFileNames(fileNames1, fileNames2, folder1, folder2);
if ~isempty(errorMsg)
    error(errorMsg);
end

fileNames = [fileNames1; fileNames2];

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
