function boxData = readBoxFile(boxFile, sz)
% boxData = readBoxFile(boxFile, sz) returns the box file information in
% boxFile.

[fid, msg] = fopen(boxFile, 'r', 'native','UTF-8');
closeFile  = onCleanup(@()fclose(fid));

if fid < 0
    error(msg);
end

data = textscan(fid, '%s %d %d %d %d %d');

boxData.chars  = data{1};
boxData.bboxes = [data{2:5}];
boxData.page   = data{end};

% convert tesseract [left bottom right top] bbox format to [x y width
% height]. note tesseract box file has origin at bottom left.

width  = boxData.bboxes(:,3) - boxData.bboxes(:,1); 
height = boxData.bboxes(:,4) - boxData.bboxes(:,2); 

x = boxData.bboxes(:,1) + 1;
y = sz(1) - boxData.bboxes(:,4);

boxData.bboxes = [x y width height];
