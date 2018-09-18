function layers = inferParametersGivenInputSize(layers, inputSize)
% local version of infer parameters that allows specifying an input size.


numLayers = numel(layers);
for i = 1:numLayers
    
    % Set default layer name if this is empty
    layers = iInferLayerName(layers, i);
    
    layers = iInferSize(layers, i, inputSize);
    inputSize = layers{i}.forwardPropagateSize(inputSize);
end

% Append a unique suffix to duplicate names
names = iGetLayerNames( layers );
names = iMakeUniqueStrings( names );
layers = iSetLayerNames( layers, names );

function str = iMakeUniqueStrings(str)
str = matlab.lang.makeUniqueStrings( str );

function names = iGetLayerNames(layers)
names = cellfun(@(layer)layer.Name, layers, 'UniformOutput', false);

function layers = iSetLayerNames(layers, names)
for i=1:numel(layers)
    layers{i}.Name = names{i};
end

function layers = iInferLayerName(layers, index)
% iInferLayerName   Assign a default name to the layer if its name is
% empty
if isempty(layers{index}.Name)
    layers{index}.Name = layers{index}.DefaultName;
end

function layers = iInferSize(layers, index, inputSize)
if(~layers{index}.HasSizeDetermined)
    % Infer layer size if its size is not determined
    try
        layers{index} = layers{index}.inferSize(inputSize);
    catch e
        throwWrongLayerSizeException( e, index );
    end
else
    % Otherwise make sure the size of the layer is correct
    iAssertCorrectSize( layers, index, inputSize );
end

function throwWrongLayerSizeException(e, index)
% throwWrongLayerSizeException   Throws a getReshapeDims:notSameNumel exception as
% a WrongLayerSize exception
if (strcmp(e.identifier,'MATLAB:getReshapeDims:notSameNumel'))
    exception = iCreateExceptionFromErrorID('nnet_cnn:inferParameters:WrongLayerSize', index);
    throwAsCaller(exception)
else
    rethrow(e)
end

function iAssertCorrectSize( layers, index, inputSize )
% iAssertCorrectSize   Check that layer size matches the input size,
% otherwise the architecture would be inconsistent.
if ~layers{index}.isValidInputSize( inputSize )
    exception = iCreateExceptionFromErrorID('nnet_cnn:inferParameters:WrongLayerSize', index);
    throwAsCaller(exception);
end

function exception = iCreateExceptionFromErrorID(errorID, varargin)
exception = MException(errorID, getString(message(errorID, varargin{:})));
