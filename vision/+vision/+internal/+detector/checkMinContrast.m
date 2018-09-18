function tf = checkMinContrast(x)
% validates MinContrast parameter value

%#codegen
%#ok<*EMCA>

vision.internal.errorIfNotFixedSize(x, 'MinContrast');

validateattributes(x, {'double', 'single'}, ...
    {'nonempty', 'nonnan', 'nonsparse', 'real', 'scalar', '>',0, '<',1},...
    'checkMinContrast', 'MinContrast');
tf = true;
