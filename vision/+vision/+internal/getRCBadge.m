% getRCBadge Returns data for drawing an 'RC' badge on blocks using the old
%   coordinate system

% Copyright 2011 The MathWorks, Inc.

function [x,y,badge] = getRCBadge

if nargout == 1
    badge.color = 'red';
    badge.txt   = 'Replace';
    badge.txtX  = 0.5;
    badge.txtY  = 0.05;
    badge.boxX  = [0.28 0.72 0.72 0.28 0.28];
    badge.boxY  = [0.01 0.01 0.24 0.24 0.01];
    badge.ha    = 'center';
    badge.va    = 'bottom';
    
    x = badge;
else
    x = 0.34;
    y = 0.18;
    badge = 'Replace';
end
