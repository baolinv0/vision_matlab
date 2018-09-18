% createSingleCameraProgressBar Create a progress bar for calibration

% Copyright 2017 MathWorks, Inc.
function progressBar = createSingleCameraProgressBar(isEnabled)
messages = {'vision:calibrate:initialGuess', 'vision:calibrate:jointOptimization', ...
            'vision:calibrate:calibrationComplete'};
percentages = [0, 0.25, 1];        
progressBar = vision.internal.calibration.CalibrationProgressBar(isEnabled,...
    messages, percentages);