% VIPDH_STRIPES Model helper script for the VIP Periodic noise removal demo.
%   This script is run in the model workspace initialization function
%   which can be accessed using the model explorer.

% Copyright 2004-2014 The MathWorks, Inc.

% load and initialize the data required by vipstripes demo

ht = 120;
wt = 160;
cf=0.65;
f=cf-0.04:0.005:cf+0.04;
f=repmat(f,[7,1]);
f=f(:);
p = 0:0.5:3;

Hd = vipstripes_filter;
b  = Hd.Numerator; % extract filter coefficients from the filter object

% convert the one dimensional filter to 2-D using ftrans2 function from
% the Image Processing toolbox
h = ftrans2(b);

% set up variables used by the frequency domain filter

source_dim = [120 160];
padded_size = 256;