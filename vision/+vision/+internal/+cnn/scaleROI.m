function scaledROI = scaleROI(roi, sx, sy)
% input  space is u,v
% output space is x,y
% sx,sy scale from input to output
% output scaledROI is in min/max roi format [xmin ymin xmax ymax]

u1 = roi(:,1);
u2 = u1 + roi(:,3) - 1;
v1 = roi(:,2);
v2 = v1 + roi(:,4) - 1;

% convert to spatial coordinates
u1 = u1 - 0.5;
u2 = u2 + 0.5;
v1 = v1 - 0.5;
v2 = v2 + 0.5;

% scale
x1 = u1 * sx + (1-sx)/2;
x2 = u2 * sx + (1-sx)/2;
y1 = v1 * sy + (1-sy)/2;
y2 = v2 * sy + (1-sy)/2;

% convert to pixel coordinates
x1 = x1 + 0.5;
x2 = x2 - 0.5;
y1 = y1 + 0.5;
y2 = y2 - 0.5;

scaledROI = floor([x1 y1 x2 y2]);
end