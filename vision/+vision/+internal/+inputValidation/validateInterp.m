function interp = validateInterp(method)
% Function for validating interpolation method.

%#codegen
%#ok<*EMTC>

if isempty(coder.target)
    % use try/catch to throw error from calling function. This produces an
    % error stack that is better associated with the calling function.
    try 
        interp = localValidate(method);
    catch E        
        throwAsCaller(E); % to produce nice error message from caller.
    end
else
    interp = localValidate(method);
end

function interp = localValidate(method)
interp = validatestring(method,...
    {'nearest','linear','cubic','bilinear','bicubic'}, ...
    mfilename, 'interp');%#ok<EMCA>
