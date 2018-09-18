function inst = mplayfind(varargin)
%MPLAYFIND Find MPlay GUI instances.
%   MPLAYFIND returns a vector of MPlay.MPlayer objects corresponding to
%   each open instance of the MPlay GUI.  Order of instances is the order
%   in which the GUI's were most recently in focus; the first entry
%   corresponds to the MPlay instance that most recently had focus, etc.
%
%   MPLAYFIND(I) returns only the objects corresponding to the specified
%   instance numbers I.  If I is empty, all MPlay instances are returned.
%
%   MPLAYFIND(0) returns the MPlayer object corresponding to the instance
%   of MPlay that has the current window focus.  If no instance of MPlay
%   currently has focus, an empty matrix is returned.

% Copyright 2005 The MathWorks, Inc.

inst = uiscopes.find(varargin{:});

indx = 1;
while indx <= length(inst)
    if strcmp(inst(indx).getAppName(true), 'MPlay')
        indx = indx + 1;
    else
        inst(indx) = [];
    end
end

% [EOF]
