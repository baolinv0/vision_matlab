function [xyzRefinedPoints, refinedPoses, reprojectionErrors] = ...
    bundleAdjustment(varargin)
%bundleAdjustment Refine camera poses and 3-D points.
%   [xyzRefinedPoints, refinedPoses] = bundleAdjustment(xyzPoints, 
%       pointTracks, cameraPoses, cameraParams) returns the refined 3-D
%   points and camera poses that minimize the reprojection errors. 3-D
%   points and camera poses are placed in the same global reference
%   coordinate system. The refinement procedure is a variant of
%   Levenberg-Marquardt algorithm.
%
%   Inputs:
%   -------
%   xyzPoints     - an M-by-3 matrix of 3-D [x, y, z] locations.
%
%   pointTracks   - an N-element array of pointTrack objects, where each 
%                   element contains two or more points matched across
%                   multiple images.
%
%   cameraPoses   - a table containing three columns: 'ViewId',
%                   'Orientations' and 'Locations', typically produced by
%                   the poses function. The view IDs in point tracks refer
%                   to the view IDs in cameraPoses.
%                   
%   cameraParams  -  a cameraParameters or cameraIntrinsics object.
%
%   Outputs:
%   --------
%   xyzRefinedPoints - an M-by-3 matrix of refined point locations.
%
%   refinedPoses     - a table containing the refined camera poses.
%
%   [..., reprojectionErrors] = bundleAdjustment(...) additionally returns
%   reprojectionErrors, an N-element vector containing the mean
%   reprojection error for each 3-D world point.
% 
%   [...] = bundleAdjustment(..., Name, Value) specifies additional
%   name-value pairs described below:
%
%   'MaxIterations'          A positive integer to specify the maximum
%                            number of iterations before Levenberg-Marquardt
%                            algorithm stops.
%
%                            Default: 50
%
%   'AbsoluteTolerance'      A positive scalar to specify termination
%                            tolerance of mean squared reprojection error
%                            in pixels.
%
%                            Default: 1
%
%   'RelativeTolerance'      A positive scalar to specify termination 
%                            tolerance of relative reduction in
%                            reprojection error between iterations.
%
%                            Default: 1e-5
%
%   'PointsUndistorted'      A boolean to specify whether the 2-D points in
%                            pointTracks are from images without lens
%                            distortion or not.
%
%                            Default: False
%
%   'FixedViewIDs'           A vector of nonnegative integer to specify the 
%                            reference cameras whose pose are fixed during
%                            optimization. This integer refers to the view
%                            IDs in cameraPoses. When it is empty, all
%                            camera poses are optimized.
%
%                            Default: []
%
%   'Verbose'                Set true to display progress information.
%
%                            Default: False
%
%   Class Support 
%   ------------- 
%   xyzPoints must be single or double.
%
%   Example 1: Refine camera poses and 3-D points
%   ---------------------------------------------
%   % Load data for initialization
%   load('sfmGlobe');
%   
%   % Refine the camera poses and points
%   [xyzRefinedPoints, refinedPoses] = ...
%       bundleAdjustment(xyzPoints, pointTracks, cameraPoses, cameraParams);
%
%   % Display the refined camera poses and 3-D world points
%   pcshow(xyzRefinedPoints, 'VerticalAxis', 'y', 'VerticalAxisDir', 'down', ...
%       'MarkerSize', 45);
%   hold on
%   plotCamera(refinedPoses, 'Size', 0.1);
%   hold off
%   grid on
%
%   Example 2: Structure from motion from multiple views
%   ----------------------------------------------------
%   % This example shows you how to estimate the poses of a calibrated 
%   % camera from a sequence of views, and reconstruct the 3-D structure of
%   % the scene up to an unknown scale factor.
%   % <a href="matlab:web(fullfile(matlabroot,'toolbox','vision','visiondemos','html','StructureFromMotionFromMultipleViewsExample.html'))">View example</a>
%
% See also pointTrack, viewSet, triangulateMultiview, cameraParameters,
%          cameraIntrinsics
 
% Copyright 2015 The MathWorks, Inc.
%
% References
% ----------
% [1] M.I.A. Lourakis and A.A. Argyros (2009). "SBA: A Software Package for
%     Generic Sparse Bundle Adjustment". ACM Transactions on Mathematical
%     Software (ACM) 36 (1): 1-30.
%
% [2] R. Hartley, A. Zisserman, "Multiple View Geometry in Computer
%     Vision," Cambridge University Press, 2003.
%
% [3] B. Triggs; P. McLauchlan; R. Hartley; A. Fitzgibbon (1999). "Bundle
%     Adjustment: A Modern Synthesis". Proceedings of the International
%     Workshop on Vision Algorithms. Springer-Verlag. pp. 298-372.

% Validate and parse inputs
[xyzPoints, pointTracks, cameraPoses, cameraParams, maxIterations, ...
    absTol, relTol, isUndistorted, verbose, fixedCameraIndex, ...
    returnPointType] = validateAndParseOptInputs(varargin{:});

% Initialize the message printer        
printer = vision.internal.MessagePrinter.configure(verbose);
printer.printMessage('vision:sfm:sbaInitialization');

% Convert inputs to internal data structure
[measurements, visibility, cameraMatrices, quaternionBases, cameraParams, returnPoseType] = ...
    convertInputDataFormat(pointTracks, cameraPoses, cameraParams, isUndistorted);

% Initialize LM solver
[numPoints, numViews] = size(visibility);
errors = zeros(size(measurements));

% List of status code
% Terminating conditions: 
%   1 - small gradient ||J'e||_inf
%   2 - small increment ||dp||
%   3 - max iterations
%   4 - small relative reduction in ||e||
%   5 - small ||e||
%   6 - Failed to converge
statusCode = struct('NoStop',               int32(0),...
                    'SmallGrad',            int32(1),...
                    'SmallIncreX',          int32(2),...
                    'MaxIters',             int32(3),...
                    'SmallRelDecreFunVal',  int32(4),...
                    'SmallAbsFunVal',       int32(5),...
                    'NoConverge',           int32(6));
                
% The variant of Levenberg-Marquardt is based on Sparse Bundle Adjustment
% (SBA) technical report by Lourakis and Argyros.

% Damping factors
v               = 2;
mu              = -inf;
tau             = 1e-3;
% Iteration counter
iter            = 0;
% Internal thresholds
gradTol         = 1e-12;
increTol        = 1e-12;
% Stopping flag
stopCondition   = statusCode.NoStop;
                        
jj = (repmat(eye(6), 1, numViews) > 0);
ii = (repmat(eye(3), 1, numPoints) > 0);

printer.printMessage('vision:sfm:sbaStart');

while (stopCondition == statusCode.NoStop)
    iter =  iter + 1;
    if iter > maxIterations
        stopCondition = statusCode.MaxIters;
        break;
    end
    
    printer.printMessageNoReturn('vision:sfm:sbaIteration', iter);

    % Compute derivative submatrices A_ij (w.r.t camera poses), B_ij (w.r.t points)
    [errors, Uj, Vi, Wij, eaj, ebi] = visionSBAAuxiliaryVariable(xyzPoints, ...
                measurements, cameraMatrices, quaternionBases, visibility, ...
                cameraParams, fixedCameraIndex);
       
    curMeanErr = errors(1,:).^2+errors(2,:).^2;
    if iter == 1
        initMeanErr = curMeanErr;
    end
    e1 = sum(curMeanErr);
    
    meanReprojError = e1 / numel(curMeanErr);
    printer.printMessage('vision:sfm:sbaMeanSquareError', num2str(meanReprojError));

    if ~isfinite(meanReprojError)
        stopCondition = statusCode.NoConverge;
        break;
    end
    
    if meanReprojError < absTol
        stopCondition = statusCode.SmallAbsFunVal;
        break;
    end
   
    g = [eaj(:); ebi(:)];
    g_inf = norm(g, Inf);
    p_L2 = norm([cameraMatrices(:); xyzPoints(:)]);
       
    if g_inf < gradTol
        stopCondition = statusCode.SmallGrad;
        break;
    end
    
    if iter == 1
        mu = max(mu,max(Uj(jj)));
        mu = max(mu,max(Vi(ii)));
        mu = tau * mu;
    end
    
    while true
         % Augment U, V with the increased damping factor
        Uj(jj) = Uj(jj) + mu;
        Vi(ii) = Vi(ii) + mu;
       
        [S, e, Vii] = visionSBASchurComplement(Uj, Vi, Wij, eaj, ebi, visibility);
        
        % Disable the warnings about conditioning for singular and
        % nearly singular matrices
        warningstate1 = warning('off','MATLAB:nearlySingularMatrix');
        warningstate2 = warning('off','MATLAB:singularMatrix');
        warningstate3 = warning('off','MATLAB:rankDeficientMatrix');

        % Solve for camera poses
        Xa = S \ e(:);

        % Restore the warning states to their original settings
        warning(warningstate1)
        warning(warningstate2)
        warning(warningstate3)
    
        % Solve for 3-D pints
        Xb = visionSBASolvePoints(Wij, Xa, Vii, ebi, visibility);
        
        delta = [Xa; Xb];

        if (norm(delta) <= increTol * p_L2)
            stopCondition = statusCode.SmallIncreX;
            break;
        end

        % Try update
        newCameraMatrices = cameraMatrices + reshape(Xa, 6, numViews);
        newXYZPoints = xyzPoints + reshape(Xb, 3, numPoints);

        % Evaluate function value
        newErrors = visionSBAAuxiliaryVariable(newXYZPoints, measurements, ...
            newCameraMatrices, quaternionBases, visibility, cameraParams, ...
            fixedCameraIndex);

        newMeanErr = newErrors(1,:).^2+newErrors(2,:).^2;
        e2 = sum(newMeanErr);
        dF = e1-e2;
        dL = (delta'*(mu*delta+g));
        
        if (dL > 0 && dF > 0)
            % Reduction in error, increment is accepted
            tmp = 2*dF/dL-1;
            tmp = 1-tmp^3;
            mu = mu * max(1/3, tmp);                                
            v = 2;
            
            if ((sqrt(e1)-sqrt(e2))^2 < relTol*e1)
                stopCondition = statusCode.SmallRelDecreFunVal;
            end

            cameraMatrices = newCameraMatrices;
            xyzPoints = newXYZPoints;
            break;
        else
            mu = mu*v;
            v2 = 2*v;
            if (v2 <= v) % v has wrapped around, too many failed attempts to increase the damping factor
                stopCondition = statusCode.NoConverge;
                break;
            end
            v = v2;
        end
    end 
end

cameraMatrices(1:3, :) = visionSBAUpdateRotationVector(quaternionBases, cameraMatrices(1:3, :));

switch stopCondition
    case statusCode.SmallGrad
        printer.printMessage('vision:sfm:sbaStopCondSmallGrad');
    case statusCode.SmallIncreX 
        printer.printMessage('vision:sfm:sbaStopCondSmallChangeOfX');
    case statusCode.MaxIters
        printer.printMessage('vision:sfm:sbaStopCondMaxIteration');
    case statusCode.SmallRelDecreFunVal
        printer.printMessage('vision:sfm:sbaStopCondSmallRelChangeOfFunVal');
    case statusCode.SmallAbsFunVal
        printer.printMessage('vision:sfm:sbaStopCondSmallAbsFunVal');
    case statusCode.NoConverge
        printer.printMessage('vision:sfm:sbaStopCondNotConverge');
end

finalMeanErr = errors(1,:).^2 + errors(2,:).^2;
printer.printMessage('vision:sfm:sbaReportInitialError', num2str(mean(sqrt(initMeanErr))));
printer.printMessage('vision:sfm:sbaReportFinalError', num2str(mean(sqrt(finalMeanErr))));

xyzRefinedPoints = cast(xyzPoints', returnPointType);
refinedPoses = cameraPoses;
for j = 1:numViews
    R = vision.internal.calibration.rodriguesVectorToMatrix(cameraMatrices(1:3, j));
    t = cameraMatrices(4:6, j)';
    refinedPoses.Location{j} = cast(-t*R, returnPoseType);
    refinedPoses.Orientation{j} = cast(R, returnPoseType);
end

reprojectionErrors = computeReprojectionError(finalMeanErr, visibility);
reprojectionErrors = cast(reprojectionErrors, returnPointType);

%==========================================================================
% Parameter validation and parsing
%==========================================================================
function [xyzPoints, pointTracks, cameraPoses, cameraParams, maxIterations, ...
    absTol, relTol, isUndistorted, verbose, fixedCameraIndex, returnType] = ...
    validateAndParseOptInputs(varargin)
    
% Set input parser
defaults = struct(...
    'MaxIterations', 50,...
    'AbsoluteTolerance', 1,...
    'RelativeTolerance', 1e-5,...
    'PointsUndistorted', false, ...
    'FixedViewIDs', [], ...
    'Verbose', false);

parser = inputParser;
parser.CaseSensitive = false;
parser.FunctionName = mfilename;

parser.addRequired('xyzPoints', @(x)validateattributes(x, {'single', 'double'}, ...
    {'finite', 'nonempty', 'nonsparse', 'real', 'size', [NaN, 3]}));
parser.addRequired('pointTracks', @(x)validateattributes(x, {'pointTrack'}, {'nonempty','vector'}));
parser.addRequired('cameraPoses', @validatePoses);
parser.addRequired('cameraParams', @checkCameraParameters);
% Optional parameters
parser.addParameter('MaxIterations', defaults.MaxIterations, ...
            @(x)validateattributes(x,{'single', 'double'}, {'scalar','integer','nonnegative'}));
parser.addParameter('AbsoluteTolerance', defaults.AbsoluteTolerance, ...
            @(x)validateattributes(x,{'single', 'double'}, {'real','nonnegative','scalar'}));
parser.addParameter('RelativeTolerance', defaults.RelativeTolerance, ...
            @(x)validateattributes(x,{'single', 'double'}, {'real','nonnegative','scalar'}));
parser.addParameter('PointsUndistorted', defaults.PointsUndistorted, ...
            @(x)vision.internal.inputValidation.validateLogical(x, 'PointsUndistorted'));
parser.addParameter('FixedViewIDs', defaults.FixedViewIDs, @validateFixedViewIDs);
parser.addParameter('Verbose', defaults.Verbose, ...
            @(x)vision.internal.inputValidation.validateLogical(x, 'Verbose'));

parser.parse(varargin{:});

xyzPoints     = double(parser.Results.xyzPoints)'; % Convert to 3-by-N double
pointTracks   = parser.Results.pointTracks;
cameraPoses   = parser.Results.cameraPoses;
cameraParams  = parser.Results.cameraParams;
maxIterations = parser.Results.MaxIterations;
absTol        = double(parser.Results.AbsoluteTolerance);
relTol        = double(parser.Results.RelativeTolerance);
isUndistorted = parser.Results.PointsUndistorted;
fixedViewIDs  = uint32(parser.Results.FixedViewIDs);
verbose       = parser.Results.Verbose;

% Check the size of input
if numel(pointTracks) ~= size(xyzPoints, 2)
    error(message('vision:sfm:unmatchedXYZTrack'));
end

% Check the fixed view ID
if ~isempty(fixedViewIDs)
    fixedCameraIndex = zeros(size(fixedViewIDs));
    for k = 1 : length(fixedViewIDs)
        idx = find(cameraPoses.ViewId == fixedViewIDs(k), 1, 'first');
        if ~isempty(idx)
            fixedCameraIndex(k) = idx;
        end
    end
else
    fixedCameraIndex = 0;
end

% Check the camera array
if ~isscalar(cameraParams) && numel(cameraParams) ~= height(cameraPoses)
    error(message('vision:sfm:unmatchedParamsPoses'));
end

returnType = class(parser.Results.xyzPoints);

%==========================================================================
% Convert inputs to internal data structure.
%
% measurements: 2-by-M packed 2-D points
% visibility(i,j): true if point i is visible in view j
% cameraMatrices: 6-by-V, rotation vector+ translation vector
% quaternionBases: 4-by-V, quaternions for initial rotations
% cameraParams: a structure of camera parameters
%
% Note, all returned values are double
%==========================================================================
function [measurements, visibility, cameraMatrices, quaternionBases, ...
    cameraParamStruct, returnType] = convertInputDataFormat(pointTracks, ...
    cameraPoses, cameraParams, isUndistorted)

numPoints = numel(pointTracks);
numViews = height(cameraPoses);

% visibility(i,j): true if point i is visible in view j
visibility = zeros(numPoints, numViews);
viewIds = cameraPoses.ViewId;
x = zeros(numPoints, numViews);
y = zeros(numPoints, numViews);
for m = 1:numPoints
    trackViewIds = pointTracks(m).ViewIds;
    for n = 1:length(trackViewIds)
        viewIndex = find(viewIds == trackViewIds(n), 1, 'first');
        if isempty(viewIndex)
            error(message('vision:absolutePoses:missingViewId', trackViewIds(n)));
        end
        visibility(m, viewIndex) = 1;
        x(m, viewIndex) =  pointTracks(m).Points(n, 1);
        y(m, viewIndex) =  pointTracks(m).Points(n, 2);
    end
end

isVisible = find(visibility);
x = x(isVisible);
y = y(isVisible);

visibility = sparse(visibility);
% measurements stores 2-D points in 1st view first, then 2nd view, ...
measurements = double([x, y])';

% Convert camera poses to a compact form of camera projection matrices
% Use quaternion for numerical stability
quaternionBases = zeros(4, numViews);
cameraMatrices = zeros(6, numViews);
for j = 1:numViews
    t = cameraPoses.Location{j};
    R = cameraPoses.Orientation{j};
    cameraMatrices(4:6, j) = -t*R';
    quaternionBases(:, j) = vision.internal.quaternion.rotationToQuaternion(R);
end

returnType = class(cameraPoses.Location{1});

if ~iscell(cameraParams)
    cameraParams = {cameraParams};
end

numCameras = length(cameraParams);
cameraParamStruct(numCameras) = struct('focalLength',[], ...
                                       'principalPoint', [], ...
                                       'radialDistortion', [], ...
                                       'tangentialDistortion', [], ...
                                       'skew', []);

for n = 1:numCameras
    % Convert the cameraParams object to a simple structure
    cameraParamStruct(n).focalLength = double(cameraParams{n}.FocalLength);
    cameraParamStruct(n).principalPoint = double(cameraParams{n}.PrincipalPoint);
    if ~isUndistorted
        % Skip if the distortion coefficients are all zeros
        if (any(cameraParams{n}.RadialDistortion) || any(cameraParams{n}.TangentialDistortion))
            cameraParamStruct(n).radialDistortion = double(cameraParams{n}.RadialDistortion);
            cameraParamStruct(n).tangentialDistortion = double(cameraParams{n}.TangentialDistortion);
        end
    end
    % Note, the internal reprojection function uses a different definition
    % of skew factor, i.e., s = S / fc(1)
    cameraParamStruct(n).skew = double(cameraParams{n}.Skew / cameraParams{n}.FocalLength(1));
end

%==========================================================================
% Compute the reprojection error for each 3-D point
%==========================================================================
function reprojectionErrors = computeReprojectionError(errors, visibility)
reprojectionErrors = zeros(size(visibility, 1), 1);
k = 1;
for n = 1:size(visibility, 1)
    nViews = sum(visibility(n, :));
    e = sqrt(errors(k : k + nViews - 1));
    reprojectionErrors(n) = sum(e) / numel(e);
    k = k + nViews;
end

%==========================================================================
% Validate Poses
%==========================================================================
function tf = validatePoses(value)
tf = true;
vision.internal.inputValidation.checkAbsolutePoses(value, mfilename, 'cameraPoses');

%==========================================================================
% Validate FixedViewIDs
%==========================================================================
function tf = validateFixedViewIDs(value)
tf = true;
if ~isempty(value)
    validateattributes(value,{'numeric'}, {'vector','integer','nonnegative'});
end

%==========================================================================
% Validate FixedViewIDs
%==========================================================================
function tf = checkCameraParameters(value)
tf = true;
if iscell(value)
    cellfun(@(x)validateattributes(x, {'cameraParameters','cameraIntrinsics'}, {}), value);
else
    validateattributes(value, {'cameraParameters','cameraIntrinsics'}, {});
end
