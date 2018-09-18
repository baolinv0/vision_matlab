% -------------------------------------------------------------------------
% Axes handle validation. Returns true if AX is a valid axes handle
% otherwise an error is thrown.
% -------------------------------------------------------------------------
function tf = validateAxesHandle(ax)
tf = true;

if ~(isscalar(ax) && ishghandle(ax,'axes'))
    error(message('vision:validation:invalidAxesHandle'));
end
