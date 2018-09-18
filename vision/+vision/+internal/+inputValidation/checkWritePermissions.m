function checkWritePermissions(foldername)
% Error if the folder specified doesn't have write access.

[status, values] = fileattrib(foldername);

hasWritePermissions = status && values.UserWrite;

if ~hasWritePermissions
    error(message('vision:validation:NoWritePermissions', foldername))
end
