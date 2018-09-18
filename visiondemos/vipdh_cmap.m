% VIPDH_CMAP creates custom colormap for two demos:  vipspokes and
%   vipstaples

% Copyright 2004 The MathWorks, Inc.
function cmap=vipdh_cmap

cmap = hot(220);
cmap = cmap(40:6:220,:);
cmap(1,:) = [0 0 0];



