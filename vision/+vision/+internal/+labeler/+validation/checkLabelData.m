function labelData = checkLabelData(labelData, dataSource, labelDefs)

% labelData must be a table/timetable with as many rows as
% there are time stamps and as many columns as there are label
% definitions when label definitions has no pixel label types. When pixel
% label types are present the are all grouped into 1 column.
%

% If dataSource is empty, just check for columns.
types = labelDefs{:,2};
isPixelLabel = types == labelType.PixelLabel;
if any(isPixelLabel)
    numLabelDefs = height(labelDefs) - sum(isPixelLabel) + 1;
else
    numLabelDefs = height(labelDefs);
end

if isempty(dataSource)
    validateattributes(labelData, {'table', 'timetable'}, {'nonempty', 'ncols', numLabelDefs}, 'groundTruth', 'LabelData');
else
    if hasTimeStamps(dataSource)
        numTimes = numel(dataSource.TimeStamps);
        allowedLabelDataClass = {'table', 'timetable'};
        
        if any(isPixelLabel)
            error(message('vision:groundTruth:pixelLabelsNotSupportWithTimeStamps'));
        end
    else
        numTimes = numel(dataSource.Source);
        allowedLabelDataClass = {'table'};
    end
    validateattributes(labelData, allowedLabelDataClass, {'nonempty', 'ncols', numLabelDefs, 'nrows', numTimes}, 'groundTruth', 'LabelData');
end

% Variables in labelData must correspond to label definitions
    
dataNames = labelData.Properties.VariableNames;
defNames  = labelDefs.Name;

if any(isPixelLabel)
    % Verify label data table has only one PixelLabelData column.
    pxData = strcmp(dataNames, 'PixelLabelData');
    if ~any(pxData) || sum(pxData) > 1
        error(message('vision:groundTruth:labelDataMissingPixelLabelData'))
    end
    
    % Remove pixel label data before checking other types.
    dataNames(pxData) = [];
    defNames(isPixelLabel) = [];
end

if ~isempty(setdiff(dataNames, defNames))
    error(message('vision:groundTruth:inconsistentLabelDefNames'))
end

% Validate each entry of the label table.
for n = 1 : width(labelData)
    name = labelData.Properties.VariableNames{n};
    if strcmp(name, 'PixelLabelData')
        type = labelType.PixelLabel;
    else
        type = labelDefs.Type(strcmpi(labelDefs.Name,name));
    end
    data = labelData.(name);
    switch type
        case labelType.Rectangle
            % If there is only 1 rectangle at each time stamp, the table
            % returns a numTimes-by-4 matrix instead of a numTimes-by-1
            % cell array with 1-by-4 matrices at each element. Convert it
            % to a cell array of the right dimensions.
            if ~iscell(data)
                data = num2cell(data, 2);
                labelData.(name) = data;
            end
            
            TF = cellfun(@(x)validateRectangleData(x), data);
            if ~all(TF)
                error(message('vision:groundTruth:badRectData',name))
            end
            
        case labelType.Line
            if ~iscell(data)
                error(message('vision:groundTruth:badLineData',name))
            end
            % If each time stamp has 1 line, the table returns a
            % numTimes-by-1 cell array with each element being a M-by-2
            % matrix, instead of a M-by-1 cell array. Convert it to a cell
            % array of cell arrays.
            if all(cellfun(@(x)~isempty(x) && ~iscell(x),data))
                data = num2cell(data);
                labelData.(name) = data;
            end
            
            TF = cellfun(@(x)validateLineData(x), data);
            if ~all(TF)
                error(message('vision:groundTruth:badLineData',name))
            end
        case labelType.Scene
            if iscell(data)
                error(message('vision:groundTruth:badSceneData',name))
            end
            TF = islogical(data);
            if ~all(TF)
                error(message('vision:groundTruth:badSceneData',name))
            end
        case labelType.PixelLabel
            if ~iscell(data)
                error(message('vision:groundTruth:badPixelLabelData', name));
            end
            
            TF = cellfun(@(x)validatePixelLabelData(x), data);
            if ~all(TF)
                 error(message('vision:groundTruth:badPixelLabelData', name));
            end
    end
end

% If a time table or table was specified, it must be consistent with the
% data source.
if ~isempty(dataSource)
    if hasTimeStamps(dataSource)
        if isa(labelData, 'timetable')
            vision.internal.labeler.validation.checkTimes(labelData, dataSource);
            
            % Ensure that source times match exactly with dataSource. Across
            % platforms, videos may provide slightly different time stamps. In that
            % case, modify labelData to use row times from the source.
            labelData.Time = dataSource.TimeStamps;
        else
            labelData = table2timetable(labelData, 'RowTimes', dataSource.TimeStamps);
        end
    end
end
end

%--------------------------------------------------------------------------
function tf = validateRectangleData(datum)
% Expected each entry to be a M-by-4 matrix.

tf = isempty(datum) ||  ...                                 % empty allowed
    isfloat(datum) && size(datum,2)==4; %&& ...             % single/double, of size Mx4
end

%--------------------------------------------------------------------------
function tf = validateLineData(datum)
% Expected each entry to be a M-by-1 cell array, with each element being
% N-by-2 matrices.

if isempty(datum)
    tf = true;
elseif iscell(datum)
    tf = isvector(datum) && ...                                     % 1-d cell
        all( cellfun( @(x)isfloat(x) && size(x,2)==2, datum ) );    % single/double, of size Mx4
else
    tf = false;
end
end

%--------------------------------------------------------------------------
function tf = validatePixelLabelData(datum)
% Expected each entry to be a character vector or ''.
tf = isempty(datum) || (ischar(datum) && isvector(datum));
end