function mplayiload(fname)
%MPLAYILOAD Load and restore MPlay instrumentation set from file.
%   MPLAYILOAD(FNAME) loads an instrumentation set structure describing the
%   state of MPlay instances and opens those instances.  This file is
%   created by MPLAYISAVE.  FNAME is the name of a MAT-file.  By default,
%   FNAME='mplay.iset'
%
%   See also: MPLAYISAVE, MPLAYCLOSE, MPLAYFIND.

%   Copyright 2005-2010 The MathWorks, Inc.

% Default iset name:
if nargin<1
    fname='mplay.iset';
end

% Default iset extension:
[p,n,e]=fileparts(fname);
if isempty(e)
    fname=[fname '.iset'];
end

uiscopes.iload(fname);

% [EOF]
