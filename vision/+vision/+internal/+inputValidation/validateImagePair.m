function validateImagePair(I1, I2, varName1, varName2, varargin)
% validateImagePair Validate a pair of images. 
% Verifies that I1 and I2 are valid grayscale or RGB images, and that they 
% are same size and class

%#codegen
%#ok<*EMTC>

if isempty(coder.target)
    % use try/catch to throw error from calling function. This produces an
    % error stack that is better associated with the calling function.
    try 
        localValidate(I1, I2, varName1, varName2, varargin{:})
    catch E        
        throwAsCaller(E); % to produce nice error message from caller.
    end
else
    localValidate(I1, I2, varName1, varName2, varargin{:});
end

%--------------------------------------------------------------------------
function localValidate(I1, I2, varName1, varName2, varargin)

vision.internal.inputValidation.validateImage(I1, varName1, varargin{:});
vision.internal.inputValidation.validateImage(I2, varName2, varargin{:});

coder.internal.errorIf(~isequal(size(I1), size(I2)), ...
    'vision:dims:inputsMismatch');
    
coder.internal.errorIf(~isequal(class(I1), class(I2)), ...
    'vision:dims:inputsMismatch');