% getAllImageFilesFromFolder Get the names of all image files in a folder
%
%  imageFileNames = getAllImageFilesFromFolder(folder) returns a cell array
%  containing the paths to all image files in the folder.  

% Copyright 2014 The MathWorks, Inc.
function imageFileNames = getAllImageFilesFromFolder(folder)
fileNames = dir(folder);
fileNames = {fileNames(:).name};
imageFileNames = {};
for i = 1:length(fileNames)
    try
        fileName = fullfile(folder, fileNames{i});
        imfinfo(fileName);
        imageFileNames{end+1} = fileName; %#ok
    catch
    end
end
end