function [f, varargout] = estimateFundamentalMatrix(...
  matchedPoints1, matchedPoints2, varargin)
%estimateFundamentalMatrix Estimate fundamental matrix.
%   estimateFundamentalMatrix estimates the fundamental matrix from
%   corresponding points in stereo images. It can be configured to use all
%   corresponding points to compute the fundamental matrix, or to exclude
%   outliers by using a robust estimation technique such as RANSAC.
%
%   F = estimateFundamentalMatrix(matchedPoints1, matchedPoints2) returns
%   the 3-by-3 fundamental matrix, F, using the Least Median of Squares
%   (LMedS) method. matchedPoints1 and matchedPoints2 can be cornerPoints
%   objects, SURFPoints objects, KAZEPoints objects, MSERRegions objects,
%   BRISKPoints objects, or M-by-2 matrices of [x,y] coordinates.
%   matchedPoints1 and matchedPoints2 must contain points which are
%   putatively matched by using a function such as matchFeatures.
%  
%   [F, inliersIndex] =
%   estimateFundamentalMatrix(matchedPoints1, matchedPoints2) returns
%   logical indices, inliersIndex, for the inliers used to compute the
%   fundamental matrix. The inliersIndex output is a M-by-1 vector. Each
%   element of inliersIndex is true if the corresponding point was used to
%   compute the fundamental matrix, and false otherwise.
%  
%   [F, inliersIndex, status] =
%   estimateFundamentalMatrix(matchedPoints1, matchedPoints2) returns a
%   status code with the following possible values:
% 
%     0: No error. 
%     1: matchedPoints1 and matchedPoints2 do not contain enough points.
%        Norm8Point and MSAC require at least 8 points, and LMedS 16 points.
%     2: Not enough inliers found.
%  
%   [F, inliersIndex, status] = estimateFundamentalMatrix(..., Name, Value)
%   sets parameters for finding outliers and computing the fundamental
%   matrix. Name and value of the parameters are:
%  
%   'Method'             One of the strings: 'Norm8Point', 'LMedS', or 'MSAC'.
%                        Specify the method used to compute the fundamental
%                        matrix. To produce reliable results using
%                        'Norm8Point' algorithm, matchedPoints1 and
%                        matchedPoints2 must match precisely. The other
%                        methods can tolerate outliers and therefore only
%                        require putatively matched input points. You can
%                        obtain putatively matched points by using
%                        matchFeatures function.
% 
%                          'Norm8Point': Normalized Eight-Point algorithm
%                          'LMedS':      Least Median of Squares
%                          'MSAC':       M-estimator SAmple Consensus
%  
%                        Default: 'LMedS'
%  
%   'OutputClass'        One of the strings: 'double' or 'single'.
%                        Specifies the class for the fundamental matrix and
%                        for the internal computation.
% 
%                        Default: 'double'
%  
%   'NumTrials'          Positive integer scalar.
%                        Specifies the number of random trials for finding
%                        the outliers. This parameter applies when you set
%                        the Method parameter to 'LMedS' or'MSAC'. When you
%                        set the Method parameter to 'LMedS', the function 
%                        sets this parameter to the actual number of trials.
%                        When you set the Method parameter to 'MSAC', the 
%                        function sets this parameter to the maximum number
%                        of trials and the actual number of trials depends 
%                        on matchedPoints1, matchedPoints2, and the value of
%                        the Confidence parameter.
% 
%                        Default: 500
% 
%   'DistanceThreshold'  Positive scalar value.
%                        Specifies the Sampson distance threshold for finding
%                        outliers. This parameter applies when you set the
%                        Method parameter to 'MSAC'.
% 
%                        Default: 0.01
% 
%   'Confidence'         Scalar value greater than 0 and less than 100.
%                        Specifies the desired confidence (in percentage)
%                        for finding the maximum number of inliers. This
%                        parameter applies when you set the Method
%                        parameter to 'MSAC'.
%  
%                        Default: 99
%    
%   'ReportRuntimeError' true or false
%                        Set this parameter to true to report runtime
%                        errors when the function cannot compute the
%                        fundamental matrix from matchedPoints1 and
%                        matchedPoints2. When you set this parameter to
%                        false, you can check the status output to verify
%                        validity of the fundamental matrix.
%
%                        Default: true
%
%   Class Support
%   -------------
%   matchedPoints1 and matchedPoints2 must be cornerPoints objects,
%   SURFPoints objects, KAZEPoints objects, MSERRegions objects,
%   BRISKPoints objects, or M-by-2 matrices of [x,y] coordinates.
%
%   Example 1
%   ---------
%     % Use the Random Sample Consensus method to compute the fundamental
%     % matrix. This method requires that the input points are already 
%     % putatively matched, for example, by using matchFeatures function.
%     % Outliers which may still be contained within putatively matched
%     % points are further eliminated by using the RANSAC algorithm.     
%     load stereoPointPairs
%     fRANSAC=estimateFundamentalMatrix(matchedPoints1,matchedPoints2,...
%      'Method', 'MSAC', 'NumTrials', 2000, 'DistanceThreshold', 1e-2)
%  
%   Example 2
%   ---------
%     % Use the Least Median of Squares method to find inliers and to
%     % compute the fundamental matrix. We begin by loading putatively 
%     % matched points matchedPoints1, and matchedPoints2.
%     load stereoPointPairs
%     [fLMedS, inliers] = estimateFundamentalMatrix(...
%       matchedPoints1, matchedPoints2, 'NumTrials', 2000);
% 
%     % Load the stereo images.
%     I1 = imread('viprectification_deskLeft.png');
%     I2 = imread('viprectification_deskRight.png');
% 
%     % Show the putatively matched points.
%     figure;
%     showMatchedFeatures(I1, I2, matchedPoints1, matchedPoints2, ...
%                         'montage','PlotOptions',{'ro','go','y--'});
%     title('Putative point matches');
% 
%     % Show the inlier points.
%     figure;
%     showMatchedFeatures(I1, I2, matchedPoints1(inliers,:), ...
%                         matchedPoints2(inliers,:), ...
%                         'montage','PlotOptions',{'ro','go','y--'});
%     title('Point matches after outliers were removed');
%     
%   Example 3
%   ---------
%     % Use the Normalized Eight-Point algorithm to compute the fundamental
%     % matrix. This algorithm is only suitable for input points which do
%     % not contain any outliers.    
%     load stereoPointPairs
%     inlierPts1 = matchedPoints1(knownInliers, :);
%     inlierPts2 = matchedPoints2(knownInliers, :);
%     fNorm8Point = estimateFundamentalMatrix(inlierPts1, inlierPts2, ...
%       'Method', 'Norm8Point')
%
%   Example 4
%   ---------
%     % Automatically register and rectify stereo images. This example
%     % detects corners in stereo images, matches the corners, computes
%     % the fundamental matrix, and then rectifies the images. 
%     % <a href="matlab:web(fullfile(matlabroot,'toolbox','vision','visiondemos','html','UncalibratedStereoRectificationExample.html'))">View example</a>
%
% See also estimateEssentialMatrix, epipolarLine, extractFeatures, 
% matchFeatures, cameraPose, estimateUncalibratedRectification,
% detectSURFFeatures, detectMSERFeatures, detectHarrisFeatures,
% detectMinEigenFeatures, detectFASTFeatures, detectBRISKFeatures

% References:
%   [1] R. Hartley, A. Zisserman, "Multiple View Geometry in Computer
%       Vision," Cambridge University Press, 2003.
%   [2] P. Rousseeuw, A. Leroy, "Robust Regression and Outlier Detection,"
%       John Wiley & Sons, 1987.
%   [3] P. H. S. Torr and A. Zisserman, "MLESAC: A New Robust Estimator
%       with Application to Estimating Image Geometry," Computer Vision
%       and Image Understanding, 2000.

% Copyright 2009 The MathWorks, Inc.

% Note: The undocumented methods 'RANSAC' and 'LTS' and the 'DistanceType' 
% and 'InlierPercentage' parameters may be removed in a future release.
%
%   'DistanceType'       One of the strings: 'Algebraic' or 'Sampson'.
%                        Specifies the distance type to determine whether a
%                        pair of points is an inlier or outlier. This
%                        parameter applies when you set the Method
%                        parameter to 'LMedS', 'RANSAC', 'MSAC', or 'LTS'.
% 
%                        Default: Sampson
%  
%   'InlierPercentage'   Scalar value greater than 0 and less than 100.
%                        Specifies the minimum percentage of inliers in
%                        matchedPoints1 and matchedPoints2. This
%                        parameter applies when you set the Method
%                        parameter to 'LTS'.
% 
%                        Default: 50


%#codegen
%#ok<*EMCA>

% List of status code
statusCode = struct('NoError',           int32(0),...
                    'NotEnoughPts',      int32(1),...
                    'NotEnoughInliers',  int32(2));

% Parse and check inputs
[points1, points2, method, outputClass, distanceType, ...
 numTrials, distanceThreshold, confidence, inlierPercentage, ...
 reportRuntimeError] ...
 = parseInputs(matchedPoints1, matchedPoints2, varargin{:});

% Compute the fundamental matrix
[f, inliers, status] = estimateFundamentalMatrixAlg(...
  points1, points2, method, outputClass, numTrials, ...
  distanceType, distanceThreshold, confidence, inlierPercentage, ...
  statusCode);

if nargout >= 2
  varargout{1} = inliers;
  if nargout == 3
    varargout{2} = status;
  end
end

if reportRuntimeError
  % Report runtime error
  checkRuntimeStatus(statusCode, status);
end

%========================================================================== 
% Check runtime status and report error if there is one
%========================================================================== 
function checkRuntimeStatus(statusCode, status)
coder.internal.errorIf(status==statusCode.NotEnoughPts, ...
    'vision:points:notEnoughMatchedPts', 'matchedPoints1', ...
    'matchedPoints2', 8);

coder.internal.errorIf(status==statusCode.NotEnoughInliers, ...
    'vision:points:notEnoughInlierMatches', 'matchedPoints1', ...
    'matchedPoints2');

%==========================================================================
% Parse and check inputs
%========================================================================== 
function [points1, points2, method, outputClass, distanceType, ...
    numTrials, distanceThreshold, confidence, inlierPercentage, ...
    reportRuntimeError] = parseInputs(...
    matchedPoints1, matchedPoints2, varargin)

% Value of string enums. The first string is the default.
methodOptions = {'LMedS', 'LTS', 'RANSAC', 'MSAC', 'Norm8Point'}; 
classOptions = {'double', 'single'};
distanceOptions = {'Sampson', 'Algebraic'};

isSimulationMode = isempty(coder.target);
if isSimulationMode
    % Instantiate an input parser
    parser = inputParser;
    parser.FunctionName = 'estimateFundamentalMatrix';

    % Specify the optional parameters
    parser.addParameter('Method', 'LMedS');
    parser.addParameter('OutputClass', 'double');
    parser.addParameter('DistanceType', 'Sampson');
    parser.addParameter('NumTrials', 500);
    parser.addParameter('DistanceThreshold', 0.01);
    parser.addParameter('Confidence', 99);
    parser.addParameter('InlierPercentage', 50);
    parser.addParameter('ReportRuntimeError', true);

    % Parse and check optional parameters
    parser.parse(varargin{:});
    r = parser.Results;
    
    method = lower(r.Method);
    outputClass = lower(r.OutputClass);
    distanceType = lower(r.DistanceType);
    numTrials = r.NumTrials;
    distanceThreshold = r.DistanceThreshold;
    confidence = r.Confidence;
    inlierPercentage = r.InlierPercentage;
    reportRuntimeError = r.ReportRuntimeError;

else
    % Instantiate an input parser
    parms = struct( ...
      'Method',             uint32(0), ...
      'OutputClass',        uint32(0), ...
      'NumTrials',          uint32(0), ...
      'DistanceType',       uint32(0), ...
      'DistanceThreshold',  uint32(0), ...
      'Confidence',         uint32(0), ...
      'InlierPercentage',   uint32(0), ...
      'ReportRuntimeError', uint32(0));

    popt = struct( ...
      'CaseSensitivity', false, ...
      'StructExpand',    true, ...
      'PartialMatching', false);

    optarg               = eml_parse_parameter_inputs(parms, popt, ...
                           varargin{:});
    method             = eml_tolower(eml_const(eml_get_parameter_value(...
                           optarg.Method, 'LMedS', varargin{:})));
    outputClass        = eml_tolower(eml_const(eml_get_parameter_value( ...
                           optarg.OutputClass, 'double', varargin{:})));
    distanceType       = eml_tolower(eml_const(eml_get_parameter_value( ...
                           optarg.DistanceType, 'Sampson', varargin{:})));
    numTrials          = eml_get_parameter_value(optarg.NumTrials, ...
                           500, varargin{:});
    distanceThreshold  = eml_get_parameter_value(...
                           optarg.DistanceThreshold, 0.01, varargin{:});
    confidence         = eml_get_parameter_value(optarg.Confidence, 99,...
                           varargin{:});
    inlierPercentage   = eml_get_parameter_value(...
                           optarg.InlierPercentage, 50, varargin{:});
    reportRuntimeError = eml_const(eml_get_parameter_value(...
                           optarg.ReportRuntimeError, true, varargin{:}));
end

% Specify the optional parameters
checkMethodStrings(methodOptions, method);
checkOutputClassStrings(classOptions, outputClass);
checkDistanceTypeStrings(distanceOptions, distanceType);
checkNumTrials(numTrials, 'NumTrials');
checkThreshold(distanceThreshold, 'DistanceThreshold');
checkPercentage(confidence, 'Confidence');
checkPercentage(inlierPercentage, 'InlierPercentage');
checkReportRuntimeError(reportRuntimeError, 'ReportRuntimeError');

[points1, points2] = ...
    vision.internal.inputValidation.checkAndConvertMatchedPoints(matchedPoints1, ...
    matchedPoints2, mfilename, 'matchedPoints1', 'matchedPoints2');

%========================================================================== 
function r = checkNumTrials(value, name)
validateattributes(value, {'numeric'}, ...
  {'scalar', 'nonsparse', 'real', 'integer', 'positive', 'finite'},...
  'estimateFundamentalMatrix', name);
r = 1;

%========================================================================== 
function r = checkThreshold(value, name)
validateattributes(value, {'numeric'}, ...
  {'scalar', 'nonsparse', 'real', 'positive', 'finite'},...
  'estimateFundamentalMatrix', name);
r = 1;

%========================================================================== 
function r = checkPercentage(value, name)
validateattributes(value, {'numeric'}, ...
  {'scalar', 'nonsparse', 'real', 'positive', 'finite', '<', 100},...
  'estimateFundamentalMatrix', name);
r = 1;

%========================================================================== 
function r = checkReportRuntimeError(value, name)
validateattributes(value, {'logical', 'numeric'}, ...
  {'scalar', 'nonsparse', 'real'}, 'estimateFundamentalMatrix', name);
r = 1;

%========================================================================== 
function r = checkMethodStrings(list, value)
potentialMatch = validatestring(value, list, ...
  'estimateFundamentalMatrix', 'Method');
coder.internal.errorIf(~strcmpi(value, potentialMatch), ...
  'vision:estimateFundamentalMatrix:invalidMethodString');
r = 1;

%========================================================================== 
function r = checkOutputClassStrings(list, value)
potentialMatch = validatestring(value, list, ...
  'estimateFundamentalMatrix', 'OutputClass');
coder.internal.errorIf(~strcmpi(value, potentialMatch), ...
  'vision:estimateFundamentalMatrix:invalidOutputClassString');
r = 1;

%========================================================================== 
function r = checkDistanceTypeStrings(list, value)
potentialMatch = validatestring(value, list, ...
  'estimateFundamentalMatrix', 'DistanceType');
coder.internal.errorIf(~strcmpi(value, potentialMatch), ...
  'vision:estimateFundamentalMatrix:invalidDistanceTypeString');
r = 1;

%========================================================================== 
% Algorithm for computing the fundamental matrix.
%========================================================================== 
function [f, inliers, status] = estimateFundamentalMatrixAlg(...
  pts1, pts2, method, outputClass, numTrials, distanceType, ...
  distanceThreshold, confidence, inlierPercentage, statusCode)

%--------------------------------------------------------------------------
% Set default values for outputs and cast the class of the inputs
%--------------------------------------------------------------------------
integerClass = 'int32';
f = zeros([3, 3], outputClass);

conf = cast(confidence, outputClass) * cast(0.01, outputClass);
threshold = cast(distanceThreshold, outputClass);
nTrials = cast(numTrials, integerClass);

%--------------------------------------------------------------------------
% Check the size of pts1 and pts2
%--------------------------------------------------------------------------
nPts = cast(size(pts1, 1), integerClass);
inliers = false(nPts, 1);

%--------------------------------------------------------------------------
% Convert pts1 and pts2 to homogeneous coordinates by padding with ones.
%--------------------------------------------------------------------------
pts1h = coder.nullcopy(zeros(3, nPts, outputClass));
pts2h = coder.nullcopy(zeros(3, nPts, outputClass));
pts1h(3, :)   = 1;
pts2h(3, :)   = 1;

pts1h(1:2, :) = pts1';
pts2h(1:2, :) = pts2';

%--------------------------------------------------------------------------
% Compute the fundamental matrix and inliers based on selected method.
%--------------------------------------------------------------------------
if strcmp(method, 'norm8point')
  if nPts >= 8
    f = norm8Point(pts1h, pts2h, outputClass, integerClass);
    inliers(:) = true(1, nPts);
    status = statusCode.NoError;
  else
    status = statusCode.NotEnoughPts;
  end
else
  % Find the inliers in pts1 and pts2 (pts1h and pts2h).
  switch method
    case 'lmeds'
      [inliers(:), status] = lmeds(statusCode, distanceType,...
        outputClass, integerClass, pts1h, pts2h, nPts, nTrials);
    case 'lts'
      percent = cast(inlierPercentage,outputClass)*cast(0.01,outputClass);
      [inliers(:), status] = lts(statusCode, distanceType,...
        outputClass, integerClass, pts1h, pts2h, nPts, nTrials, percent);
    case 'ransac'
      [inliers(:), status] = ransac(statusCode, distanceType,...
        outputClass, integerClass, pts1h, pts2h, nPts, nTrials,...
        threshold, conf);
    otherwise % MSAC
      [inliers(:), status] = msac(statusCode, distanceType,...
        outputClass, pts1h, pts2h, nPts, nTrials,...
        threshold, conf);
  end

  % Compute the fundamental matrix from the inliers
  if status == statusCode.NoError
    f = norm8Point(pts1h(:, inliers), pts2h(:, inliers), outputClass,...
      integerClass);
  end
end

%========================================================================== 
% Find out inliers in the input data by using LMedS algorithm
%========================================================================== 
function [inliers, status] = lmeds(statusCode, disType, outputClass,...
  integerClass, pts1h, pts2h, nPts, nTrials)

inliers = false(1, nPts);
bestDis = realmax(outputClass);
bestF = coder.nullcopy(zeros([3, 3], outputClass));

if nPts >= 16
  for idx = 1: nTrials
    [d, f] = estTFormDistance(...
      disType, pts1h, pts2h, nPts, outputClass, integerClass);
    
    curDis = median(d);
    if bestDis > curDis
      bestDis = curDis;
      bestF = f;
    end
  end

  if bestDis < realmax(outputClass)
    d = computeDistance(disType, pts1h, pts2h, bestF);
    inliers = (d <= bestDis);
    status = statusCode.NoError;
  else
    status = statusCode.NotEnoughInliers;
  end
else
  status = statusCode.NotEnoughPts;
end

%========================================================================== 
% Find out inliers in the input data by using MSAC algorithm
%========================================================================== 
function [inliers, status] = msac(statusCode, disType, outputClass,...
  pts1h, pts2h, nPts, nTrials, threshold, confidence)

inliers = false(1, nPts);
if nPts >= 8
    
    ransacParams.maxNumTrials = nTrials;
    ransacParams.confidence = cast(confidence * 100, outputClass);
    ransacParams.maxDistance = threshold;
    ransacParams.sampleSize = 8;
    ransacParams.recomputeModelFromInliers = false;
    
    ransacFuncs.checkFunc = @checkTForm;
    ransacFuncs.fitFunc = @computeTForm;
    if strcmp(disType, 'sampson')
        ransacFuncs.evalFunc = @evaluateTFormSampson;
    else
        ransacFuncs.evalFunc = @evaluateTFormAlgebraic;
    end
    
    points = cast(cat(3, pts1h', pts2h'), outputClass);
    [isFound, ~, inliers] = vision.internal.ransac.msac(...
        points, ransacParams, ransacFuncs);
    
    if isFound 
        status = statusCode.NoError;
    else
        status = statusCode.NotEnoughInliers;
    end
else
    status = statusCode.NotEnoughPts;
end

%========================================================================== 
% Update the number of trials based on the desired confidence and the
% inlier ratio.
%========================================================================== 
function maxNTrials = updateNumTrials(oneOverNPts, logOneMinusConf, ...
  outputClass, integerClass, curNInliers, maxNTrials)

ratioOfInliers = cast(curNInliers, outputClass) * oneOverNPts;
if ratioOfInliers > cast(1, outputClass) - eps(outputClass)
  newNum = zeros(1, integerClass);
else
  ratio8 = ratioOfInliers^8;
  if ratio8 > eps(ones(1, outputClass))
    logOneMinusRatio8 = log(ones(1, outputClass) - ratio8);
    newNum = cast(ceil(logOneMinusConf / logOneMinusRatio8), integerClass);
  else
    newNum = intmax(integerClass);
  end
end

if maxNTrials > newNum
  maxNTrials = newNum;
end

%========================================================================== 
% Randomly select 8 points and compute the fundamental matrix.
%========================================================================== 
function [d, f] = estTFormDistance(disType, pts1h, pts2h, nPts,...
  outputClass, integerClass)

indices = cast(randperm(nPts, 8), integerClass);
f = norm8Point(pts1h(:, indices), pts2h(:, indices), outputClass,...
  integerClass);
d = computeDistance(disType, pts1h, pts2h, f);

%========================================================================== 
function F = computeTForm(points)
points1 = points(:,:,1)';
points2 = points(:,:,2)';
F = norm8Point(points1, points2, class(points), 'int32');

%========================================================================== 
function dis = evaluateTFormAlgebraic(F, points)
points1 = points(:, :, 1)';
points2 = points(:, :, 2)';
dis = computeDistance('algebraic', points1, points2, F)';

%========================================================================== 
function dis = evaluateTFormSampson(F, points)
points1 = points(:, :, 1)';
points2 = points(:, :, 2)';
dis = computeDistance('sampson', points1, points2, F)';

%==========================================================================
function tf = checkTForm(tform)
tf = all(isfinite(tform(:)));

%========================================================================== 
% Function norm8Point computes the fundamental matrix using THE NORMALIZED
% 8-POINT ALGORITHM as described in page 281 of the following reference:
%   R. Hartley, A. Zisserman, "Multiple View Geometry in Computer Vision," 
%   Cambridge University Press, 2003.
%========================================================================== 
function f = norm8Point(pts1h, pts2h, outputClass, integerClass)
% Normalize the points
num = cast(size(pts1h, 2), integerClass);
[pts1h, t1] = vision.internal.normalizePoints(pts1h, 2, outputClass);
[pts2h, t2] = vision.internal.normalizePoints(pts2h, 2, outputClass);

% Compute the constraint matrix
m = coder.nullcopy(zeros(num, 9, outputClass));
for idx = 1: num
  m(idx,:) = [...
    pts1h(1,idx)*pts2h(1,idx), pts1h(2,idx)*pts2h(1,idx), pts2h(1,idx), ...
    pts1h(1,idx)*pts2h(2,idx), pts1h(2,idx)*pts2h(2,idx), pts2h(2,idx), ...
                 pts1h(1,idx),              pts1h(2,idx), 1];
end

% Find out the eigen-vector corresponding to the smallest eigen-value.
[~, ~, vm] = svd(m, 0);
f = reshape(vm(:, end), 3, 3)';

% Enforce rank-2 constraint
[u, s, v] = svd(f);
s(end) = 0;
f = u * s * v';

% Transform the fundamental matrix back to its original scale.
f = t2' * f * t1;

% Normalize the fundamental matrix.
f = f / norm(f);
if f(end) < 0
  f = -f;
end

%========================================================================== 
% Find out the point pairs whose distances are less than the threshold.
%========================================================================== 
function [inliers, nInliers] = findInliers(distance, nPts, threshold)
inliers = distance <= threshold;
nInliers = cast(sum(inliers), 'like', nPts);

%========================================================================== 
% Compute the distance of points according to a fundamental matrix.
%========================================================================== 
function d = computeDistance(disType, pts1h, pts2h, f)
pfp = (pts2h' * f)';
pfp = pfp .* pts1h;
d = sum(pfp, 1) .^ 2;

if strcmp(disType, 'sampson')
  epl1 = f * pts1h;
  epl2 = f' * pts2h;
  d = d ./ (epl1(1,:).^2 + epl1(2,:).^2 + epl2(1,:).^2 + epl2(2,:).^2);
end

%========================================================================== 
% Find out inliers in the input data by using LTS algorithm
% Note: this methods for estimating the fundamental matrix 
% may be removed in future release.
%========================================================================== 
function [inliers, status] = lts(statusCode, disType, outputClass,...
  integerClass, pts1h, pts2h, nPts, nTrials, inlierPercentage)

inliers = false(1, nPts);
bestDis = realmax(outputClass);
bestF = coder.nullcopy(zeros([3, 3], outputClass));

idxDis = cast(floor(inlierPercentage * cast(nPts, outputClass)),...
  integerClass);

if idxDis >= 8
  for idx = 1: nTrials
    [d, f] = estTFormDistance(...
      disType, pts1h, pts2h, nPts, outputClass, integerClass);
    
    d = sort(d, 'ascend');
    curDis = d(idxDis);
    if bestDis > curDis
      bestDis = curDis;
      bestF = f;
    end
  end

  if bestDis < realmax(outputClass)
    d = computeDistance(disType, pts1h, pts2h, bestF);
    inliers = (d <= bestDis);
    status = statusCode.NoError;
  else
    status = statusCode.NotEnoughInliers;
  end
else
  status = statusCode.NotEnoughPts;
end

%========================================================================== 
% Find out inliers in the input data by using RANSAC algorithm
% Note: this methods for estimating the fundamental matrix 
% may be removed in future release.
%========================================================================== 
function [inliers, status] = ransac(statusCode, disType, outputClass,...
  integerClass, pts1h, pts2h, nPts, nTrials, threshold, confidence)

inliers = false(1, nPts);
if nPts >= 8
  maxNTrials = nTrials;
  curNTrials = zeros(1, integerClass);
  bestNInliers = zeros(1, integerClass);
  logOneMinusConf = log(ones(1, outputClass) - confidence);
  oneOverNPts = ones(1, outputClass) / cast(nPts, outputClass);
  
  while curNTrials < maxNTrials
    d = estTFormDistance(disType, pts1h, pts2h, nPts, outputClass,...
      integerClass);
    
    [curInliers, curNInliers] = findInliers(d, nPts, threshold);
    
    if bestNInliers < curNInliers
      bestNInliers = curNInliers;
      inliers = curInliers;
      
      % Update the number of trials
      maxNTrials = updateNumTrials(oneOverNPts, logOneMinusConf, ...
        outputClass, integerClass, curNInliers, maxNTrials);
    end
    curNTrials = curNTrials + 1;
  end
  
  if bestNInliers >= 8
    status = statusCode.NoError;
  else
    status = statusCode.NotEnoughInliers;
  end
else
  status = statusCode.NotEnoughPts;
end

