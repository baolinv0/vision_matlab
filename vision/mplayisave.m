function mplayisave(fname)
%MPLAYISAVE Get and save current MPlay instrumentation set to file.
%   MPLAYISAVE(FNAME) saves an instrumentation set structure describing the
%   current state of all open MPlay instances.  This file can be
%   passed to MPLAYILOAD to reinstantiate all MPlay instances.]
%   FNAME is the name of a MAT-file.  By default, FNAME='mplay.iset'
%
%   See also: MPLAYILOAD, MPLAYCLOSE, MPLAYFIND.

% Copyright 2005-2010 The MathWorks, Inc.

% Default iset name:
if nargin<1
    fname='mplay.iset';
end

% Default iset extension:
[p,n,e]=fileparts(fname);
if isempty(e)
    fname=[fname '.iset'];
end

uiscopes.isave(fname);

% [EOF]
