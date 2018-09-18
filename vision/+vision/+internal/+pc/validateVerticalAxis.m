function varargout = validateVerticalAxis(filename, value)
% Validate 'VerticalAxis'

list = {'X', 'Y', 'Z'};
validateattributes(value, {'char'}, {'nonempty'}, filename, 'VerticalAxis');

str = validatestring(value, list, filename, 'VerticalAxis');

if nargout == 1
    varargout{1} = str;
end