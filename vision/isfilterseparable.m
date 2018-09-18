function [S, HCOL, HROW]  = isfilterseparable(H)
% ISFILTERSEPARABLE  Check filter separability. 
% S = ISFILTERSEPARABLE(H) takes in the filter kernel H and returns true
% if filter is separable, otherwise it returns false.
%
% [S, HCOL, HROW]  = ISFILTERSEPARABLE(H) optionally returns the vertical
% coefficients HCOL  and horizontal coefficients HROW, if the filter is
% separable, otherwise HCOL and HROW are empty. 
%
% Class Support
% -------------
% H can be logical or numeric, 2-D, and nonsparse. 
% S is logical, HCOL and HROW are the same class as H if H is float 
% otherwise they are double. 

%   Copyright 2003-2005 The MathWorks, Inc. 

S = false;
if (~isa(H,'float')),  H = double(H); end
if all(isfinite(H(:)))
  % Check rank (separability) of H
  [u,s,v] = svd(H);
  s = diag(s);
  tol = length(H) * eps(max(s));
  rank = sum(s > tol);   
  S = (rank ==1);
end
HCOL = [];
HROW = [];
if S
    HCOL = u(:,1) * sqrt(s(1));
    HROW = conj(v(:,1)) * sqrt(s(1));
end
HROW = HROW.';    