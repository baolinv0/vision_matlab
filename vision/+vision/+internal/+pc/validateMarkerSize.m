function validateMarkerSize(filename, value)
% Validate 'MarkerSize'

validateattributes(value, {'numeric'}, {'nonempty', 'nonnan', ...
    'finite', 'nonsparse', 'real', 'scalar', '>', 0}, filename, 'MarkerSize');
