function out = testEstimateGeometricTransform(varargin)
%testEstimateGeometricTransform Set or get debugging mode for estimateGeometricTransform
%   S = testEstimateGeometricTransform returns whether the
%   estimateGeometricTransform function has been set to debugging mode.
%
%   testEstimateGeometricTransform(FLAG) sets the debugging mode to FLAG
%   for the estimateGeometricTransform function.

%   Copyright  The MathWorks, Inc.

persistent flag;
mlock; % prevent the persistent variable from being easily cleared

if isempty(flag)
    flag = false; % Default is false
end

out = flag; % Return the old flag

if nargin > 0
    flag = logical(varargin{1});
end
