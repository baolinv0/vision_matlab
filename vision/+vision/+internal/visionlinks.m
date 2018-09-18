function [currentOut toremoveOut] = visionlinks
% VISIONLINKS Display and return library link information for
%    blocks linked to the Computer Vision System Toolbox libraries.
% 
%   VISIONLINKS highlites the blocks from Computer Vision System Toolbox 
%               libraries in the current system (gcs) with color:
%
%                  blue - for current blocks
%                  red  - for blocks which are slated for removal in a 
%                         future release
%
%   [CURRENT TOREMOVE] = VISIONLINKS returns the blocks in a cell array.
%
%   See also DSP_LINKS, LIBLINKS.

% Copyright 2003-2004 The MathWorks, Inc.

sys = gcs;

libs = vision.internal.librarylist;

current  = liblinks(libs.current, sys,'blue');
toremove = liblinks(libs.toremove,sys,'red');

if nargout > 0
    currentOut = current;
    if nargout > 1
        toremoveOut = toremove;
    end
end
    
