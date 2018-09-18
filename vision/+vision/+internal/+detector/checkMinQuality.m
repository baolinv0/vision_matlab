function tf = checkMinQuality(x)
% validates MinQuality parameter value. 

%#codegen
%#ok<*EMCA>

vision.internal.errorIfNotFixedSize(x,'MinQuality');

validateattributes(x,{'double','single'},...
    {'nonempty', 'nonnan', 'nonsparse', 'real', 'scalar', '>=', 0, '<=', 1},...
    'checkMinQuality','MinQuality');

tf = true;