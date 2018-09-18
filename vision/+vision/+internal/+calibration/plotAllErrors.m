%--------------------------------------------------------------
% Plot a scatter plot of X vs. Y

% Copyright 2017 MathWorks, Inc.
function plotAllErrors(hAxes, errors, highlightIndex)
% Record the current 'hold' state so that we can restore it later
holdState = get(hAxes,'NextPlot');

numPatterns = size(errors, 3);
% colormap for marker colors
colorLookup = im2double(label2rgb(1:numPatterns, ...
    'lines','c','shuffle'));

% plot the errors
legendStrings = cell(1, numPatterns);
for i = 1:numPatterns
    legendStrings{i} = sprintf('%d', i);
    x = errors(:, 1, i);
    y = errors(:, 2, i);
    if highlightIndex(i)
        marker = 'o';
    else
        marker = '+';
    end
    color = squeeze(colorLookup(1,i,:))';
    plot(hAxes, x, y, marker, 'MarkerEdgeColor', color);                    
    set(hAxes, 'NextPlot', 'add'); % hold on 
end

drawnow();
% plot highlighted points again to make them more visible
for i = 1:numPatterns
    if highlightIndex(i)
        x = errors(:, 1, i);
        y = errors(:, 2, i);
        marker = 'o';
        color = squeeze(colorLookup(1,i,:))';
        plot(hAxes, x, y, marker, 'MarkerEdgeColor', color);   
    end
end

legend(hAxes, legendStrings, 'AutoUpdate', 'off');
title(hAxes, getString(message('vision:calibrate:scatterPlotTitle')));
xlabel(hAxes, getString(message('vision:calibrate:scatterPlotXLabel')));
ylabel(hAxes, getString(message('vision:calibrate:scatterPlotYLabel')));

axis equal;
set(hAxes, 'NextPlot', holdState); % restore the hold state                 

