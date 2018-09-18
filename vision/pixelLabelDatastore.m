%pixelLabelDatastore Create a PixelLabelDatastore to work with collections of pixel label data.
%
%   pxds = pixelLabelDatastore(gTruth) creates a PixelLabelDatastore from
%   gTruth, an array of groundTruth objects. The returned datastore, pxds,
%   can be used to read pixel label data using read(pxds). The output of
%   read(pxds) is a categorical matrix C, where C(i,j) represents the
%   categorical label assigned to pixel at location (i,j).
%
%   pxds = pixelLabelDatastore(location, classNames, pixelLabelID) creates
%   a PixelLabelDatastore given the location of image files storing pixel
%   label data as numeric label matrices. The location can be a folder name
%   or a cell array of image filenames. classNames is a set of class names
%   specified as a string vector or cell array of character vectors. The
%   values in pixelLabelID map image pixel label values and to specific
%   class names. pixelLabelID must be one of the following:
%
%      - A vector of numeric IDs. The length of the vector must equal
%        the number of class names.
%
%      - An M-by-3 matrix where M is the number of class names. Each row is
%        a three element vector representing the RGB pixel value to
%        associate with each class name. Use this format when the pixel
%        label data is stored as RGB images.
%
%      - A cell array of column vectors or a cell array of M-by-3 matrices.
%        Use a cell array to map multiple pixel label IDs to one class
%        name.
%
%   pxds = pixelLabelDatastore(..., 'Name', 'Value') specifies additional
%   name-value pair arguments described below:
%
%     'IncludeSubfolders'  A logical that specifies whether the files in
%                          each folder and its subfolders are included
%                          recursively or not. This name-value pair does
%                          not apply when a groundTruth object is used to
%                          create the PixelLabelDatastore.
%
%                          Default: false
%
%     'ReadSize'           Number of image files to read in a call to the
%                          read function, specified as a positive integer
%                          scalar. Each call to the read function reads at
%                          most ReadSize images.
%
%                          ReadSize: 1
%
%   PixelLabelDatastore Properties:
%
%      Files          - A cell array of file names
%      ClassNames     - A cell array of class names
%      ReadSize       - Upper limit on the number of images returned by the
%                       read method
%      ReadFcn        - Function handle used to read files
%
%   PixelLabelDatastore Methods:
%
%      hasdata        - Returns true if there is more data to read.
%      read           - Reads the next consecutive file.
%      reset          - Resets the datastore to the start of the data.
%      preview        - Reads the first image from the datastore.
%      readimage      - Reads a specified image from the datastore.
%      readall        - Reads all pixel label data from the datastore.
%      partition      - Returns a new datastore that represents a single
%                       partitioned portion of the original datastore.
%      numpartitions  - Returns an estimate for a reasonable number of
%                       partitions to use with the partition function,
%                       according to the total data size.
%      countEachLabel - Counts the number of pixel labels for each class.
%
% Notes
% -----
% - Pixel label IDs must be between 0 and 255.
%
% Example - Read and display pixel label data.
% --------------------------------------------
% % Location of image and pixel label data
% dataDir = fullfile(toolboxdir('vision'), 'visiondata');
% imDir = fullfile(dataDir, 'building');
% pxDir = fullfile(dataDir, 'buildingPixelLabels');
%
% % Create image datastore
% imds = imageDatastore(imDir);
%
% % Create pixel label datastore.
% classNames = ["sky" "grass" "building" "sidewalk"];
% pixelLabelID = [1 2 3 4];
% pxds = pixelLabelDatastore(pxDir, classNames, pixelLabelID);
%
% % Read image and pixel label data. read(pxds) returns a categorical
% % matrix, C. C(i,j) is the categorical label assigned to I(i,j).
% I = read(imds);
% C = read(pxds);
%
% % Display the label categories in C
% categories(C)
%
% % Overlay pixel label data on the image and display.
% B = labeloverlay(I, C);
% figure
% imshow(B)
%
% See also pixelLabelImageSource, imageDatastore, semanticseg, 
%          labeloverlay, evaluateSemanticSegmentation, imageLabeler,
%          groundTruth, matlab.io.datastore.PixelLabelDatastore.

% Copyright 2017 The MathWorks, Inc.

function ds = pixelLabelDatastore(varargin)
narginchk(1,7);
if isa(varargin{1}, 'groundTruth')
    narginchk(1,5);
    [gTruth, params] = parseGroundTruthInputs(varargin{:});
    ds = matlab.io.datastore.PixelLabelDatastore.createFromGroundTruth(gTruth, params);
else
    narginchk(3,7);
    [location, classes, values,params] = parseInputs(varargin{:});
    ds = matlab.io.datastore.PixelLabelDatastore.create(location, classes, values, params);
end

%--------------------------------------------------------------------------
function [gTruth, params] = parseGroundTruthInputs(varargin)


p = inputParser();
p.addRequired('gTruth', @checkGroundTruth)
p.addParameter('IncludeSubfolders', false, ...
    @(x)vision.internal.inputValidation.validateLogical(x,'IncludeSubfolders'));
p.addParameter('ReadSize', 1, @checkReadSize);

p.parse(varargin{:});

userInput = p.Results;

includeSubfoldersWasProvided = ~ismember('IncludeSubfolders', p.UsingDefaults);

if includeSubfoldersWasProvided
    % warning(message('vision:pixelLabelDatastore:TODO'));
end

gTruth = userInput.gTruth;
params.ReadSize          = double(userInput.ReadSize);
params.IncludeSubfolders = logical(userInput.IncludeSubfolders);


%--------------------------------------------------------------------------
function [location, classNames, pixelLabelID, params] = parseInputs(varargin)
location = varargin{1};
classNames = varargin{2};
pixelLabelID = varargin{3};

p = inputParser();
p.addRequired('location', @checkLocation);
p.addRequired('classNames', @checkClassNames);
p.addRequired('pixelLabelID', @checkPixelLabelID);
p.addParameter('IncludeSubfolders', false, ...
    @(x)vision.internal.inputValidation.validateLogical(x,'IncludeSubfolders'));
p.addParameter('ReadSize', 1, @checkReadSize);

p.parse(varargin{:});

location   = cellstr(location);
classNames = cellstr(classNames);

% convert user input pixel label ID into cell of double numeric arrays.
if iscell(pixelLabelID)
    pixelLabelID = cellfun(@(x)double(x), pixelLabelID, 'UniformOutput', false);
else
    % convert vector or M-by-3 into to cell of numerics of M-by-3 or cell of column vectors.
    if isvector(pixelLabelID)
        if numel(classNames) == 1 && isrow(pixelLabelID)
            % special case for single class name with scalar or 1-by-3 RGB.
            % leave it as a row.
        else
            pixelLabelID = reshape(pixelLabelID,[],1);
        end
    else
        pixelLabelID = double(pixelLabelID);
    end
    pixelLabelID = num2cell(double(pixelLabelID),2);
end

if numel(classNames) ~= numel(pixelLabelID)
    error(message('vision:semanticseg:invalidNumelClassesLabels'));
end

params.IncludeSubfolders = logical(p.Results.IncludeSubfolders);
params.ReadSize = double(p.Results.ReadSize);

%--------------------------------------------------------------------------
function checkGroundTruth(x)
validateattributes(x, {'groundTruth'}, {'vector', 'nonempty'},...
    mfilename, 'gTruth');

for i = 1:numel(x)
    if hasTimeStamps(x(i).DataSource)
        error(message('vision:semanticseg:gTruthWithTimeStamps'));
    end
    
    defs = x(i).LabelDefinitions;
    if ~any(defs.Type == labelType.PixelLabel)
        error(message('vision:semanticseg:gTruthWithNoPixelLabels'));
    end
end

iAssertAllGroundTruthHaveConsistentLabelNames(x);

%--------------------------------------------------------------------------
function iAssertAllGroundTruthHaveConsistentLabelNames(x)

expectedNames = iPixelLabelNames(x(1).LabelDefinitions);

for i = 2:numel(x)
    if ~isempty(setxor(expectedNames, iPixelLabelNames(x(i).LabelDefinitions)))
        error(message('vision:semanticseg:gTruthNotSameName'));
    end
end

%--------------------------------------------------------------------------
function names = iPixelLabelNames(labeldef)
idx = labeldef.Type == labelType.PixelLabel;
names = labeldef.Name(idx);

%--------------------------------------------------------------------------
function checkReadSize(x)
validateattributes(x, {'numeric'}, ...
    {'scalar', 'nonempty', 'positive', 'real', 'finite'}, ...
    mfilename, 'ReadSize');

%--------------------------------------------------------------------------
function checkLocation(x)
% char or string or cellstr - defer other checks to PixelLabelDatastore
% class.
if iscell(x)
    validateattributes(x, {'cell'}, {'vector', 'nonempty'},...
        mfilename, 'location');
    if ~iscellstr(x)
        error(message('vision:semanticseg:invalidLocationInput'));
    end
else
    validateattributes(x, {'char','string'}, {'row', 'nonempty'}, ...
        mfilename, 'location');
end

%--------------------------------------------------------------------------
function checkClassNames(x)

if iscell(x)
    validateattributes(x, {'cell'}, {'vector', 'nonempty'},...
        mfilename, 'location');
    
    if ~iscellstr(x)
        error(message('vision:semanticseg:invalidClassNamesInput'));
    end
else
    % char or string array
    if ischar(x)
        validateattributes(x, {'string','char'}, ...
            {'row', 'nonempty'}, mfilename, 'classNames');
    else
        validateattributes(x, {'string'}, ...
            {'vector', 'nonempty'}, mfilename, 'classNames');
    end
end
x = string(x);
if numel(unique(x)) ~= numel(x)
    error(message('vision:semanticseg:pxdsNonUniqueClassNames'));
end

%--------------------------------------------------------------------------
function checkPixelLabelID(pxid)
if iscell(pxid)
    cellfun(@(x) checkCellPixelLabelIDVectorOrMatrix(x), pxid);
    
    % Check that all values have the same format.
    areVectors  = cellfun(@(x)iscolumn(x), pxid);
    areMatrices = cellfun(@(x)ismatrix(x) && size(x,2)==3, pxid);
    
    if ~(all(areVectors)  || all(areMatrices))
        error(message('vision:semanticseg:pxidNotAllSameFormat'));
    end
    
    % verify IDs are not shared by multiple classes.
    if all(areVectors)
        % make all vectors columns
        pxid = cellfun(@(x)reshape(x,[],1), pxid, 'UniformOutput', false);
    end
    
    pxid = vertcat(pxid{:});
    
else
    checkPixelLabelIDVectorOrMatrix(pxid);
end

c = unique(pxid, 'rows');
if size(pxid,1) ~= size(c,1)
    error(message('vision:semanticseg:pxidDuplicateIDs'));
end

%--------------------------------------------------------------------------
function checkCellPixelLabelIDVectorOrMatrix(pxid)
if iscolumn(pxid)
    checkVectorPixelLabelID(pxid);
elseif ismatrix(pxid)
    checkMatrixPixelLabelID(pxid);
else
    error(message('vision:semanticseg:pxidNotColVectorOrMatrix'));
end

%--------------------------------------------------------------------------
function checkPixelLabelIDVectorOrMatrix(pxid)
if isvector(pxid)
    checkVectorPixelLabelID(pxid);
elseif ismatrix(pxid)
    checkMatrixPixelLabelID(pxid);
else
    error(message('vision:semanticseg:pxidNotVectorOrMatrix'));
end

%--------------------------------------------------------------------------
function checkVectorPixelLabelID(pxid)
validateattributes(pxid, {'numeric'}, ...
    {'integer', 'nonempty', 'finite', 'real', 'nonsparse', '>=', 0, '<=', 255}, ...
    mfilename, 'pixelLabelID');

%--------------------------------------------------------------------------
function checkMatrixPixelLabelID(pxid)
validateattributes(pxid, {'numeric'}, ...
    {'size', [NaN 3], 'integer', 'nonempty', 'finite', 'real', 'nonsparse', '>=', 0, '<=', 255}, ...
    mfilename, 'pixelLabelID');
