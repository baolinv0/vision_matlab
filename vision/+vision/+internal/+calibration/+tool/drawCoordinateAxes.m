function drawCoordinateAxes(boardSize, hAxes, p)
% Draw origin marker
plot(hAxes, p(1,1),p(1,2), ...
    'MarkerEdgeColor', 'yellow', ...
    'Marker', 'square', ...
    'LineStyle', 'none', ...
    'LineWidth', 2,'MarkerSize', 10);

color = 'black';
p1 = p(1,:);
p2 = p(2,:);
p3 = p(boardSize(1), :);
[loc, theta] = getAxesLabelPosition(p1, p2, p3);
alignment = 'bottom';
displayAxesLabel('(0,0)', loc, theta, alignment, color);

p1 = p(boardSize(1)-1,:);
p2 = p(boardSize(1)-2,:);
p3 = p(2 * (boardSize(1)-1),:);
[loc, theta] = getAxesLabelPosition(p1, p2, p3);
alignment = 'top';
displayAxesLabel('\downarrowY', loc, theta, alignment, color);

p1 = p(end - boardSize(1)+2, :);
p3 = p(end - 2*(boardSize(1) - 2)-1, :);
p2 = p(end - boardSize(1)+3, :);
[loc, theta] = getAxesLabelPosition(p1, p2, p3);
theta = 180 + theta;
alignment = 'bottom';
displayAxesLabel('X\rightarrow', loc, theta, alignment, color);

%--------------------------------------------------------------
    function displayAxesLabel(label, loc, theta, alignment, labelColor)
        text(loc(1), loc(2), label, 'Parent', hAxes, 'Color', labelColor,...
            'FontUnits', 'normalized', 'FontSize', 0.05,...
            'Rotation', theta, ...
            'BackgroundColor', 'white',...
            'EdgeColor', 'black',...
            'VerticalAlignment', alignment, 'Clipping', 'on');
    end

%--------------------------------------------------------------
% p1+v
%  \
%   \     v1
%    p1 ------ p2
%    |
% v2 |
%    |
%    p3
    function [loc, theta] = getAxesLabelPosition(p1, p2, p3)
        v1 = p3 - p1;
        theta = -atan2d(v1(2), v1(1));
        
        v2 = p2 - p1;
        v = -v1 - v2;
        d = hypot(v(1), v(2));
        minDist = 40;
        if d < minDist
            v = (v / d) * minDist;
        end
        loc = p1 + v;
    end
end