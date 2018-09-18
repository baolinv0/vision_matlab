function varargout = validateVerticalAxisDir(filename, value)
% Validate 'VerticalAxisDir'

list = {'Up', 'Down'};
validateattributes(value, {'char'}, {'nonempty'}, filename, 'VerticalAxisDir');

str = validatestring(value, list, filename, 'VerticalAxisDir');

if nargout == 1
    varargout{1} = str;
end
    
