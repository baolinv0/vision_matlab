% TableValidator Object for validating tables
%
%  tableValidator = TableValidator creates a new table validator object.
%
%  TableValidator properties:
%       MinRows               - Minimum number of rows
%       CanBeEmpty            - Allow the table to be empty
%       RequiredVariableNames - Required columns
%       OptionalVariableNames - Optional columns
%       MinRowsMsg            - Error message for having too few rows
%       MissingRequiredVariablesMsg - Error message for missing required columns
%       UnrecognizedVariablesMsg    - Error message for columns that are neither required nor optional
%       ValidationFunctions    - A map containing validation function handles for particular columns
%
%  TableValidator methods:
%       validate - Validate a table
%
%  Example:
%  --------
%  validator = vision.internal.inputValidation.TableValidator;
%  validator.MinRows = 1;
%  validator.RequiredVariableNames = {'ViewId'};
%  validator.OptionalVariableNames = {'Points', 'Orientation', 'Location'};
%
%  ViewId = 1;
%  Points = {rand(3, 2)};
%  view = table(ViewId, Points);
%  validate(validator, view, 'myfilename', 'view')
%
%  See also viewSet, bundleAdjustment

%  Copyright 2015 The MathWorks, Inc.
classdef TableValidator 
    properties
        MinRows = 0;
        CanBeEmpty = false;
        RequiredVariableNames = {};
        OptionalVariableNames = {};
        
        MinRowsMsg = 'vision:table:tooFewRows';
        MissingRequiredVariablesMsg = 'vision:table:missingRequiredColumns';
        UnrecognizedVariablesMsg = 'vision:table:unrecognizedColumns';
        
        ValidationFunctions;
    end
    
    methods
        %------------------------------------------------------------------
        function this = TableValidator()
            this.ValidationFunctions = ...
                containers.Map('KeyType', 'char', 'ValueType', 'any');
        end
        
        %------------------------------------------------------------------
        function tf = validate(this, theTable, filename, varname)                   
        % validate Validate a table.
        %  tf = validate(tableValidator, theTable, filename, varname) returns
        %  true if theTable is valid, and throws an error otherwise. 
        %  tableValidator is a TableValidator object. theTable is
        %  a table, flename is the name of the calling M-file. varname is
        %  the variable name of the table.
            
            if this.CanBeEmpty
                attr = {};
            else
                attr = {'nonempty'};
            end
            validateattributes(theTable, {'table'}, attr, filename, varname);
            
            if height(theTable) < this.MinRows
                error(message(this.MinRowsMsg, varname, this.MinRows));
            end
            
            % Check that required columns are present
            if ~all(ismember(this.RequiredVariableNames, ...
                    theTable.Properties.VariableNames))
                error(message(this.MissingRequiredVariablesMsg, varname, ...
                    strjoin(this.RequiredVariableNames, ', ')));
            end
            
            % Check that there are no extra columns
            if any(~ismember(theTable.Properties.VariableNames, ...
                    cat(2, this.RequiredVariableNames, this.OptionalVariableNames)))
                error(message(this.UnrecognizedVariablesMsg, varname, ...
                    strjoin(cat(2, this.RequiredVariableNames, this.OptionalVariableNames), ...
                    ', ')));
            end
            
            % Check the entries
            vars = keys(this.ValidationFunctions);
            funs = values(this.ValidationFunctions);
            for i = 1:numel(vars)
                var = vars{i};
                if ismember(var, theTable.Properties.VariableNames)
                    fun = funs{i};
                    checkColumn(theTable, var, fun);
                end
            end
            tf = true;
        end
    end
end

%--------------------------------------------------------------------------
function checkColumn(theTable, colName, fun)
col = theTable{:, colName};
if iscell(col)
    cellfun(fun, col);
else
    arrayfun(fun, col);
end
end