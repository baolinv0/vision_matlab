function B = blackimage(varargin)
%BLACKIMAGE Return black image of desired size and data type.
%    BLACKIMAGE(SIZE,DTYPE) specifies numeric vector SIZE describing the
%    dimensions of the desired image, and DTYPE specifies a string
%    describing the desired data type of the image, either 'double', 
%    'single', 'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', 
%    'int64', 'uint64', or 'logical'.
%
%    Typical dimensions are [R C] for a 2-D intensity image, and 
%    [R C 3] for an RGB color image, where R and C are the row and column
%    dimensions of the desired image.  DTYPE may be the name of any
%    numeric data type supported for images.
%
%    BLACKIMAGE(I) produces a black image of the same size and data type
%    as image I.
%
%    Class Support
%    -------------
%    SIZE must be a real, nonsparse numeric vector. DTYPE must be a string.
%    I can be any nonsparse, numeric matrix.
%
%    See also ZEROS, CHECKERBOARD, GETIMAGE.

%    Copyright 2004-2006 The MathWorks, Inc.

[dims,dtype,errmsg] = parseArgs(varargin{:});
if ~isempty(errmsg)
    error(message('vision:blackimage:invalidInput', errmsg));
end
B = createBlackImage(dims,dtype);

% ----------------------------------------
function B = createBlackImage(dims,dtype)
% Return image of proper dimensions and datatype,
% filled with values representing the "black" color

switch dtype
    case {'uint8','int8','uint16','int16','uint32','int32','uint64','int64'}
        B = intmin(dtype);
    case 'logical'
        B = false;
    otherwise
        % Presumably, {'double','single'}, but other numeric types allowed
        % This is *expected* to error-out for unsupported types
        try
            B = zeros(1,dtype);
        catch
            error(message('vision:blackimage:invalidImageDType', dtype));
        end
end
B = repmat(B,dims);

% ----------------------------------------
function [dims,dtype,errmsg] = parseArgs(varargin)
% Determine desired size and datatype
% Return in a struct with fields
%   .errmsg: if an error occurs, a non-empty string is return
%            containing the error message
%  
% Valid syntax:
%    BLACKIMAGE(SIZE,DTYPE) specifies the size SIZE as [R,C] or [R,C,P]
%    BLACKIMAGE(I) takes SIZE and DTYPE from image I.

dtype  = '';
errmsg = '';

% Check for incorrect number of arguments
narginchk(1,2);

if nargin==2
    % SIZE, DTYPE specified
    
    % Parse size
    dims = varargin{1};
    if ~isvector(dims) || ~isnumeric(dims) || ~isreal(dims) || issparse(dims)
        errmsg='SIZE must be a real vector of image dimensions';
        return
    end
    dims = double(dims);  % convert to doubles
    
    % Parse datatype
    dtype = varargin{2};
    if ~ischar(dtype)
        errmsg = 'DTYPE must be a string specifying a numeric data type';
        return
    end
else
    % Image specified
    dims = size(varargin{1});
    dtype = class(varargin{1});
end

