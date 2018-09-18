function ret = fontinfo(arg1)
%FONTINFO Provides information about TrueType fonts installed on the system.
%   FONTNAMES = FONTINFO returns a cell array of sorted TrueType
%   font names installed on the system. These font names have been modified
%   so that they would work with Simulink combo-box. Special characters
%   like ',' , ')' , '(' and '|' have been removed from their names.
%
%   FONTFILE = FONTINFO(FONTNAME) returns the path to the font file for the
%   font face name given in FONTNAME, where FONTNAME is one of the entries
%   in the list returned by FONTINFO.
%
%    Copyright 1995-2007 The MathWorks, Inc.

allFonts = struct([]);
fontList = cell(0);  
fontIndx = 1;  i = 1; 
if ispc
    numFonts = fontpicker;
    while numFonts
        fontName = fontpicker(i);
        i = i + 1;
        % Add font names to allFonts structure as well as fontList.
        if ~ismember(fontName,fontList)
            fontList{end+1} = fontName; %#ok<AGROW>
            allFonts(fontIndx).fontName = fontName; 
            allFonts(fontIndx).fontFile = fontpicker(fontName);
            fontIndx = fontIndx+1;
        end                            
        numFonts = numFonts-1;
    end
else
    fontFiles = getFontFilesUNIX;    
    if ~ isempty(fontFiles)
        numFonts = length(fontFiles);
        while numFonts
            allFonts(fontIndx).fontFile = fontFiles{i};
            i = i + 1;
            [pathStr,theName,theExtension] = fileparts(allFonts(fontIndx).fontFile); %#ok
            fontName = theName;
            fontName = strrep(fontName, '_', ' ');
            if ~ismember(fontName,fontList)
                fontList{end+1} = fontName; %#ok<AGROW>
                allFonts(fontIndx).fontName = fontName;
                fontIndx = fontIndx+1;
            end            
            numFonts = numFonts-1;
        end
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
    ret = fontList; %allFonts;
elseif nargin == 1
    if ischar(arg1)
        ret = getFontFilename(allFonts, arg1);
    else
        error(message('vision:fontinfo:invalidInputArg'));
    end
end

%-------------------------------------------------------------------------
function filename = getFontFilename(fontlist, fontName)
filename = '';
if isempty(fontlist)
    return;
end
for i=1:length(fontlist)
    if strcmpi(fontlist(i).fontName, fontName) == 1
        filename = fontlist(i).fontFile;
        return;
    end
end

%-------------------------------------------------------------------------
function fontFiles = getFontFilesUNIX
fontDirs = getFontDirs;
numFontDirs = length(fontDirs);
for i=1:numFontDirs
    fontDirs{end+1} = [fontDirs{i}  '../truetype/']; %#ok<AGROW>
    fontDirs{end+1} = [fontDirs{i}  '../TrueType/']; %#ok<AGROW>
    fontDirs{end+1} = [fontDirs{i}  '../TTF/']; %#ok<AGROW>
end
fontDirs{end+1} = [matlabroot '/toolbox/vipblks/vipblks/fonts/'];
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
            fontFiles{end+1} = [fontDirs{i} thisDirFontFiles(j).name]; %#ok<AGROW>
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
    end
end
