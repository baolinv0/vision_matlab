function varargout = mplay(varargin)
%MPLAY View video from files, the MATLAB workspace, or Simulink signals.
%
% -------------------------------------------------------------------------
% This function will be removed in a future release. Please use 
% IMPLAY function instead of MPLAY.
% -------------------------------------------------------------------------
%
%   See also implay, vision.VideoPlayer, vision.DeployableVideoPlayer

% Copyright 2004-2009 The MathWorks, Inc.

visionsyslinit;

nargs = nargin;
names = cell(1, nargs);
for indx = 1:nargs
    names{indx} = inputname(indx);
end

hScopeCfg = scopeextensions.MPlayScopeCfg(varargin, uiservices.cacheFcnArgNames(names));
hMPlay = uiscopes.new(hScopeCfg);
if nargout > 0
    varargout = {hMPlay};
end
