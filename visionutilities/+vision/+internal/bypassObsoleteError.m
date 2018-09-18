function out=bypassObsoleteError(varargin)
% bypassObsoleteError Bypass error thrown by an obsolete block or function.
%   S = bypassObsoleteError returns true when bypass is activated and
%   false otherwise.
%
%   bypassObsoleteError(FLAG) sets the state of the bypass. When FLAG
%   is set to true, the error will no longer be issued.

%   Copyright 2011 The MathWorks, Inc.

persistent flag;
mlock; % prevent the persistent variable from being easily cleared

narginchk(0,1);

if isempty(flag)
    flag = false; % issue the error by default
end

if nargin > 0
    flag = logical(varargin{1});
else
    % Simply return the state of the bypass flag.
end

out = flag;
