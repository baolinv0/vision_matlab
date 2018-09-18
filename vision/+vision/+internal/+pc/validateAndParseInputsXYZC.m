function [X, Y, Z, C] = validateAndParseInputsXYZC(filename, varargin)
% Validate and parse points and colors

if isa(varargin{1}, 'pointCloud')
    % Retrieve the regular parameters
    ptCloud = varargin{1};
    xyzPoints = ptCloud.Location;
    C = ptCloud.Color;
elseif (ischar(varargin{1}) || isstring(varargin{1}))
    ptCloud = pcread(varargin{1});
    xyzPoints = ptCloud.Location;
    C = ptCloud.Color;    
else
    if ismatrix(varargin{1})
        xyzPoints = varargin{1};
        validateattributes(xyzPoints,{'numeric'}, {'real','ncols',3},filename,'xyzPoints');
    else
        xyzPoints = varargin{1};
        validateattributes(xyzPoints,{'numeric'}, {'real','size',[NaN,NaN,3]},filename,'xyzPoints');    
    end
    
    if nargin > 2
        C = varargin{2};
        validateattributes(C,{'numeric', 'char'}, {'nonempty','nonsparse','real'});
    else
        C = [];
    end
    
    % Check the color input
    if ~isempty(C)
        if ischar(C)
            validateattributes(C,{'char'}, {'nonempty'}, filename, 'C', 2);
        elseif numel(C) == 3
            validateattributes(C,{'numeric'}, {'real','ncols',3}, filename, 'C', 2);
        else
            if ismatrix(xyzPoints)
                if isvector(C)
                    validateattributes(C,{'numeric'}, {'real'}, filename, 'C', 2);
                    if numel(C) ~= size(xyzPoints,1)
                        error(message('vision:pointcloud:unmatchedXYZC'));
                    end
                else
                    validateattributes(C,{'numeric'}, {'real','size',[NaN,3]}, filename, 'C', 2);
                    if size(C, 1) ~= size(xyzPoints, 1)
                        error(message('vision:pointcloud:unmatchedXYZC'));
                    end
                end
            else
                if ismatrix(C)
                    validateattributes(C,{'numeric'}, {'real'}, filename, 'C', 2);
                else
                    validateattributes(C,{'numeric'}, {'real','size',[NaN,NaN,3]}, filename, 'C', 2);
                end
                if (size(C, 1) ~= size(xyzPoints, 1) || size(C, 2) ~= size(xyzPoints, 2))
                    error(message('vision:pointcloud:unmatchedXYZC'));
                end
            end
        end
    end
    
end

if ismatrix(xyzPoints)
    X = xyzPoints(:, 1);
    Y = xyzPoints(:, 2);
    Z = xyzPoints(:, 3);
else
    X = reshape(xyzPoints(:,:,1), [], 1);
    Y = reshape(xyzPoints(:,:,2), [], 1);
    Z = reshape(xyzPoints(:,:,3), [], 1);
    if ndims(C) == 3
        C = reshape(C, [], 3);
    elseif ~isvector(C)
        C = C(:);
    end
end

% Convert to double precision, rescaling the data if necessary
if (size(C, 2) == 3 && isnumeric(C))
    C = im2double(C);
end

end