function imageLabeler(varargin)
%imageLabeler Label ground truth in a collection of images.
%
%  imageLabeler launches the Image Labeler app for interactive image
%  labeling. You can use the app to label:
%
%     * Rectangular Regions of Interest (ROI) for object detection
%     * Pixel labels for semantic segmentation
%     * Scene labels for image classification
%
%  imageLabeler(imageFolder) launch the app and immediately load all images
%  from imageFolder.
%
%  imageLabeler(imgDatastore) launch the app and immediately load all
%  images from an imageDatastore object.
%
%  imageLabeler(sessionFile) launch the app and load a saved session.
%  sessionFile is the path to a MAT file containing the saved session.
%
%  Notes
%  -----
%  - Define and execute custom label automation algorithms with the Image
%    Labeler app by creating an <a href="matlab:help('vision.labeler.AutomationAlgorithm')">AutomationAlgorithm</a> class.
%
%  Example - Open Image Labeler with an image collection.
%  ------------------------------------------------------
%  stopSignsDir = fullfile(toolboxdir('vision'), 'visiondata', 'stopSignImages')
%  imds = imageDatastore(stopSignsDir)
%  imageLabeler(imds)
%
%  See also trainRCNNObjectDetector, trainFastRCNNObjectDetector,
%           trainFasterRCNNObjectDetector, trainACFObjectDetector,
%           trainCascadeObjectDetector, groundTruth,
%           vision.labeler.AutomationAlgorithm.

% Copyright 2017 The MathWorks, Inc.


narginchk(0,1);
shouldAddImages = false;
issueWarning = false;
shouldOpenSession = false;

if nargin == 0
    tool = vision.internal.imageLabeler.tool.ImageLabelerTool();
    tool.show();
    return
    
elseif isa(varargin{1}, 'matlab.io.datastore.ImageDatastore')
    issueWarning = false;
    shouldAddImages = true;
    imds = varargin{1};
    fileNames = imds.Files;
    
else
    
    validateattributes(varargin{1}, {'char'}, {'vector'}, mfilename, 'input name');
    
    if exist(varargin{1}, 'dir')
        % Load images from a folder
        folder = varargin{1};
        folder = vision.internal.getFullPath(folder);
        fileNames = parseFolder(folder);
        if(isempty(fileNames))
            % Folder does not contain any valid images
            issueWarning = true;
        else
            shouldAddImages = true;
        end
        
    elseif exist(varargin{1}, 'file') || exist([varargin{1}, '.mat'], 'file')
        % Load a session
        sessionFileName = varargin{1};
        import vision.internal.calibration.tool.*;
        try
            [sessionPath, sessionFileName] = parseSessionFileName(sessionFileName);
            shouldOpenSession = true;
        catch ME
            throwAsCaller(ME);
        end
    else
        error(message('vision:imageLabeler:InvalidInput',varargin{1}));
    end
end

tool = vision.internal.imageLabeler.tool.ImageLabelerTool();
tool.show();

if shouldAddImages
    tool.doLoadImages(fileNames);
    
elseif issueWarning
    warndlg(...
        getString(message('vision:imageLabeler:NoImagesFoundMessage',folder)),...
        getString(message('vision:uitools:NoImagesAddedTitle')),'modal');
    
elseif shouldOpenSession
    doLoadSession(tool, sessionPath, sessionFileName);
    
end

%------------------------------------------------------------------
function imageFilenames = parseFolder(fileFolder)

% get a list of valid image extensions
formats = imformats();
ext = [formats(:).ext];

% scan the folder for files
contents = dir(fileFolder);
imageFilenames = contents(~[contents(:).isdir]);
imageFilenames = {imageFilenames(:).name};
exp = sprintf('(.*\\.%s$)|',ext{:});

% filter filenames by extension
idx = cellfun(@(x)~isempty(x),regexpi(imageFilenames, exp,'once'));
imageFilenames = fullfile(fileFolder, imageFilenames(idx));
