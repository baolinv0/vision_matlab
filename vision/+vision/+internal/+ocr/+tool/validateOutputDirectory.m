% Validate that output directory is valid and writable.
%------------------------------------------------------------------
function isValid = validateOutputDirectory(dirname, issueError)

isValid = true;

if nargin == 1
    % open errordlg on error
    issueError = true;
end

if isdir(dirname)
    % Ensure writable.       
    try
        tmpfile = tempname(dirname);
        fid = fopen(tmpfile,'a');
    catch
        isValid = false;
    end
    
    if fid < 0
        isValid = false;
    end
    
    if isValid
        fclose(fid);
        delete(tmpfile);
    end
    
    if ~isValid && issueError
        msg   = vision.getMessage('vision:ocrTrainer:NoWritePermissions',dirname);
        title = vision.getMessage('vision:ocrTrainer:NoWritePermissionsTitle');
        errordlg(msg,title,'modal');
    end
else
    isValid = false;
    if issueError
        msg   = vision.getMessage('vision:ocrTrainer:InvalidDirectory',dirname);
        title = vision.getMessage('vision:ocrTrainer:InvalidDirectoryTitle');
        errordlg(msg,title,'modal');
    end
end
