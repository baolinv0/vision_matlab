% relativeCameraPose Compute relative up-to-scale pose of calibrated camera
%   [relativeOrientation, relativeLocation] = relativeCameraPose(M, cameraParams,
%   inlierPoints1, inlierPoints2) returns the orientation and up-to-scale location of a
%   calibrated camera relative to its previous pose. relativeLocation is always
%   a unit vector.
%
%   M is either essential or fundamental matrix. cameraParams is a
%   cameraParameters or cameraIntrinsics object. inlierPoints1 and
%   inlierPoints2 are matching inlier points from the two views
%   corresponding to the two poses. M, inlierPoints1, and inlierPoints2 are
%   returned by the estimateEssentialMatrix or estimateFundamentalMatrix
%   functions. relativeOrientation is a 3-by-3 rotation matrix.
%   relativeLocation is a unit vector of size 3-by-1.
%
%   [...] = relativeCameraPose(M, cameraParams1, cameraParams2, inlierPoints1, inlierPoints2)
%   returns the orientation and location of camera 2 relative to camera 1.
%   cameraParams1 and cameraParams2 are cameraParameters or
%   cameraIntrinsics objects containing the parameters of camera 1 and
%   camera 2 respectively.
%
%   [..., validPointsFraction] = relativeCameraPose(...) additionally returns the
%   fraction of the inlier points that project in front of both cameras. If
%   this fraction is too small (e. g. less than 0.9), that can indicate that
%   the fundamental matrix is incorrect.
%
%   Notes
%   -----
%   - You can compute the camera extrinsics as follows:
%     [rotationMatrix, translationVector] = cameraPoseToExtrinsics(
%       relativeOrientation, relativeLocation)
%
%   - The relativeCameraPose function uses inlierPoints1 and inlierPoints2 to
%     determine which one of the four possible solutions is physically
%     realizable.
%
%    Class Support
%    -------------
%    M must be double or single. cameraParams must be a cameraParameters or
%    cameraIntrinsics object. inlierPoints1 and inlierPoints2 can be
%    double, single, or any of the point feature types. location and
%    orientation are the same class as M.
%
%  Example: Structure from motion from two views
%  ---------------------------------------------
%  % This example shows you how to build a point cloud based on features
%  % matched between two images of an object.
%  % <a href="matlab:web(fullfile(matlabroot,'toolbox','vision','visiondemos','html','StructureFromMotionExample.html'))">View example</a>
%
%  See also estimateWorldCameraPose, cameraCalibrator, estimateCameraParameters, 
%    estimateEssentialMatrix, estimateFundamentalMatrix, cameraMatrix,
%    plotCamera, triangulate, triangulateMultiview, cameraPoseToExtrinsics,
%    extrinsics

% Copyright 2015 The MathWorks, Inc.

% References:
% -----------
% [1] R. Hartley, A. Zisserman, "Multiple View Geometry in Computer
% Vision," Cambridge University Press, 2003.
%
% [2] R. Hartley, P. Sturm. "Triangulation." Computer Vision and
% Image Understanding. Vol 68, No. 2, November 1997, pp. 146-157

%#codegen

function [orientation, location, validPointsFraction] = ...
    relativeCameraPose(F, varargin)

[cameraParams1, cameraParams2, inlierPoints1, inlierPoints2] = ...
    parseInputs(F, varargin{:});

if isa(cameraParams1, 'cameraIntrinsics')
    cameraParams1 = cameraParams1.CameraParameters;
end

if isa(cameraParams2, 'cameraIntrinsics')
    cameraParams2 = cameraParams2.CameraParameters;
end

K1 = cameraParams1.IntrinsicMatrix;
K2 = cameraParams2.IntrinsicMatrix;

if isFundamentalMatrix(F, inlierPoints1, inlierPoints2, K1, K2)
    % Compute the essential matrix
    E = K2 * F * K1';
else
    % We already have the essential matrix
    E = F;
end

[Rs, Ts] = vision.internal.calibration.decomposeEssentialMatrix(E);
[R, t, validPointsFraction] = chooseRealizableSolution(Rs, Ts, cameraParams1, cameraParams2, inlierPoints1, ...
    inlierPoints2);

% R and t are currently the transformation from camera1's coordinates into
% camera2's coordinates. To find the location and orientation of camera2 in
% camera1's coordinates we must take their inverse.
orientation = R';
location = -t * orientation;

%--------------------------------------------------------------------------
function tf = isFundamentalMatrix(M, inlierPoints1, inlierPoints2, K1, K2)
% Assume M is F
numPoints = size(inlierPoints1, 1);
pts1h = [inlierPoints1, ones(numPoints, 1, 'like', inlierPoints1)];
pts2h = [inlierPoints2, ones(numPoints, 1, 'like', inlierPoints2)];
errorF = mean(abs(diag(pts2h * M * pts1h')));

% Assume M is E
F = K2 \ M / K1';
errorE = mean(abs(diag(pts2h * F * pts1h')));

tf = errorF < errorE;

%--------------------------------------------------------------------------
function [cameraParams1, cameraParams2, inlierPoints1, inlierPoints2] = ...
    parseInputs(F, varargin)
narginchk(4, 5);
validateattributes(F, {'single', 'double'}, ...
    {'real', 'nonsparse', 'finite', '2d', 'size', [3,3]}, mfilename, 'F');

cameraParams1 = varargin{1};
if isa(varargin{2}, 'cameraParameters') || isa(varargin{2}, 'cameraIntrinsics')
    cameraParams2 = varargin{2};
    paramVarName = 'cameraParams';
    idx = 2;
else
    paramVarName = 'cameraParams1';
    cameraParams2 = cameraParams1;
    idx = 1;
end
validateattributes(cameraParams1, {'cameraParameters','cameraIntrinsics'},...
    {'scalar'}, mfilename, paramVarName);

points1 = varargin{idx + 1};
points2 = varargin{idx + 2};
[inlierPoints1, inlierPoints2] = ...
    vision.internal.inputValidation.checkAndConvertMatchedPoints(...
    points1, points2, mfilename, 'inlierPoints1', 'inlierPoints2');

coder.internal.errorIf(isempty(points1), 'vision:relativeCameraPose:emptyInlierPoints');

%--------------------------------------------------------------------------
% Determine which of the 4 possible solutions is physically realizable.
% A physically realizable solution is the one which puts reconstructed 3D
% points in front of both cameras.
function [R, t, validFraction] = chooseRealizableSolution(Rs, Ts, cameraParams1, ...
    cameraParams2, points1, points2)
numNegatives = zeros(1, 4);

camMatrix1 = cameraMatrix(cameraParams1, eye(3), [0 0 0]);
for i = 1:size(Ts, 1)
    camMatrix2 = cameraMatrix(cameraParams2, Rs(:,:,i)', Ts(i, :));
    m1 = triangulateMidPoint(points1, points2, camMatrix1, camMatrix2);
    m2 = bsxfun(@plus, m1 * Rs(:,:,i)', Ts(i, :));
    numNegatives(i) = sum((m1(:,3) < 0) | (m2(:,3) < 0));
end

[val, idx] = min(numNegatives);

validFraction = 1 - (val / size(points1, 1));

R = Rs(:,:,idx)';
t = Ts(idx, :);

tNorm = norm(t);
if tNorm ~= 0
    t = t ./ tNorm;
end

%--------------------------------------------------------------------------
% Simple triangulation algorithm from
% Hartley, Richard and Peter Sturm. "Triangulation." Computer Vision and
% Image Understanding. Vol 68, No. 2, November 1997, pp. 146-157
function points3D = triangulateMidPoint(points1, points2, P1, P2)

numPoints = size(points1, 1);
points3D = zeros(numPoints, 3, 'like', points1);
P1 = P1';
P2 = P2';

M1 = P1(1:3, 1:3);
M2 = P2(1:3, 1:3);

c1 = -M1 \ P1(:,4);
c2 = -M2 \ P2(:,4);
y = c2 - c1;

u1 = [points1, ones(numPoints, 1, 'like', points1)]';
u2 = [points2, ones(numPoints, 1, 'like', points1)]';

a1 = M1 \ u1;
a2 = M2 \ u2;

isCodegen  = ~isempty(coder.target);
condThresh = eps(class(points1));

for i = 1:numPoints
    A   = [a1(:,i), -a2(:,i)];  
    AtA = A'*A;
    
    if rcond(AtA) < condThresh
        % Guard against matrix being singular or ill-conditioned
        p    = inf(3, 1, class(points1));
        p(3) = -p(3);
    else
        if isCodegen
            % mldivide on square matrix is faster in codegen mode.
            alpha = AtA \ A' * y;
        else
            alpha = A \ y;        
        end
        p = (c1 + alpha(1) * a1(:,i) + c2 + alpha(2) * a2(:,i)) / 2;
    end
    points3D(i, :) = p';

end
