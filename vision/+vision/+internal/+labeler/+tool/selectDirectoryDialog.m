function [imgDirectory, gTruthFilename, userCancelled] = selectDirectoryDialog(groupName)

% Copyright 2017 The MathWorks, Inc.

imgDirectory  = [];
gTruthFilename = [];
userCancelled = false;

currentlyLoading   = false;

persistent previousLocations;

% Create file chooser if necessary:
needToInitPath = isempty(previousLocations);
if needToInitPath
    previousLocations = '';
end

% If this is the first time you're using this and there is no record of a
% previous directory, previousSettings{1} will return empty. In either
% case, we default to the present working directory.
if(isempty(previousLocations) || isempty(previousLocations{1}))
    folderAbsolutePath = pwd;
else
    % Using only one location now
    folderAbsolutePath = previousLocations{1};
end

dlgHeight = 8;
loadDirDialog = dialog(...
    'Name', vision.getMessage('vision:labeler:TempDirectoryTitle'),...
    'Units','char',...
    'Position',[0 0 100 dlgHeight],...
    'Visible','off',...
    'Tag','LoadDirDialog');
loadDirDialog.CloseRequestFcn = @doCancel;
movegui(loadDirDialog, 'center');


% Label
uicontrol('Parent', loadDirDialog,...
    'Style','text', ...
    'Units', 'char',...
    'Position', [1 dlgHeight-2 100 1.5],...
    'HorizontalAlignment', 'left',...
    'String', vision.getMessage('vision:labeler:TempDirectoryDialog'));

% Text box to type folder path
hFolderTextBox = uicontrol('Parent', loadDirDialog,...
    'Style', 'edit', ...
    'Units', 'char',...
    'Position', [1 dlgHeight-4 80 1.5],...
    'String', folderAbsolutePath, ...
    'HorizontalAlignment', 'left',...
    'KeyPressFcn',@doLoadIfEntered,...
    'Tag','InputFolderTextBox');

    function doLoadIfEntered(~, event)
        if(strcmp(event.Key,'return') && strcmp(hLoadButton.Enable,'on'))
            doLoad();
        end
    end

% Browse button
currentlyBrowsing = false;
hBrowseButton = uicontrol('Parent', loadDirDialog, ...
    'Style','pushbutton',...
    'Units', 'char',...
    'Position', [85 dlgHeight-4 14 1.5],...
    'Callback', @doBrowse,...
    'String', vision.getMessage('vision:labeler:Browse'),...
    'Tag','BrowseButton');

    function doBrowse(varargin)
        if(currentlyBrowsing)
            return;
        end
        currentlyBrowsing = true;
        dirname = uigetdir(hFolderTextBox.String, vision.getMessage('vision:labeler:TempDirectoryTitle'));
        if(dirname ~= 0)
            folderAbsolutePath = dirname;
            hFolderTextBox.String    = folderAbsolutePath;
        end
        currentlyBrowsing = false;
    end

% Cancel button
hCancelButton = uicontrol('Parent', loadDirDialog, ...
    'Style','pushbutton',...
    'Callback', @doCancel,...
    'Units', 'char',...
    'Position', [85 1 14 1.5],...
    'String', vision.getMessage('vision:labeler:Cancel'),...
    'Tag','CancelButton');

    function doCancel(varargin)
        userCancelled = true;
        % Reset output variables when user cancels
        imgDirectory = [];
        
        if(~currentlyLoading)
            delete(loadDirDialog);
        end
    end

% Load button
hLoadButton = uicontrol('Parent', loadDirDialog, ...
    'Style','pushbutton',...
    'Callback', @doLoad,...
    'Units', 'char',...
    'Position', [65 1 16 1.5],...
    'String', vision.getMessage('vision:labeler:Accept'),...
    'Enable', 'on',...
    'Tag', 'LoadButton');

    function doLoad(varargin)
        drawnow; % Ensure all edits are captured
        folderAbsolutePath = hFolderTextBox.String;
        folderAbsolutePath = strtrim(folderAbsolutePath);
                
        if(isdir(folderAbsolutePath))
            tempDirectory = fullfile(folderAbsolutePath, ['Labeler_' groupName]);
            status = mkdir(tempDirectory);
            if status
                % Remember successfully loaded location
                previousLocations = {folderAbsolutePath};
                imgDirectory = tempDirectory;            
                delete(loadDirDialog);
            else
                errorMessage = vision.getMessage('vision:labeler:UnableToWrite', folderAbsolutePath);
                dialogName = vision.getMessage('vision:labeler:UnableToWriteTitle');                  
                errordlg(errorMessage, dialogName);              
            end
            
        else
            errorMessage = vision.getMessage('vision:labeler:InvalidFolder', folderAbsolutePath);
            dialogName = vision.getMessage('vision:labeler:InvalidFolderTitle');                  
            errordlg(errorMessage, dialogName);              
        end
    end

loadDirDialog.Units = 'pixels'; % needed for API below
loadDirDialog.Visible = 'on';
uiwait(loadDirDialog);
end