%LabelSet This is the base class from which ROILabelSet and FrameLabelSet
%are inherited.

% Copyright 2016-2017 The MathWorks, Inc.

classdef (Abstract) LabelSet < handle
    
    properties (GetAccess = public, SetAccess = protected)
        
        % Struct storing arrays of the following fields to represent a
        % definition set. We use a struct here so as to easily return a
        % table down the line. This will be defined in the derived class.
        DefinitionStruct
        
        NumLabels
        PixelLabelID
        ColorCounter
    end
    
    events
        LabelAdded
        LabelRemoved
        LabelChanged
        PixelLabelRemoved
        
        AttributeAdded
    end
    
    properties (Access = protected)
        colorLookup
        maxColors
        pixelColorLookup
    end
    
    methods
        %------------------------------------------------------------------
        function renameLabel(this, labelID, newName)
            %renameLabel renames label
            %   renameLabel(labelSet, labelID, newName) renames label with
            %   ID labelID as newName.
            %
            %   renameLabel(labelSet, oldName, newName) renames label with
            %   name oldName to newName.
            
            labelID = this.labelNameToID(labelID);
            
            % If the label name is not valid or is a duplicate, fail the
            % operation.
            [validLabelName,uniqueLabelName] = this.isUniqueLabelName(newName);
            if ~validLabelName
                invalidNameDialog(this);
                return;
            elseif ~uniqueLabelName
                duplicateNameDialog(this);
                return;
            end
            
            % Store the old name in the label ID
            oldName = this.labelIDToName(labelID);
            
            this.DefinitionStruct(labelID).Name = newName;
            
            if this.DefinitionStruct(labelID).Type ~= labelType.PixelLabel
                % Create event data packet with old name
                evtData = this.createEventDataPacket(labelID);
                evtData.OldLabel = oldName;

                notify(this, 'LabelChanged', evtData);
            end
        end
        
        %------------------------------------------------------------------
        function removeLabel(this, labelID)
            %removeLabel removes a label
            %   removeLabel(labelSet, labelID) removes label with ID
            %   labelID from the labelSet.
            %
            %   removeLabel(labelSet, labelName) removes label with Name
            %   labelName from the labelSet.
            
            labelID = this.labelNameToID(labelID);
            
            if ~isfield(this.DefinitionStruct,'Type') || (this.DefinitionStruct(labelID).Type ~= labelType.PixelLabel)
                % Create event first before the label is removed
                evtData = this.createEventDataPacket(labelID);
                notify(this, 'LabelRemoved', evtData);
            end
            
            % Remove label definition with specified ID.
            this.DefinitionStruct(labelID) = [];
            
            % If no pixel labels exist, remove PixelLabelData from
            % Annotation Struct if applicable
            if ~hasPixelLabel(this)
                notify(this, 'PixelLabelRemoved');
            end
            
            % Update LabelIDs to be linear.
            linearIDs = num2cell( 1 : numel(this.DefinitionStruct) );
            [this.DefinitionStruct.LabelID] = deal(linearIDs{:});
            
            % Update number of labels
            this.NumLabels = this.NumLabels-1;
        end
        
        %------------------------------------------------------------------
        function [isValid, isUnique] = isUniqueLabelName(this, labelName)
            %isUniqueLabelName Specifies whether label name is valid and
            %unique.
            %   [isV, isU] = isUniqueLabelName(labelSet,labelName) returns
            %   isV true if valid and isU true if it is unique and valid.
            
            isValid = isvarname(labelName) || (iscellstr(labelName) && isscalar(labelName) && isvarname(labelName{1}));
            isUnique = isValid && ( isempty(this.DefinitionStruct) || ~any( strcmpi({this.DefinitionStruct.Name},labelName) ) );
            
        end
        
        %------------------------------------------------------------------
        function labelSetTable = export2table(this)
            %export2table exports label definitions as a table
            % frameSetTable = export2table(labelSet) exports label
            % definitions in LabelSet labelSet to a table
            % labelSetTable.
            
            if isempty(this.DefinitionStruct)
                labelSetTable = table({},{},{},{},'VariableNames',{'Name','Type','PixelLabelID','Description'});
            else
                labelSetTable = struct2table(this.DefinitionStruct,'AsArray',true);
                
                % Remove color
                isColorPresent = any(strcmpi('Color',labelSetTable.Properties.VariableNames));
                if isColorPresent
                    labelSetTable.Color = [];
                end
                
                % Remove label ID
                isLabelIdPresent = any(strcmpi('LabelID',labelSetTable.Properties.VariableNames));
                if isLabelIdPresent
                    labelSetTable.LabelID = [];
                end
                
                % Remove attribute
                isAttrPresent = any(strcmpi('Attributes',labelSetTable.Properties.VariableNames));
                if isAttrPresent
                    labelSetTable.Attributes = [];
                end
                
                % Convert PixelLabelID to cells.
                if ~iscell(labelSetTable.PixelLabelID) 
                    % struct2array only packs data into cells if it needs
                    % to. In case of just pixel label IDs, the are all
                    % scalars so they do not get packed into cells.
                    % However, groundTruth requires them to be put into
                    % cells.
                    labelSetTable.PixelLabelID = num2cell(labelSetTable.PixelLabelID);
                end
                
            end
        end
        
        %------------------------------------------------------------------
        function name = labelIDToName(this,id)
            %labelIDToName converts label ID to label name.
            %   If the input is an ID, the corresponding label name is
            %   returned. If the input is a label name, it is passed
            %   through.
            
            if ischar(id)
                name = id;
            else
                name = this.DefinitionStruct(id).Name;
            end
        end
        
        %------------------------------------------------------------------
        function ID = labelNameToID(this,name)
            %labelNameToID converts label name to ID.
            %   If the input is a label name, a label ID is returned. If
            %   the input is a ID, it is passed through.
            
            if ischar(name) || isstring(name)
                ID = find( strcmpi(name,{this.DefinitionStruct.Name}) );
                
                assert(~isempty(ID), 'Invalid Label Name');
            else
                ID = name;
            end
        end
        
        %------------------------------------------------------------------
        function TF = hasPixelLabel(this)
            %hasPixelLabel Returns true if there is a labelType.PixelLabel
            %in the ROI label set
            if isfield(this.DefinitionStruct,'Type')
                labelTypes = [this.DefinitionStruct.Type];
                TF = any(labelTypes == labelType.PixelLabel);
            else
                TF = false;
            end
        end
        
        %------------------------------------------------------------------
        function TF = hasRectangularLabel(this)
            %hasPixelLabel Returns true if there is a labelType.Rectangle
            %in the ROI label set
            if isfield(this.DefinitionStruct,'Type')
                labelTypes = [this.DefinitionStruct.Type];
                TF = any(labelTypes == labelType.Rectangle);
            else
                TF = false;
            end
        end
        
        %------------------------------------------------------------------
        function N = getNumROIByType(this, type)
            
            labelTypes = [this.DefinitionStruct.Type];
            N = sum(labelTypes == type);
        end
        
        %------------------------------------------------------------------
        function id = getNextPixelLabel(this)
            %getNextPixelLabel Returns the next available PixelLabelID
            %value from range of 1 to 255
            if isfield(this.DefinitionStruct,'PixelLabelID')
                possibleIDs = 1:255;
                currentIDs = [this.DefinitionStruct.PixelLabelID];
                possibleIDs(currentIDs) = [];
                id = min(possibleIDs);
            end
        end
    end
    
    methods (Access = protected)
        %------------------------------------------------------------------
        function initializeColorLookup(this, displaySource)
            this.colorLookup = vision.internal.labeler.getColorMap(displaySource);
            this.maxColors = size(this.colorLookup,1);
        end
        
        %------------------------------------------------------------------
        function growColorLookup(this)
            
            % Try to grow the lookup by growLength. If there are repeated
            % entries within this local set, we may grow by a smaller
            % number.
            growLength = 8;
            newColors = unique(rand(growLength,3),'rows');
            
            % Add this list of colors to the colorLookup. Check if there
            % are repeated entries and remove from the list.
            [~,~,idxNew] = intersect(squeeze(this.colorLookup), newColors, 'rows');
            newColors(idxNew,:) = [];
            
            actualGrowLength = size(newColors,1);
            this.colorLookup = cat(2,this.colorLookup,reshape(newColors,1,actualGrowLength,3));
            this.maxColors = actualGrowLength;
        end
        
        %------------------------------------------------------------------
        function evtData = createEventDataPacket(this, labelID)
            label = this.labelIDToName(labelID);
            evtData = vision.internal.labeler.LabelSetUpdateEvent(label);
        end
        
        %------------------------------------------------------------------
        function invalidNameDialog(~)
            errordlg(...
                vision.getMessage('vision:uitools:invalidCategoryVariable'),...
                vision.getMessage('MATLAB:uistring:popupdialogs:ErrorDialogTitle'),...
                'modal');
        end
        
        %------------------------------------------------------------------
        function duplicateNameDialog(~)
            errordlg(...
                vision.getMessage('vision:uitools:DuplicateLabelName'),...
                vision.getMessage('MATLAB:uistring:popupdialogs:ErrorDialogTitle'),...
                'modal');
        end
    end
end