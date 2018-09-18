function writeBoxFile(boxFilename, boxData, sz)
% writeBoxFile creates a box file named boxFilename using the bounding box
% data in boxData. The .box extension must be provided in the boxFilename.
% The bounding box data in boxData is stored in [x y width height] format
% and must be converted to the [left bottom right top] format used within
% the box file. This image size information required for this conversion is
% given in the input sz and corresponds to size(I), where I is the training
% image corresponding to the boxData.

% create a box file. tesseract requires using UTF-8 encoding.
[fid, msg] = fopen(boxFilename, 'w', 'native','UTF-8');

if fid < 0
    error('Unable to open file: %s', msg);
end

closeFile = onCleanup(@()fclose(fid));

% convert [x y width height] to [left bottom right top] format
left   = boxData.bboxes(:,1) - 1;
top    = sz(1) - boxData.bboxes(:,2);
right  = left + boxData.bboxes(:,3);
bottom = top - boxData.bboxes(:,4);

% Write data into box file.
numBoxes = size(boxData.bboxes, 1);
for i = 1:numBoxes    
    fprintf(fid,'%s %d %d %d %d %d\n', ...
        boxData.chars{i}, left(i), bottom(i), right(i), top(i), boxData.page(i));
end