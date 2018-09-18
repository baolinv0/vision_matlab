function initializeVerticalAxis(currentAxes, vertAxis, vertAxisDir)
view(currentAxes,3);
if strcmpi(vertAxis, 'X')
    if strncmpi(vertAxisDir, 'Up', 1)
        set(currentAxes, 'CameraUpVector', [1 0 0]);
    else
        set(currentAxes, 'CameraUpVector', [-1 0 0]);
    end
elseif strcmpi(vertAxis, 'Y')
    % This setup is best used to visualize data in a camera centric view point
    if strncmpi(vertAxisDir, 'Up', 1)
        set(currentAxes, 'CameraUpVector', [0 1 0]);
        camorbit(currentAxes, 60, 0, 'data', [0 1 0]);
    else
        set(currentAxes, 'CameraUpVector', [0 -1 0]);
        camorbit(currentAxes, -120, 0, 'data', [0 1 0]);
    end
else
    if strncmpi(vertAxisDir, 'Up', 1)
        set(currentAxes, 'CameraUpVector', [0 0 1]);
    else
        % This setup is best used to visualize data where world coordinate
        % system is set on the checkerboard during camera calibration process
        set(currentAxes, 'CameraUpVector', [0 0 -1]);
        camorbit(currentAxes, -110, 60, 'data', [0 0 1]);
    end
end