function outputType = checkAbsolutePoses(absPoses, filename, varname)
%checkAbsolutePoses Check validity of a table containing absolute camera poses
%  outputType = checkAbsolutePoses(absPoses, fileName, varName) checks that
%  the absPoses table contains the required  columns, and that all elements
%  are valid. Also checks that all orientations and locations are of the
%  same class, and returns that class.
%
%  See also triangulateMultiview, bundleAdjustment, viewSet

% Copyright 2015 Mathworks, Inc.

validator = vision.internal.inputValidation.TableValidator;
validator.RequiredVariableNames = {'ViewId', 'Orientation', 'Location'};
validator.MinRows = 2;

validator.ValidationFunctions('ViewId')      = @checkViewId;
validator.ValidationFunctions('Orientation') = @checkOrientation;   
validator.ValidationFunctions('Location')    = @checkLocation;

validator.validate(absPoses, filename, varname);

outputType = class(absPoses{1, 'Orientation'}{1});

for j = 1:size(absPoses, 1)
    R = absPoses{j, 'Orientation'}{1};
    t = absPoses{j, 'Location'}{1};
    if ~isa(R, outputType) || ~isa(t, outputType)
        error(message('vision:absolutePoses:locationsOrientationsSameType'));
    end    
end

    %----------------------------------------------------------------------
    function checkViewId(viewId)
        validateattributes(viewId, {'uint32'}, {'scalar'}, filename, 'ViewId');
    end

    %----------------------------------------------------------------------
    function checkOrientation(R)
        vision.internal.inputValidation.validateRotationMatrix(...
            R, filename, 'Orientation');
    end

    %----------------------------------------------------------------------
    function checkLocation(T)
        vision.internal.inputValidation.validateTranslationVector(...
            T, filename, 'Location');
    end
end
