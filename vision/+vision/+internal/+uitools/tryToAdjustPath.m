
%--------------------------------------------------------------
% This function will poke around the file system to see if the file or
% directory can be loaded even though they are not at the specified
% locations. This can happen, for example, when moving between operating
% systems.
function newPath = tryToAdjustPath(origPath, currentSessionFilePath,...
    origFullSessionFileName)

if exist(origPath, 'file')
    newPath = origPath;
    return;
end

% strip off the path regardless of the operating system and return a list
% of folders created from the file path.
[fileName, folderList] = getFilename(origPath);

% pick off the first one for use in matlab path search. Full list will be
% used to build serach 
fdir = folderList{1}; 

% see if the file can be found at the same location as the
% session file
newPath = fullfile(currentSessionFilePath,fileName);
ok = exist(newPath,'file');

% try again; this time look at the relative path upwards of
% the session file location
if ~ok
    relativePath = getRelativePath(origPath);
    newPath = fullfile(relativePath,fileName);
    ok = exist(newPath,'file');
end

if ~ok
    % Try to find using relative paths created from original file path. For
    % example, if original file path is c/b/a/file, then folderList is
    % {'a','b','c'}. First try relativePath/a, then relativePath/b/a, then
    % relativePath/c/b/a.
    pathToTry = fullfile(folderList{1});
    for i = 2:numel(folderList)
        
        newPath = fullfile(relativePath, pathToTry, fileName);
        ok = exist(newPath, 'file');
        if ok
            break;
        end
        
        % generate new path to try
        pathToTry = fullfile(folderList{i}, pathToTry);
    end
end

% try again; see if the file can be found on MATLAB path
if ~ok
    newPath = which(fileName);
    ok = ~isempty(newPath);
end

% try again; see if the filename is a directory that can be found on MATLAB
% path
if ~ok
    dirPath = what(fileName);
    ok = ~isempty(dirPath);
    if ok
        % dirPath can have multiple valid paths. Set newPath to one of the
        % valid paths and attempt to find the most probable path.
        newPath = dirPath(1).path;
        for pathIdx = 1:numel(dirPath)
            if ~isempty(strfind(dirPath(pathIdx).path,[fdir filesep fileName]))
                newPath = dirPath(pathIdx).path;
                break;
            end
        end
    end
end

if ~ok 
    error(message('vision:uitools:missingImageFiles'));
end

%--------------------------------------------------------------
% gets file name regardless of the operating system
    function [fname, fdir] = getFilename(path)
        
        unixDelimiters = strfind(path,'/');
        windowsDelimiters = strfind(path,'\');
        
        if ~isempty(unixDelimiters)
            last = unixDelimiters(end);
            
        elseif ~isempty(windowsDelimiters) % windows file path
            last = windowsDelimiters(end);
        else
            % just a file name
            fname = path;
            fdir = {'.'};
            return
        end
        
        fname = path(last+1:end);
        
        % get list of folders in reverse order, starting with the
        % containing folder going all the way up the path. For example, if
        % file is '/a/b/c/d/file.foo', folderList is {'d','c','b','a'}.
        %
        % This list is used to create a set of relative search paths that
        % we use to look for the file.foo. 

        folders = strsplit(string(path(1:last-1)),{'/', '\'});
        folders(folders == "") = []; % remove empties
        fdir = fliplr(cellstr(folders));
        
    end
%--------------------------------------------------------------
    function path = getRelativePath(oldPath)
        path = '';
        
        fname = getFilename(oldPath);
        imageFilePathLength = length(oldPath)-length(fname);
        
        fname = getFilename(origFullSessionFileName);
        atSavingTimeSessionFilePathLength = ...
            length(origFullSessionFileName) - length(fname);
        
        fullImagePath = oldPath;
        imageFilePath = fullImagePath(1:imageFilePathLength);
        
        atSavingTimeSessionFilePath = ...
            origFullSessionFileName(1:atSavingTimeSessionFilePathLength);
        
        % process only up the filesystem tree
        if(imageFilePathLength >= atSavingTimeSessionFilePathLength)
            pattern = atSavingTimeSessionFilePath;
            str = imageFilePath;            
        else
            pattern = imageFilePath;
            str = atSavingTimeSessionFilePath;
        end
        
        idx = imageFilePathLength - strfind(fliplr(str), fliplr(pattern)) + 2;
        path = str(idx:end);
        
        % adjust delimeters so that the path is valid across
        % different platforms
        path = getPathForCurrentPlatform();
        
        path = [currentSessionFilePath, path];
        
        %----------------------------------------------------------
        function pathOut = getPathForCurrentPlatform
            pathOut = path;
            
            if isempty(strfind(path,filesep))
                if filesep == '/'
                    storedFileSeparator = '\';
                else
                    storedFileSeparator = '/';
                end
                idx = strfind(path,storedFileSeparator);
                pathOut(idx) = filesep;
            end
        end
    end % getRelativePath
end
