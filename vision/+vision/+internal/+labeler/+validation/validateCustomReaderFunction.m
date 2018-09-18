function validateCustomReaderFunction(readerFunctionHandle,sourceName,timestamps)
%validateCustomReaderFunction Validates Custom Reader Function. 
%Invokes custom reader function on the first timestamp and verifies the
%output. The custom reader function is expected to have the following
%signature

% img = readerFunctionHandle(sourceName, timestampScalar);

% The output, img must be a grayscale or color image.

% Copyright 2016 The MathWorks, Inc.

assert(isa(readerFunctionHandle,'function_handle') || ischar(sourceName) || ...
    isduration(timestamps),'Unexpected inputs');

try
    img = readerFunctionHandle(sourceName,timestamps(1));
catch ME
    throwAsCaller(ME);
end

% Validate image size (2-D or RGB only).
if ~((ismatrix(img) || (ndims(img)==3 && size(img,3) == 3)))
    error(message('vision:groundTruthDataSource:expected2DOrRGB'));
end

end
