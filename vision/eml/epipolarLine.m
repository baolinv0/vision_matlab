function lines = epipolarLine(f,pts)
% Compute epipolar lines for stereo images.

% Copyright 2010 The MathWorks, Inc.
%#codegen

coder.extrinsic('cvstGetCoordsChoice');

% Code below is only used by Simulink when the function is
% placed in the MATLAB Function block. Simulink first propagates
% the sizes followed by the types. The block of code below sets
% the sizes during the Simulink size propagation stage.
if eml_ambiguous_types
    lines = zeros(size(pts, 1), 3);
    return;
end

% Declare that the inputs are most likely constant in order to generate 
% more optimzed code.
eml_prefer_const(f, pts);

checkInputs(f, pts);

%--------------------------------------------------------------------------
% Computation
%--------------------------------------------------------------------------
outputClass = class(f);

  nPts = cast(size(pts, 1), 'int32');
  lines = coder.nullcopy([cast(pts, outputClass), ones(nPts, 1)] * f');

  for idx = 1: nPts
    for jdx = 1: 3
      lines(idx,jdx) = f(jdx,1) * cast(pts(idx,1), outputClass) ...
                     + f(jdx,2) * cast(pts(idx,2), outputClass) + f(jdx,3);
    end
  end
end

%========================================================================== 
function checkInputs(f, pts)
%--------------------------------------------------------------------------
% Check F
%--------------------------------------------------------------------------
eml_lib_assert(isfloat(f) && isreal(f) && ~issparse(f), ...
  'vision:epipolarLine:invalidFType', ...
  'Expected F to be floating point, real, and nonsparse.');

eml_lib_assert(ndims(f) == 2 && all(size(f) == [3, 3]), ...
  'vision:epipolarLine:invalidFSize', ...
  'Expected F to be a 3-by-3 matrix.');

%--------------------------------------------------------------------------
% Check PTS
%--------------------------------------------------------------------------
eml_lib_assert(isfloat(pts) || isinteger(pts), ...
  'vision:epipolarLine:invalidPtsClass', ...
  'Expected PTS to be double, single, or integer.');

eml_lib_assert(isreal(pts) && ~issparse(pts), ...
  'vision:epipolarLine:invalidPtsType', ...
  'Expected PTS to be real and nonsparse.');

  eml_lib_assert(ndims(pts)==2 && size(pts,1)>0 && size(pts,2)==2, ...
    'vision:epipolarLine:invalidPtsSize', ...
    'Expected PTS to be a M-by-2 matrix.');
end

