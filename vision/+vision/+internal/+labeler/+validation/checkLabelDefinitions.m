function labelDefs = checkLabelDefinitions(labelDefs)

% labelDefs must be a table with 2 or 4 columns.
validateattributes(labelDefs, {'table'}, {'nonempty'}, 'groundTruth', 'LabelDefinitions');

numWidth = width(labelDefs);
if numWidth==2 || numWidth==3 || numWidth==4
      
    % Determine if label def table has one pixel label type.
    type = labelDefs{:,2};
    if all(isa(type, 'labelType'))
        hasPixelLabelType = any(type == labelType.PixelLabel);
    else
        error(message('vision:groundTruth:labelDefsMissingType'));
    end
    
    if hasPixelLabelType && numWidth < 3
        % Need 3 columns there are pixel labels.
        error(message('vision:groundTruth:labelDefsMissingPixelLabelID'));
    end
    
    % Check each label defintion row.
    TF = rowfun(@(varargin)validateLabelDefEntry(hasPixelLabelType, varargin{:} ), labelDefs,...
        'OutputFormat', 'uniform', 'ExtractCellContents', true, ...
        'NumOutputs', width(labelDefs));
    
    if ~all(TF(:,1))
        error(message('vision:groundTruth:labelDefsInvalidLabelNames'))
    end
    
    if ~all(TF(:,2))
        error(message('vision:groundTruth:labelDefsInvalidLabelType'))
    end
    
    if hasPixelLabelType && numWidth == 3 && ~all(TF(:,3))
        error(message('vision:groundTruth:labelDefsInvalidPixelLabelID'))
    end
    
    if ~hasPixelLabelType && numWidth==3 && ~all(TF(:,3))
        error(message('vision:groundTruth:labelDefsInvalidLabelDesc'))
    end
    
    if ~hasPixelLabelType && numWidth==4
        error(message('vision:groundTruth:invalidLabelDefinitionColumnsPixelLabel'))
    end
    
    if hasPixelLabelType && numWidth==4 && ~all(TF(:,4))
        error(message('vision:groundTruth:labelDefsInvalidLabelDesc'))
    end
    
    if hasPixelLabelType
        % Verify all PixelLabelID are either columns or M-by-3 matrices.
        
        % Check PixelLabelID is packed in a cell.
        if ~iscell(labelDefs{:,3})
            error(message('vision:groundTruth:invalidPixelLabelNotCell'));
        end
        
        % Remove empties first.
        nonEmptyPixelLabelID = cellfun(@(x)~isempty(x), labelDefs{:,3});
        defs = labelDefs{nonEmptyPixelLabelID, 3};
        
        % Check that all values have the same format.
        areColumnVecs = cellfun(@(x)iscolumn(x), defs);
        areMatrices   = cellfun(@(x)ismatrix(x) && size(x,2)==3, defs);
  
        if ~(all(areColumnVecs)  || all(areMatrices))
            error(message('vision:groundTruth:labelDefsAllColumnsNotSameFormat'));
        end
        
        % verify IDs are not shared by multiple classes.
        x = vertcat(defs{:});
        c = unique(x, 'rows');
        if size(x,1) ~= size(c,1)
            error(message('vision:groundTruth:labelDefsDuplicateIDs'));
        end
    end
else
    error(message('vision:groundTruth:invalidLabelDefinitionColumns'))
end

[~, uniqueIdx] = unique(labelDefs(:,1));
if numel(uniqueIdx) < height(labelDefs)
    error(message('vision:groundTruth:labelDefsNotUnique'))
end

% Rename variables in case different names were specified.
if numWidth == 2
    labelDefs.Properties.VariableNames = {'Name', 'Type'};
elseif numWidth == 3 && hasPixelLabelType
    labelDefs.Properties.VariableNames = {'Name', 'Type', 'PixelLabelID'};
elseif numWidth == 3 && ~hasPixelLabelType
    labelDefs.Properties.VariableNames = {'Name', 'Type', 'Description'};
elseif numWidth == 4
    labelDefs.Properties.VariableNames = {'Name', 'Type', 'PixelLabelID', 'Description'};
end

% Check if any Name is 'PixelLabelData'. This is reserved for
% all pixel label types.
if ismember('PixelLabelData', labelDefs{:,1})
    error(message('vision:groundTruth:pixelLabelDataInvalidName'));
end

end



function varargout = validateLabelDefEntry(hasPixelLabelType, varargin)

% Name must be a valid variable name
varargout{1} = isvarname(varargin{1});
    
% Type must be an enumeration of type labelType
varargout{2} = isa(varargin{2}, 'labelType') && isscalar(varargin{2});

if hasPixelLabelType
    % What type is the current row.
    isPixelLabelType = varargin{2} == labelType.PixelLabel;
    
    id = varargin{3};
    if isPixelLabelType
        varargout{3} = isValidPixelLabelID(id);
    else
        % non-PixelLabel types must have an []
        varargout{3} = isnumeric(id) && isempty(id);
    end
end

if (~hasPixelLabelType && nargin == 4) || (hasPixelLabelType && nargin == 5)
    varargout{nargin-1} = isValidDescription(varargin{nargin-1});
end
end

function TF = isValidDescription(in)
TF = ischar(in) && (isempty(in) || ismatrix(in));
end

function TF = isValidPixelLabelID(id)
try
    % valid PixelLabelID is a column vector or matrix that is M-by-3
    % (RGB triplet maps to label category)
    validateattributes(id, {'numeric'}, {'integer', 'real', 'finite', 'nonsparse', '>=', 0, '<=', 255});
    TF = iscolumn(id) || (ismatrix(id) && size(id,2) == 3);
catch
    TF = false;
end
end