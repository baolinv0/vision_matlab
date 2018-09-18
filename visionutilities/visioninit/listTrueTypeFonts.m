function ret = listTrueTypeFonts(arg1)
%listTrueTypeFonts List available TrueType fonts.
%   fontNames = listTrueTypeFonts returns a cell array of sorted TrueType
%   font names installed on the system.
%
%   Example 1: List available TrueType fonts
%   ----------------------------------------
%   listTrueTypeFonts
%
%   Example 2: Find all TrueType 'Lucida' fonts
%   ------------------------------------------
%   fontNames = listTrueTypeFonts;
%   LucidaFonts = fontNames(~cellfun(@isempty,regexp(fontNames,'^Lucida')))
%
%   See also listfonts, insertText, insertObjectAnnotation.

%   Copyright 1995-2015 The MathWorks, Inc.

allFonts = struct([]);
fontList = cell(0);  
fontIndx = 1;  i = 1; 
if ispc
    numFonts = fontpicker;
    while numFonts
        fontName = fontpicker(i);
        thisFontFile = fontpicker(fontName);
        
        i = i + 1;
        % Add font names to allFonts structure as well as fontList.        
        [allFonts, fontList, fontIndx] = createFontInfo(fontName, ...
            thisFontFile, allFonts, fontList, fontIndx);
                           
        numFonts = numFonts-1;
    end
else
    fontFiles = getFontFilesUNIX;    
    numFonts = length(fontFiles);
    while numFonts
        thisFontFile = fontFiles{i};
        fontName = getFontNameFromFileForUNIX(thisFontFile);

        i = i + 1;
        % Add font names to allFonts structure as well as fontList.        
        [allFonts, fontList, fontIndx] = createFontInfo(fontName, ...
            thisFontFile, allFonts, fontList, fontIndx);       
        numFonts = numFonts-1;          
    end
end
allFonts = addJavaFonts(allFonts);
numFonts = length(allFonts);
% Add Java fonts to fontList. 
for i = fontIndx:numFonts
    fontList{end+1} = allFonts(i).fontName; %#ok<AGROW>
end    
    

% The fontFaces need to be listed in a sorted order in the block's pop-up.
fontList = sort(fontList);

% now look at input arguments to see what the user wants
if nargin == 0
    ret = reshape(fontList,[length(fontList) 1]); %allFonts;
elseif nargin == 1
    if ischar(arg1)
        [fileName, faceIndex] = getFontFilenameFaceindex(allFonts, arg1);
        ret.fileName = fileName;
        ret.faceIndex = faceIndex;
    else
        error(message('vision:fontinfo:invalidInputArg'));
    end
end

%-------------------------------------------------------------------------
function [allFonts, fontList, fontIndx] = createFontInfo(fontName, ...
            thisFontFile, allFonts, fontList, fontIndx)
        
% Font Face Index:
% ---------------
% For some fonts, one font file contains multiple fonts of different   
% styles. On windows, one example of such font is 'MS Mincho & MS PMincho'. 
% In listTrueTypeFonts, we post-process the LONG font name to generate 
% SHORT font name with a single style. So 'MS Mincho & MS PMincho' 
% is split into 'MS Mincho' and 'MS PMincho'. But here both styles 
% use a single font file. To use different styles from a single font file, 
% FT_New_Face function uses faceIndex. Here we assume that fonts
% are named in ascending order of font index; so for LONG font name 
% 'A & B & C', SHORT font name 'A' has font index 0, 
%                              'B' has font index 1,
%                              'C' has font index 2

fontNameCell = strsplit(fontName, ' & ');
for p=1:length(fontNameCell)
    if ~ismember(fontNameCell{p},fontList) && ~isempty(fontNameCell{p})                
        fontList{end+1} = fontNameCell{p}; %#ok<AGROW>
        allFonts(fontIndx).fontName = fontNameCell{p};
        allFonts(fontIndx).fontFile = thisFontFile;% same file name for all fonts in fontNameCell
        allFonts(fontIndx).faceIndex = uint8(p-1); % most of the time, faceIndex = 0
        fontIndx = fontIndx+1;
    end
end 
%-------------------------------------------------------------------------
function fontName = getFontNameFromFileForUNIX(thisFontFile)

[pathStr,theName,theExtension] = fileparts(thisFontFile); %#ok
fontName = theName;
fontName = strrep(fontName, '_', ' ');
            
%-------------------------------------------------------------------------
function [fileName, faceIndex] = getFontFilenameFaceindex(fontlist, fontName)
fileName = '';
faceIndex = uint8(0);
if isempty(fontlist)
    return;
end
for i=1:length(fontlist)
    if strcmpi(fontlist(i).fontName, fontName) == 1
        fileName = fontlist(i).fontFile;
        faceIndex = fontlist(i).faceIndex;
        return;
    end
end

%-------------------------------------------------------------------------
function subDirNames = getSubDirNames(rootDir)

filelist = dir(rootDir);
% get list of subdirectories.
dirList = filelist([filelist.isdir]);
% filter by excluding '.', '..'
filteredDirList = dirList(cellfun(@isempty,regexp({dirList.name},'^(\.|\.\.)$')));
% prepend root dir to the path
subDirNames = cellfun(@(in)fullfile(rootDir,in, filesep),{filteredDirList.name},...
    'UniformOutput',false);

if ~isempty(subDirNames)                
    for i=1:numel(subDirNames)
        tempDirNames = getSubDirNames(subDirNames{i});
        subDirNames = [subDirNames, tempDirNames]; %#ok<AGROW>
    end
end

%-------------------------------------------------------------------------
function fontDirs = appendTrueTypeDirs(fontDirs)
numFontDirs = length(fontDirs);
for i=1:numFontDirs
    fontDirs{end+1} = [fontDirs{i}  '../truetype/'];  %#ok<AGROW>
    fontDirs1 = getSubDirNames(fontDirs{end});
    for ii=1:length(fontDirs1)
        fontDirs{end+1} = fontDirs1{ii}; %#ok<AGROW>
    end
    fontDirs{end+1} = [fontDirs{i}  '../TrueType/']; %#ok<AGROW>
    fontDirs2 = getSubDirNames(fontDirs{end});
    for ii=1:length(fontDirs2)
        fontDirs{end+1} = fontDirs2{ii};%#ok<AGROW>
    end
    fontDirs{end+1} = [fontDirs{i}  '../TTF/']; %#ok<AGROW>
    fontDirs3 = getSubDirNames(fontDirs{end});
    for ii=1:length(fontDirs3)
        fontDirs{end+1} = fontDirs3{ii};%#ok<AGROW>
    end
end

%-------------------------------------------------------------------------
function fontFiles = getFontFilesUNIX
fontDirs = getFontDirs;
fontDirs = appendTrueTypeDirs(fontDirs);
fontDirs = fixUpDirAndRemoveDups(fontDirs);
fontFiles = findFontFilesInThesePaths(fontDirs);

%-------------------------------------------------------------------------
function fontFiles = findFontFilesInThesePaths(fontDirs)
fontFiles = {};
ttf_pattern = '*.ttf';
numFontDirs = length(fontDirs);
for i=1:numFontDirs
    thisDirFontFiles = dir([fontDirs{i} ttf_pattern]);
    if ~ isempty(thisDirFontFiles)
        for j=1:length(thisDirFontFiles)
            if ~isempty(thisDirFontFiles(j).name)
              fontFiles{end+1} = [fontDirs{i} thisDirFontFiles(j).name]; %#ok<AGROW>
            end
        end
    end
end

%-------------------------------------------------------------------------
function fontDirs = getFontDirs

persistent unixFontDirs

if ismac
  % On the Mac, X11 fonts are not used. Qt and Java use system fonts,
  % located on these paths:
  theFontDirs = {'/System/Library/Fonts' '/Library/Fonts' '~/Library/Fonts'};
else
 if isempty(unixFontDirs)
    unixFontDirs = xfonts;
    % Append the following dirs explicitly
    unixFontDirs{end+1} = '/usr/share/fonts/dummy';
    unixFontDirs{end+1} = '/usr/local/share/fonts/dummy';
 end
 theFontDirs = unixFontDirs;
end
fontDirs = cell(1,length(theFontDirs));

for i=1:length(theFontDirs)
    if theFontDirs{i}(end) ~= filesep
        theFontDirs{i}(end+1) = filesep;
    end
    fontDirs{i} = theFontDirs{i};
end

%-------------------------------------------------------------------------
function fontDirs = fixUpDirAndRemoveDups(allDirs)
fontDirs = cell(size(allDirs));
for i=1:length(allDirs),
    if isempty(strfind(allDirs{i}, [filesep '..' filesep]))
        fontDirs{i} = allDirs{i};
    else
        % make the /thisDir/../ just be /
        pat = [filesep '[^' filesep ']*' filesep '..' filesep];  % /<anything>/../ 
        repl = filesep;                     % /
        fontDirs{i} = regexprep(allDirs{i}, pat, repl);
    end
    if ~isempty(strfind(fontDirs{i}, [filesep '.' filesep]))
        % make the /./ just be /
        pat = [filesep '.' filesep];  % /./ 
        repl = filesep;                     % /
        fontDirs{i} = regexprep(fontDirs{i}, pat, repl);
    end    
end
fontDirs = unique(fontDirs);

%-------------------------------------------------------------------------
function withJavaFonts = addJavaFonts(fontList)
withJavaFonts = fontList;
if exist('java.lang.System','class') ~= 8
    return;
end
javaPath = char(java.lang.System.getProperty('java.home'));
javaFontDir = [javaPath filesep 'lib' filesep 'fonts'];
listing = dir(javaFontDir);
for i=1:length(listing)
    ttfStart = strfind(listing(i).name, '.ttf');
    if ~ listing(i).isdir && ~ isempty(ttfStart)
        newIndex = length(withJavaFonts) + 1;
        withJavaFonts(newIndex).fontName = listing(i).name(1:ttfStart-1);
        withJavaFonts(newIndex).fontFile = [javaFontDir filesep listing(i).name];
        withJavaFonts(newIndex).faceIndex = uint8(0);
    end
end
