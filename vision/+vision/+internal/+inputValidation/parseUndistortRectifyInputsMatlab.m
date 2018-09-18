function [interp, outputView, fillValues] = ...
    parseUndistortRectifyInputsMatlab(functionName, I, outputViewValidator, varargin)
if strcmp(functionName, 'undistortImage')
    defaultOutputView = 'same';
else
    defaultOutputView = 'valid';
end

parser = inputParser();
parser.addOptional('interp', 'bilinear', @validateInterpMethod);
parser.addParameter('OutputView', defaultOutputView, @validateOutputView);
parser.addParameter('FillValues', 0);

parser.parse(varargin{:});
interp = vision.internal.inputValidation.validateInterp(parser.Results.interp);
outputView = outputViewValidator(parser.Results.OutputView);
vision.internal.inputValidation.validateFillValues(...
    parser.Results.FillValues, I);
fillValues = parser.Results.FillValues;

%--------------------------------------------------------------------------
    function TF = validateOutputView(outputView)
        validateattributes(outputView, {'char'}, {'vector'}, functionName, 'OutputView');
        TF = true;
    end

%--------------------------------------------------------------------------
    function tf = validateInterpMethod(method)
        vision.internal.inputValidation.validateInterp(method);
        tf = true;
    end
end