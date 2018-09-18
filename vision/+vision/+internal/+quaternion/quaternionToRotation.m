function R = quaternionToRotation(quaternion)
% quaternionToRotation Converts (unit) quaternion to (orthogonal) rotation matrix.
% 
% quaternion is a 4-by-1 vector
% R is a 3x3 orthogonal matrix of corresponding rotation matrix
%
% Note
% ----
% R is rotation of vectors anti-clockwise in a right-handed system by pre-multiplication

% Copyright 2014 The MathWorks, Inc.

% References
% ----------
% http://en.wikipedia.org/wiki/Quaternions_and_spatial_rotation#From_a_quaternion_to_an_orthogonal_matrix

q0 = quaternion(1);
qx = quaternion(2);
qy = quaternion(3);
qz = quaternion(4);

R = [q0.^2+qx.^2-qy.^2-qz.^2, 2*qx.*qy-2*q0.*qz,       2*qx.*qz+2*q0.*qy; ...
     2*qx.*qy+2*q0.*qz,       q0.^2-qx.^2+qy.^2-qz.^2, 2*qy.*qz-2*q0.*qx; ...
     2*qx.*qz-2*q0.*qy,       2*qy.*qz+2*q0.*qx,       q0.^2-qx.^2-qy.^2+qz.^2];
