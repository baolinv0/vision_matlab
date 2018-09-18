function validateTranslationVector(t, fileName, varName)
%#codegen
validateattributes(t, {'numeric'}, ...
    {'finite', 'vector', 'real', 'nonsparse', 'numel', 3}, fileName, varName);    