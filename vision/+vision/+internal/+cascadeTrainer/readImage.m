function img = readImage(imagename)
%readImage reads and returns an image by calling imread
%
%   img = readImage(imagename) 
%   Returns an image whose name is specified in imageName
%   Performs checks to handle non-regular image formats (like indexed
%   files)
%
%   If imagename has a non-valid image extension, readImage returns an 
%   empty result for img without throwing an error.
%   If the image cannot be read for any other reason, readImage throws
%   an error.

try
    if isImageIndexed(imagename)
        [img, map] = imread(imagename);
        img = ind2rgb(img, map);
    else
        img = imread(imagename);
    end
catch e
    %Check if the imagename has a non-valid image extension
    [~,~,fileext] = fileparts(imagename);
    %List all valid image formats
    imageFormats = imformats;
    found = false;
    %For each valid format, check if ext equals any of the allowed
    %image extensions
    for formatNum=1:size(imageFormats, 2)
        validExtensions = imageFormats(formatNum).ext;
        for extNum=1:size(validExtensions, 2)
            if isequal(lower(fileext), ['.' validExtensions{extNum}])
                found = true;
                break;
            end
        end
        if found
            break;
        end
    end
    %If imagename had one of the valid extensions, then rethrow the error
    if found
        rethrow(e);
    else
        img = [];
    end
end

%------------------------------------------------------------------------
function tf = isImageIndexed(imagename)
disableImfinfoWarnings();
try
    info = imfinfo(imagename);
    enableImfinfoWarnings();
    tf = strcmp(info.ColorType, 'indexed');
catch e
    enableImfinfoWarnings();
    rethrow(e);
end

%------------------------------------------------------------------------
function disableImfinfoWarnings()
imfinfoWarnings('off');

%------------------------------------------------------------------------
function enableImfinfoWarnings()
imfinfoWarnings('on');

%------------------------------------------------------------------------
function imfinfoWarnings(onOff)
warnings = {'MATLAB:imagesci:tifftagsread:badTagValueDivisionByZero',...
            'MATLAB:imagesci:tifftagsread:numDirectoryEntriesIsZero',...
            'MATLAB:imagesci:tifftagsread:tagDataPastEOF'};
for i = 1:length(warnings)
    warning(onOff, warnings{i});
end