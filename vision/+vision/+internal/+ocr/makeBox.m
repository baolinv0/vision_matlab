function varargout = makeBox(I, boxFile, language)
% makeBox create a box file by running OCR on I using the specified
% language. boxFile specifies the name of the generated box file and should
% not include the .box extension.


if nargin < 3
    language = 'English';
end

if ~islogical(I)
    Iu8 = im2uint8(I);    
    I = vision.internal.ocr.convertRGBToGray(Iu8);
end

% Set variables from makebox config file
setVariable.tessedit_create_boxfile = '1';

% Init variables from batch.nochop config file
initVariable.chop_enable = '0';
initVariable.wordrec_enable_assoc = '0';

tessOpts.lang     = vision.internal.ocr.convertLanguageToAlias(language);
tessOpts.tessdata = vision.internal.ocr.locateTessdataFolder(tessOpts.lang);
tessOpts.setVariable = setVariable;
tessOpts.initVariable = initVariable;

txt = tesseractMakeBox(tessOpts, I);
if nargout == 1
    % Write text to file
    fid = fopen([boxFile '.box'],'w','n','UTF-8'); % tesseract uses UTF-8 encoding
    fprintf(fid,txt);
    success = fclose(fid);
    if success~=0
        warning('MATLAB:toolbox:vision:ocr:training', ...
            'tessMakeBox could not write to file %s', boxFile);
    end
    varargout{1} = success;
else
        
end
