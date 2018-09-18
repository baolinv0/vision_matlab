% rotationVectorToMatrix Convert a 3-D rotation vector into a rotation matrix
%
% rotationMatrix = rotationVectorToMatrix(rotationVector) reconstructs a 
% 3D rotationMatrix from a rotationVector (axis-angle representation) using
% the Rodrigues formula. rotationVector is a 3-element vector representing 
% the axis of rotation in 3-D. The magnitude of the vector is the rotation 
% angle in radians. rotationMatrix is a 3-by-3 3-D rotation matrix 
% corresponding to rotationVector. 
%
% Class Support
% -------------
% rotationVector can be double or single. rotationMatrix is the same class
% as rotationVector.
%
% Example
% -------
% % Create a vector representing 90-degree rotation about Z-axis
% rotationVector = pi/2 * [0, 0, 1];
%
% % Find the equivalent rotation matrix
% rotationMatrix = rotationVectorToMatrix(rotationVector)
%
% See also rotationMatrixToVector, cameraParameters, relativeCameraPose, 
%          estimateWorldCameraPose, extrinsics

% References:
% [1] R. Hartley, A. Zisserman, "Multiple View Geometry in Computer
%     Vision," Cambridge University Press, 2003.
% 
% [2] E. Trucco, A. Verri. "Introductory Techniques for 3-D Computer
%     Vision," Prentice Hall, 1998.

%#codegen
function rotationMatrix = rotationVectorToMatrix(rotationVector)

validateattributes(rotationVector, {'single', 'double'}, ...
    {'real', 'nonsparse', 'vector', 'numel', 3}, mfilename, 'rotationVector');

rotationMatrix = vision.internal.calibration.rodriguesVectorToMatrix(rotationVector)';
