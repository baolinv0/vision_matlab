% EnforceScalarValue overloads key methods to prevent the creation of
% object arrays.
%
% This class supports codegen.
%
% Examples of syntaxes that will error out:
%
%  obj(1)
%  obj(ones(3,3))
%  obj(2) = obj
%  [obj obj] % horzcat
%  [obj;obj] % vertcat
%  obj(1).property
%  repmat(obj,3,3)
%  cat(2,obj,obj)

classdef EnforceScalarValue < matlab.mixin.internal.Scalar
    methods(Access = public, Static)
        % Redirect for codegen. We need this until an overloaded subsref is
        % allowed for codegen (g912825)
        function name = matlabCodegenRedirect(~)
            name = 'vision.internal.enforcescalar.ValueCodegen';
        end
    end
end
