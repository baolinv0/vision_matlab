function lang = validateLanguage(userLang, isSupportPackageInstalled)
% Validates languages strings against the language strings supported by ocr
% and those available in the OCR support package.

%#codegen

% Determine whether the OCR Language support package is required.
n = numel(userLang);

% To avoid ambiguity between English and other languages that start with an
% 'e', 'en' is required for a partial match to 'english'
isEnglish  = n > 1 && strncmpi(userLang, 'english',n);

isJapanese = strncmpi(userLang, 'japanese', n);

coder.extrinsic('eml_try_catch');

% Determine whether the language string is valid. First, English and
% Japanese are check as these are the built-in ocr languages. If neither of
% these is selected, then check against content of the OCR Support Package.
if isEnglish
    lang = 'English';
elseif isJapanese
    lang = 'Japanese';
else % check if in support package
    
    if isempty(coder.target)
        try  %#ok<EMTC>
            lang = vision.internal.ocr.validateSupportPackageLanguages(userLang);
            inSupportPackage = true;
        catch
            lang = '';
            inSupportPackage = false;
        end
        
        % Error out if language is in the support package, but the support
        % package is not installed.
        if inSupportPackage && ~isSupportPackageInstalled
            msg = message('vision:ocr:requiresSupportPackage',userLang);
            str = getString(msg);
            error('vision:ocr:requiresSupportPackage',...
                '<a href="matlab:visionSupportPackages">%s</a>',str);
        end
        
        % Error out if the language is not in the support package.
        if ~inSupportPackage
            %langs = getFormattedLanguageStrings();
            msg1  = message('vision:ocr:languagesInSupportPackage');
            msg2  = message('vision:ocr:languagesInSupportPackageDisp');
            error('vision:ocr:languagesInSupportPackage',...
                '%s <a href="matlab:disp(vision.internal.ocr.formatLanguages(false))">%s</a>',...
                getString(msg1),...
                getString(msg2));
        end
    else        
        [~,~,langVal] = eml_const(eml_try_catch(...
            'vision.internal.ocr.validateSupportPackageLanguages',userLang));      
        
        if isempty(langVal)
            % An error was thrown evaluating
            % validateSupportPackageLanguages this means userLang was not
            % one of the support package languages.            
            lang = '';
            inSupportPackage = false;
        else            
            lang = langVal;
            inSupportPackage = true;           
        end        
               
        % Error out if language is in the support package, but the support
        % package is not installed.
        if inSupportPackage && ~isSupportPackageInstalled            
            % use eml_invariant to force compile time error message
            % (coder.internal.errorIf throws a runtime error), which is not
            % desirable here.            
            eml_invariant(0, ...
                eml_message('vision:ocr:requiresSupportPackage',userLang));
        end
        
        % Error out if the language is not in the support package.
        if ~inSupportPackage
            langs = getFormattedLanguageStrings();
            eml_invariant(0, ...
                eml_message('vision:ocr:languagesInSupportPackageCodegen',langs));
        end
    end                     
end

%--------------------------------------------------------------------------
function str = getFormattedLanguageStrings()
coder.extrinsic('eml_try_catch');

if isempty(coder.target)
    str = vision.internal.ocr.formatLanguages(false);
else    
    [~,~,str] = eml_const(eml_try_catch('vision.internal.ocr.formatLanguages',true));
end
