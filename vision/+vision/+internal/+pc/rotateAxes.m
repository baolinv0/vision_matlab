function rotateAxes(ax,dtheta,dphi,axCenter,vertAxis,vertAxisDir,showAxis)
% Rotate Axes around given axis
if nargin < 6
    showAxis = false;
end

currentPose = ax.CameraPosition;
up = ax.CameraUpVector;       

currentTarg = ax.CameraTarget;
dar = ax.DataAspectRatio;

% View Axis: vector from camera position to rotation center
vaxis = axCenter - currentPose;
coordsysval = lower(vertAxis) - 'x' + 1;

% First rotation axis is parallel to the principle up axis
raxis1 = [0 0 0];
if strncmpi(vertAxisDir,'down',1)
    raxis1(coordsysval) = -1;
    dtheta = -dtheta;
    dphi = -dphi;
else
    raxis1(coordsysval) = 1;
end

% Second rotation axis orthogonal to the plane made by raxis1 and vaxis
raxis2 = crossSimple(vaxis,raxis1);    
raxis2 = raxis2/simpleNorm(raxis2); 

upsidedown = (up(coordsysval) < 0);
if upsidedown
    dtheta = -dtheta;
    raxis2 = -raxis2;    
end

if showAxis
    hline1 = findobj(ax,'tag','pcViewerRAxis1'); 
    hline2 = findobj(ax,'tag','pcViewerRAxis2');
    hline3 = findobj(ax,'tag','pcViewerRAxis3');
    XSpan = ax.XLim(2)-ax.XLim(1);
    YSpan = ax.YLim(2)-ax.YLim(1);
    ZSpan = ax.ZLim(2)-ax.ZLim(1);
    
    minSpan = min([XSpan,YSpan,ZSpan]);
    vlength = minSpan*0.2;
    raxis1 = raxis1*vlength;
    raxis2 = raxis2*vlength;
    raxis3 = crossSimple(raxis1,raxis2);
    raxis3 = raxis3/simpleNorm(raxis3)*vlength;
    
    hline1.XData = [axCenter(1),axCenter(1)+raxis1(1)];
    hline1.YData = [axCenter(2),axCenter(2)+raxis1(2)];
    hline1.ZData = [axCenter(3),axCenter(3)+raxis1(3)];
    hline2.XData = [axCenter(1),axCenter(1)+raxis2(1)];
    hline2.YData = [axCenter(2),axCenter(2)+raxis2(2)];
    hline2.ZData = [axCenter(3),axCenter(3)+raxis2(3)];
    hline3.XData = [axCenter(1),axCenter(1)+raxis3(1)];
    hline3.YData = [axCenter(2),axCenter(2)+raxis3(2)];
    hline3.ZData = [axCenter(3),axCenter(3)+raxis3(3)];
    
end

% Check if the camera up vector is parallel with the view direction;
% if yes, use another rotation axis
if any(isnan(raxis2))
    raxis2 = crossSimple(raxis1,up);
end

% Rotate the camera, its upvector, and the camera target around raxis1 and
% raxis2 by dtheta and dphi
[newPos, newUp, newTarg] = localCamrotate(currentPose,currentTarg,axCenter,dar,up,dtheta,dphi,raxis1,raxis2);


if ~all(isnan(newPos))    
    ax.CameraPosition = newPos;
    ax.CameraUpVector= newUp;
end

if ~all(isnan(newTarg))    
    ax.CameraTarget = newTarg;
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Perform camera rotation around 2 axis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [newPos, newUp, newTarg] = localCamrotate(a,targ,b,dar,up,dt,dp,direction1,direction2)
%   Rotate a and targ around two axis
%   Rotation is first around a line defined by 
%      point b and direction1, then a line defined by point b and
%      direction2

va = (b-a)./dar;
ra = crossSimple(va, up./dar);
ua = crossSimple(ra, va);

dis = simpleNorm(va);
va = va/dis;
ua = ua/simpleNorm(ua);

% same for target
vtarg = (b-targ)./dar;
disTarg = simpleNorm(vtarg);
vtarg = vtarg/disTarg;

haxis = direction1/simpleNorm(direction1);
vaxis = direction2/simpleNorm(direction2);

rotH = localRotMat(haxis,dt);
rotV = localRotMat(vaxis,-dp);

rotHV = rotV*rotH;
newV = -va*rotHV;
newUp = ua*rotHV;
newVTarg = -vtarg*rotHV;

newPos=b+newV*dis.*dar;
newUp=newUp.*dar;
newTarg = b+newVTarg*disTarg.*dar;
end

function rotM = localRotMat(axis,dt)
deg2rad = pi/180;
alph = dt*deg2rad;
cosa = cos(alph);
sina = sin(alph);
vera = 1 - cosa;
x = axis(1);
y = axis(2);
z = axis(3);
rotM = [cosa+x^2*vera x*y*vera-z*sina x*z*vera+y*sina; ...
  x*y*vera+z*sina cosa+y^2*vera y*z*vera-x*sina; ...
  x*z*vera-y*sina y*z*vera+x*sina cosa+z^2*vera]';

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% simple cross product
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function c=crossSimple(a,b)
c(1) = b(3)*a(2) - b(2)*a(3);
c(2) = b(1)*a(3) - b(3)*a(1);
c(3) = b(2)*a(1) - b(1)*a(2);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% simple norm for a 3D vector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function n = simpleNorm(v)
n = sqrt(v(1)^2+v(2)^2+v(3)^2);
end