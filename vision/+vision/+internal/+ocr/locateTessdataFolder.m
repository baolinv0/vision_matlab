function tessdata = locateTessdataFolder(lang)
% Determine the location of the tessdata folder. When the support package
% is installed the support package's tessdata folder is used. Otherwise,
% the default tessdata folder is used.
%
% Input lang is 3-character code for language as returned by
% vision.internal.ocr.convertLanguageToAlias.

%#codegen

coder.extrinsic('fullfile','eml_try_catch');
if vision.internal.ocr.ocrSpkgInstalled()
    
    if vision.internal.ocr.isCodegen()
       [~,~,tessdata] = eml_const(eml_try_catch(... 
           'vision.internal.ocr.getTessdataSupportPackageLocation', lang));                           
    else
        tessdata = vision.internal.ocr.getTessdataSupportPackageLocation(lang);        
    end
    
else
    if isdeployed && ~vision.internal.ocr.isCodegen()
        mlroot = coder.internal.const(ctfroot);
    else
        mlroot = coder.internal.const(matlabroot);
    end
    tessdata = coder.internal.const(...
        fullfile(mlroot,'toolbox','vision','visionutilities'));
end

% Tesseract requires that the path must end with a filesep
tessdata = [tessdata localFilesep];

tessdata = addDoubleFilesepOnPC(tessdata);

% -------------------------------------------------------------------------
% Return a filesep based on the current platform. Code generation only
% supports filesep on MEX and SFUN targets. For other targets, the unix
% style / is returned.
% -------------------------------------------------------------------------
function fs = localFilesep

if isempty(coder.target)
    fs = filesep;
else
    if strcmp(coder.target,'sfun') || strcmp(coder.target,'mex')
        % ispc only support on host
        if ispc
            fs = '\';
        else
            fs = '/';
        end
    else
        % use unix style filesep for non-host
        fs = '/';
    end
end
    
% -------------------------------------------------------------------------
% Tesseract requires that language fileseps are doubled (\ -> \\) on PCs
% -------------------------------------------------------------------------
function out = addDoubleFilesepOnPC(p)

if isempty(coder.target) || ...
        strcmp(coder.target,'sfun') || ...
        strcmp(coder.target,'mex')
    if ispc
        fs  = localFilesep;
        isUNCPath = ~isempty(strfind(p(1:2),'\\'));       
        if isUNCPath
            out = strrep(p(3:end),fs,[fs fs]);
            out = ['\\' out];
        else
            out = strrep(p,fs,[fs fs]);
        end
    else
        out = p;
    end
else
    out = p;
end
