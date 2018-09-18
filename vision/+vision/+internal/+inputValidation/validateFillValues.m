function tf = validateFillValues(fillValues, I, fileName, varName)

%#codegen
%#ok<*EMTC>

if nargin < 4
    varName = 'FillValues';
end

if nargin < 3
    fileName = mfilename;
end

if isempty(coder.target)
    % use try/catch to throw error from calling function. This produces an
    % error stack that is better associated with the calling function.
    try 
        tf = localValidate(fillValues, I, fileName, varName);
    catch E        
        throwAsCaller(E); % to produce nice error message from caller.
    end
else
    tf = localValidate(fillValues, I, fileName, varName);
end

function tf = localValidate(fillValues, I, fileName, varName)
validateattributes(fillValues, {'numeric'},...
    {'nonempty','nonsparse', 'vector'}, ...
    fileName, varName); %#ok<EMCA>

coder.internal.errorIf(ismatrix(I) && ~isscalar(fillValues),...
    'vision:calibrate:scalarFillValueRequired');

coder.internal.errorIf(size(I, 3) > 1 && numel(fillValues) > 3,...
    'vision:calibrate:scalarOrTripletFillValueRequired');

tf = true;