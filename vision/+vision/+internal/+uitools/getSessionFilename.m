% Open a FileSave dialog for saving a session
function filename = getSessionFilename(defaultFileName)

[filename, pathname] = uiputfile('*.mat', ...
    vision.getMessage('vision:uitools:SaveSessionAsOption'), ...
        defaultFileName);

isCanceled = isequal(filename,0) || isequal(pathname,0);

if isCanceled
    filename = '';
else
    filename = [pathname, filename];
end
