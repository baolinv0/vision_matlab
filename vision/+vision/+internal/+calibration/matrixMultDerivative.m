function [AB, dABdA, dABdB] = matrixMultDerivative(A,B)
% matrixMultDerivative Compute derivative of (A*B) w.r.t A, or B.
%
% [AB, dABdA, dABdB] = matrixMultDerivative(A,B), where AB = A * B
%
% Note, the derivative is 4-D tensor, which is a very large matrix.
% Currently, this function is intended to be used for small matrix input.
% For example, it is used for 3x3 rotation matrix.

% Copyright 2017 MathWorks, Inc.

AB = A * B;

outputClass = class(AB);

[p, n] = size(A); 
[~, q] = size(B);

A = double(A);
B = double(B);

dABdA = zeros(p*q, p*n);

for i = 1 : q
    for j = 1 : p
        ij = j + (i-1)*p;
        for k = 1 : n
            kj = j + (k-1)*p;
            dABdA(ij,kj) = B(k,i);            
        end        
    end
end

dABdB = zeros(p*q, q*n);

for i = 1:q
    dABdB((i*p-p+1:i*p)',(i*n-n+1:i*n)) = A;
end

dABdA = cast(dABdA, outputClass);
dABdB = cast(dABdB, outputClass);