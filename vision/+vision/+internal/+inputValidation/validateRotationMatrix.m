function validateRotationMatrix(M, fileName, varName)
%#codegen
validateattributes(M, {'numeric'}, ...
    {'finite', '2d', 'real', 'nonsparse', 'size', [3,3]}, fileName, varName);

% M is a rotational matrix if and only if M is orthogonal, i.e.
% M*M'=I, and det(M)=1

coder.internal.errorIf(abs(det(double(M))-1) > 1e-3,...
                'vision:validation:invalid3DRotationMatrix');
M = double(M);
MM = M*M';
I = eye(3);
coder.internal.errorIf(max(abs(MM(:)-I(:))) > 1e-3,...
                'vision:validation:invalid3DRotationMatrix');
