function checkPoints(pointsIn, fileName, varName, allowGPUArrays)
% Checks if points are valid. Allows points to be any numeric type.

%#codegen
%#ok<*EMCA>

if nargin ~= 4
    allowGPUArrays = false;
end

coder.internal.errorIf( ~isnumeric(pointsIn)...
    && ~vision.internal.inputValidation.isValidPointObj(pointsIn), ...
    'vision:points:ptsClassInvalid', varName);

if isnumeric(pointsIn)
    checkPts(pointsIn, fileName, varName, allowGPUArrays);    
else         
    checkPointObject(pointsIn, fileName, varName, allowGPUArrays);      
end

%--------------------------------------------------------------------------
function checkPts(value, fileName, varName, allowGPUArrays)

if allowGPUArrays && isa(value, 'gpuArray')
    checkPtsGPU(value, fileName, varName);
else
    checkBuiltinPts(value, fileName, varName);
end

%--------------------------------------------------------------------------
function checkPointObject(value, fileName, varName, allowGPUArrays)

if isa(value.Location,'gpuArray')    
    if allowGPUArrays
        checkPtsGPU(value.Location,fileName, varName);
    else
        str = class(value);
        cmd = sprintf('<a href="matlab:help %s/gather">gather</a>',str);
        error(message('vision:points:gpuArrayNotSupportedForPtObj',str,cmd));
    end
else
    checkBuiltinPts(value.Location,fileName, varName);
end


%--------------------------------------------------------------------------
function checkBuiltinPts(value, fileName, varName)
validateattributes(value, {'numeric'}, ...
    {'2d', 'nonsparse', 'real', 'size', [NaN, 2]}, fileName, varName);

%--------------------------------------------------------------------------
function checkPtsGPU(value, fileName, varName)
hValidateAttributes(value, {'numeric'}, ...
    {'2d', 'real'}, fileName, varName);

% size
if size(value, 2) ~= 2
    validateattributes(ones(1,3),{'numeric'},{'size',[NaN, 2]}, fileName, varName);
end
