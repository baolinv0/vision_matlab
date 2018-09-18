function fullPathName = getFullPathName(fileName)
%getFullPathName returns the full path name of a file on path.

% Try to find the absolute path by calling fopen twice.
fid = fopen(fileName);
if fid ~= -1
    fullPathName = fopen(fid);
    fclose(fid);
else
    % The file wasn't found, return the file name.
    fullPathName = fileName;
end
end