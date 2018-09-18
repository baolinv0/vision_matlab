%--------------------------------------------------------------
% Plot a bar graph with error bars

% Copyright 2017 MathWorks, Inc.
function plotMeanErrorPerImage(hAxes, meanError, meanErrors, highlightIndex)

% Record the current 'hold' state so that we can restore it later
holdState = get(hAxes,'NextPlot');

% plot the mean errors
hBar = bar(hAxes, meanErrors, 'FaceColor', [0 0.7 1]);                
set(hBar, 'Tag', 'errorBars');

set(hAxes, 'NextPlot', 'add'); % hold on     

% plot errors for highlighted images
highlightedErrors = meanErrors;
highlightedErrors(~highlightIndex) = 0;
hHighlightedBar = bar(hAxes, highlightedErrors, ...
    'FaceColor', [0 0 1]);
set(hHighlightedBar, 'Tag', 'highlightedBars');

hErrorLine = line(get(hAxes, 'XLim'), [meanError, meanError],...
    'LineStyle', '--', 'Parent', hAxes);

% Set AutoUpdate to off to prevent other items from
% appearing automatically in the legend.
legend(hErrorLine, getString(message(...
    'vision:calibrate:overallMeanError', ...
    sprintf('%.2f', meanError))), ...
    'Location', 'SouthEast', ...
    'AutoUpdate', 'off');

set(hAxes, 'NextPlot', holdState); % restore the hold state                                

title(hAxes, getString(message('vision:calibrate:barGraphTitle')));
xlabel(hAxes, getString(message('vision:calibrate:barGraphXLabel')));
ylabel(hAxes, getString(message('vision:calibrate:barGraphYLabel')));
