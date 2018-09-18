function value = resolve( this, variableName )
%RESOLVE 
%   Copyright 2015 The MathWorks, Inc.

    [value,errorID] = evaluateVariable(this,variableName);
    if ~isempty(errorID)
        value = [];
    end                 
end

function [value,errorID,errorMessage] = evaluateVariable(this,variableName)
    % Evaluate a variable using slResolve first. If not successful,
    % try uiservices.evaluate. If varaibleName is not a string, we
    % return it without evaluating and a non empty error. If the
    % variable is not defined, we return empty for evaluated value
    % and a non empty error ID if simulation is running. If not, we
    % return the variableName back with empty error ID.
    try
        blockObj = get_param(this.Handle,'Object');
        value = slResolve(variableName,blockObj.getFullName);
        errorID = '';
        errorMessage = '';
    catch ME
        if ischar(variableName)
            [value,errorID,errorMessage] = uiservices.evaluate(variableName);
        else
            value = variableName; 
            errorID = ME.identifier;
            errorMessage = ME.message;
        end
    end
end