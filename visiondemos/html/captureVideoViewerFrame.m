function i = captureVideoViewerFrame(blockName, multiplier)
%CAPTUREVIDEOVIEWERFRAME 

%   Copyright 2008-2015 The MathWorks, Inc.
scopeCfg = get_param(blockName,'ScopeConfiguration');

f = figure;
data = scopeCfg.CData;
if islogical(data)
    i = imshow(data, 'border','tight');
else
    colorMap = eval(scopeCfg.MapExpression);
    i = imshow(data, colorMap, 'border','tight');
end

if nargin < 2
    multiplier = scopeCfg.Magnification;
end

a = ancestor(i, 'axes');
pos = get(a, 'position');
set(a, 'position', [0 0 pos(3:4)*multiplier], 'units','pixels');
set(f, 'Units', 'Pixels');
pos = get(a, 'position');
figpos = get(f, 'position');
set(f, 'position', [figpos(1:2) pos(3:4)]);

% [EOF]
