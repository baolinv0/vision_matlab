function lang = validateSupportPackageLanguages(userLang)
% Validate languages strings against those in the support package.

%#codegen

validStrings = vision.internal.ocr.languagesInSupportPackage();
lang = validatestring(userLang, validStrings, 'ocr');



