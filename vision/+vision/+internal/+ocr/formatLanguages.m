function str = formatLanguages(isCodegen)
% Format language strings for error message display.

%#codegen

langs = vision.internal.ocr.languagesInSupportPackage();
if isCodegen
    % comma separated display for MATLAB coder report.
    str = sprintf('%s, ',langs{:}); %#ok<EMCA>
    str = str(1:end-2);
else
    % newline separated display for command window.
    str = sprintf('%s\n',langs{:}); %#ok<EMCA>
end
