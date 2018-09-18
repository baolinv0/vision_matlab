% Generate character icons for use in the image strip.

function icon = generateCharacterIcon(font, character, n)

label = vision.internal.ocr.tool.ImageSet.generateCharacterIconDescription(n);

try
    if strcmpi(character,char(0))
        fontSize = 10;
        character = vision.getMessage('vision:ocrTrainer:UnknownString');
    else
        fontSize = 34;
    end
    thumbnailSize = [48 48];
    javaImage = generateThumbnail(...
        character, font, fontSize, thumbnailSize);    
    
    icon{1} = javax.swing.ImageIcon(javaImage);
    icon{1}.setDescription(label);
    
catch loadingEx
    errordlg(loadingEx.message,...
        vision.getMessage('vision:uitools:LoadingImageFailedTitle'),...
        'modal');
end

%------------------------------------------------------------------
% Use java to render glyphs. java fonts are supported on more
% platforms and does not require special fonts to display a wide
% range of unicode characters.
function imgbuffer = generateThumbnail(character, fontstr, fontSize, thumbnailSize)

persistent bg % for icon background
if isempty(bg)
    bg = imread(fullfile(...
        toolboxdir('vision'), 'vision','+vision','+internal',...
        '+ocr','+tool','iconbg.png'));        
end

% Use unicode font.
font = java.awt.Font(fontstr, java.awt.Font.PLAIN, fontSize);

antialias = true;
frc = javaObjectEDT('java.awt.font.FontRenderContext', ...
    java.awt.geom.AffineTransform(), antialias, false);



w = thumbnailSize(2);
h = thumbnailSize(1);
centerX = w/2;
centerY = h/2;

% create the java image buffer to draw into
imgbuffer = im2java2d(bg);

g2d = javaMethodEDT('createGraphics', imgbuffer);
javaMethodEDT('setFont', g2d, font)

% get the bounds of the string to draw.
fontMetrics   = javaMethodEDT('getFontMetrics', g2d);

stringWidth = javaMethodEDT('stringWidth', fontMetrics, character);

if stringWidth > w
    % scale font size to fit into thumbnail    
    while stringWidth > w && font.getSize > 1
        font = java.awt.Font(fontstr, java.awt.Font.PLAIN, font.getSize - 1);
        javaMethodEDT('setFont', g2d, font);
        fontMetrics   = javaMethodEDT('getFontMetrics', g2d);
        stringWidth = javaMethodEDT('stringWidth', fontMetrics, character);
    end           
end

stringBounds  = javaMethodEDT('getStringBounds',fontMetrics, character, g2d);
stringRect    = javaMethodEDT('getBounds', stringBounds);

gv = javaMethodEDT('createGlyphVector', font, frc, 'S');

% get the visual bounds of the text using a GlyphVector.
visualBounds   = javaMethodEDT('getVisualBounds', gv);
visualRect     = javaMethodEDT('getBounds', visualBounds);

% calculate the lower left point at which to draw the string.
% note that this we give the graphics context the y corridinate
% at which we want the baseline to be placed. use the visual
% bounds height to center on in conjuction with the position
% returned in the visual bounds. the vertical position given
% back in the visualBounds is a negative offset from the
% basline of the text.
textX = centerX - stringRect.width/2;
textY = centerY - visualRect.height/2 - visualRect.y;

% set color to render black text
javaMethodEDT('setColor', g2d,javaObjectEDT('java.awt.Color',0,0,0));

% set rendering hints for antialiased text
javaMethodEDT('setRenderingHint', g2d, ...
    java.awt.RenderingHints.KEY_TEXT_ANTIALIASING,...
    java.awt.RenderingHints.VALUE_TEXT_ANTIALIAS_LCD_HRGB);       
        
javaMethodEDT('drawString', g2d, character, round(textX), round(textY));


