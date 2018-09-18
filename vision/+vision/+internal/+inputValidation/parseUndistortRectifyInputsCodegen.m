%#codegen
function [interp, outputView, fillValues] = ...
    parseUndistortRectifyInputsCodegen(I, functionName, defaultOutputView, varargin)
if ~isempty(varargin)
    [interp, firstArg] = parseInterpCodegen(varargin{1});
    
    params = struct( ...
        'OutputView', uint32(0), ...
        'FillValues', uint32(0));
    
    popt = struct( ...
        'CaseSensitivity', false, ...
        'StructExpand',    true, ...
        'PartialMatching', true);
    
    optarg = eml_parse_parameter_inputs(params, popt, varargin{firstArg:end});
    outputViewTmp = eml_get_parameter_value(optarg.OutputView, defaultOutputView, ...
        varargin{firstArg:end});
    fillValues = eml_get_parameter_value(optarg.FillValues, getDefaultFillValues(), ...
        varargin{firstArg:end});
    
    % interp
    % Case-insensitivity of interp is handled by
    % images.internal.coder.interp2d or imwarp. If we handle it here, then
    % interp will not be a compile-time constant, which will cause an
    % error.
    vision.internal.inputValidation.validateInterp(interp);
    
    % OutputView    
    validateattributes(outputViewTmp, {'char'}, {'vector'}, functionName, 'OutputView'); %#ok<EMCA>
    if strcmp(functionName, 'rectifyStereoImages')
        outputView = validatestring(outputViewTmp, {'full', 'valid'}, functionName, 'OutputView'); %#ok<EMCA>
    else
        outputView = validatestring(outputViewTmp, {'full', 'valid', 'same'}, functionName, 'OutputView'); %#ok<EMCA>
    end
        
    % FillValues
    vision.internal.inputValidation.validateFillValues(fillValues, I);
else
    interp = getDefaultInterp();
    outputView = defaultOutputView;
    fillValues = getDefaultFillValues();
end

%--------------------------------------------------------------------------
function interp = getDefaultInterp()
interp = 'bilinear';

%--------------------------------------------------------------------------
function fillValues = getDefaultFillValues()
fillValues = 0;

%--------------------------------------------------------------------------
function [interp, firstArg] = parseInterpCodegen(interpTmp)
if strcmpi(interpTmp, 'OutputView') || strcmpi(interpTmp, 'FillValues')
    firstArg = 1;
    interp = getDefaultInterp();
else
    interp = interpTmp;
    firstArg = 2;
end
