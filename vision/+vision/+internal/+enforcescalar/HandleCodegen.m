%#codegen

% codegen redirection class. Allows us to overload subsref using
% EnforceScalar* to get the behavior we need in MATLAB and still allows
% codegen. This work around can be removed once g912825 is resolved.
classdef HandleCodegen < vision.internal.enforcescalar.HandleBase
    methods(Access = protected, Sealed)
        function enforceNoArray(obj)
            coder.internal.errorIf(true,...
                'vision:dims:arrayNotSupported',...
                class(obj));
        end
    end
end
