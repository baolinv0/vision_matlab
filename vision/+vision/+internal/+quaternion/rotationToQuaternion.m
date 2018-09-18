function quaternion = rotationToQuaternion(R)
% rotationToQuaternion Converts (orthogonal) rotation matrix R to (unit) quaternion.
% 
% quaternion is a 4-by-1 vector
% R is a 3x3 orthogonal matrix of corresponding rotation matrix
%
% Note
% ----
% R is rotation of vectors anti-clockwise in a right-handed system by pre-multiplication
%
% Copyright 2014 The MathWorks, Inc.

% References
% ----------
% http://en.wikipedia.org/wiki/Rotation_matrix#Quaternion

Qxx = R(1,1);
Qxy = R(1,2);
Qxz = R(1,3);
Qyx = R(2,1);
Qyy = R(2,2);
Qyz = R(2,3);
Qzx = R(3,1);
Qzy = R(3,2);
Qzz = R(3,3);

t = Qxx+Qyy+Qzz;

if t >= 0,
    r = sqrt(1+t);
    s = 0.5/r;
    w = 0.5*r;
    x = (Qzy-Qyz)*s;
    y = (Qxz-Qzx)*s;
    z = (Qyx-Qxy)*s;
else
    maxv = max(Qxx, max(Qyy, Qzz));
    if maxv == Qxx
        r = sqrt(1+Qxx-Qyy-Qzz);
        s = 0.5/r;
        w = (Qzy-Qyz)*s;
        x = 0.5*r;
        y = (Qyx+Qxy)*s;
        z = (Qxz+Qzx)*s;
    elseif maxv == Qyy
        r = sqrt(1+Qyy-Qxx-Qzz);
        s = 0.5/r;
        w = (Qxz-Qzx)*s;
        x = (Qyx+Qxy)*s;
        y = 0.5*r;
        z = (Qzy+Qyz)*s;
    else
        r = sqrt(1+Qzz-Qxx-Qyy);
        s = 0.5/r;
        w = (Qyx-Qxy)*s;
        x = (Qxz+Qzx)*s;
        y = (Qzy+Qyz)*s;
        z = 0.5*r;
    end
end

quaternion = [w;x;y;z];
