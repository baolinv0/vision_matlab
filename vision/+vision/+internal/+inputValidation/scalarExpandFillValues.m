% Copyright 2013 MathWorks, Inc.

%#codegen
function fillValuesOut = scalarExpandFillValues(fillValues, I)
if size(I, 3) > 1 && isscalar(fillValues)
    fillValuesOut = cast(repmat(fillValues, [1, 1, 3]), 'like', I);
else
    fillValuesOut = cast(fillValues, 'like', I);
end