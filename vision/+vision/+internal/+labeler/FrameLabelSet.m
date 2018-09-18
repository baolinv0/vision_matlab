% FrameLabelSet Stores all information about Frame labels that are labeled.

% Copyright 2016-2017 The MathWorks, Inc.

classdef FrameLabelSet < vision.internal.labeler.LabelSet
    
    % Struct storing arrays of the following fields to represent a
    % definition set.
    %  * LabelName
    %  * LabelID
    %  * Color
    %  * Description
    % We use a struct here so as to easily return a table down the
    % line.
    % DefinitionStruct (inherited)

    methods
        %------------------------------------------------------------------
        function this = FrameLabelSet(varargin)
            %FrameLabelSet Construct a FrameLabel set
            %   frameSet = FrameLabelSet() returns a FrameLabelSet with no
            %   labels. Use the addLabel method to add labels to this set.
            %
            %   frameSet = FrameLabelSet(labelNames) returns a
            %   FrameLabelSet with labels specified by elements of
            %   labelNames.
            
            this.initializeColorLookup('scene');
            
            this.NumLabels = 0;
            
            this.DefinitionStruct = struct(...
                'Name',{},...
                'LabelID',[],...
                'Color',[],...
                'PixelLabelID',[],...
                'Description','');
            
            if nargin>0
                labelNames = varargin{1};
                if ~iscellstr(labelNames)
                    labelNames = cellstr(labelNames);
                end
                
                for n = 1 : numel(labelNames)
                    this.addLabel(labelNames{n});
                end
            end
        end
        
        %------------------------------------------------------------------
        function tf = validateLabelName(this, labelName)
            % validate if the given label name is valid
            tf = true;
            
            % If the label name is not valid or is a duplicate, fail the
            % operation.
            [validLabelName,uniqueLabelName] = this.isUniqueLabelName(labelName);
            if ~validLabelName
                invalidNameDialog(this);
                tf = false;
            elseif ~uniqueLabelName
                duplicateNameDialog(this);
                tf = false;
            end
        end
        
        %------------------------------------------------------------------
        function frameLabel = addLabel(this, frameLabel)
            %addLabel adds a label to the frame label set
            
            labelName   = frameLabel.Label;
            description = frameLabel.Description;
            
            % If the label name is not valid or is a duplicate, fail the
            % operation.
            [validLabelName,uniqueLabelName] = this.isUniqueLabelName(labelName);
            if ~validLabelName
                invalidNameDialog(this);
                return;
            elseif ~uniqueLabelName
                duplicateNameDialog(this);
                return;
            end
            
            this.NumLabels = this.NumLabels + 1;
            
            % If the number of colors exceeds maxColors, we grow the table.
            if this.NumLabels>this.maxColors
                this.growColorLookup();
            end
            colorVal = reshape(this.colorLookup(:,this.NumLabels,:),1,3);
            frameLabel.Color = colorVal;
            
            definitionStruct = struct('Name', labelName, ...
                'LabelID', this.NumLabels, 'Color', colorVal, ...
                'PixelLabelID', '', 'Description', description);
            this.DefinitionStruct = [this.DefinitionStruct; definitionStruct];
            
            labelID = this.NumLabels;
            evtData = this.createEventDataPacket(labelID);
            notify(this, 'LabelAdded', evtData);
        end
        
        %------------------------------------------------------------------
        function frameLabel = queryLabel(this, labelID)
            %queryLabel returns label data corresponding to a label ID
            %   frameLabel = queryLabel(labelID) returns FrameLabel object
            %   representing data corresponding to label with ID labelID.
            %
            %   frameLabel = queryLabel(labelName) returns FrameLabel object
            %   representing data corresponding to label with name
            %   labelName.
            
            labelID = this.labelNameToID(labelID);
            labelDataStruct = this.DefinitionStruct(labelID);
            
            name  = labelDataStruct.Name;
            descr = labelDataStruct.Description;
            color = labelDataStruct.Color;
            
            frameLabel = vision.internal.labeler.FrameLabel(name, descr);
            frameLabel.Color = color;
        end
        
        %------------------------------------------------------------------
        function color = queryLabelColor(this, labelID)
            %queryLabelColor returns color associated with label ID.

            color = this.DefinitionStruct(labelID).Color;
        end
        
        %------------------------------------------------------------------
        function oldDescr = updateLabelDescription(this, labelID, descr)
            %updateLabelDescription update the description associated with
            %label ID.
            oldDescr = this.DefinitionStruct(labelID).Description;
            this.DefinitionStruct(labelID).Description = descr;
        end
        
        %------------------------------------------------------------------
        function labelSetTable = export2table(this)
            %export2table exports label definitions as a table
            % frameSetTable = export2table(labelSet) exports label
            % definitions in LabelSet labelSet to a table
            % labelSetTable.
            
            labelSetTable = export2table@vision.internal.labeler.LabelSet(this);
            
            labelSetTable.Type = repmat(labelType.Scene,height(labelSetTable),1);
            
            labelSetTable = labelSetTable(:,{'Name','Type','PixelLabelID','Description'});
        end
        
        %------------------------------------------------------------------
        function TF = hasSceneLabel(this)
            %hasPixelLabel Returns true if there are any scene labels
            %defined.
            TF = this.NumLabels > 0;
        end
     end
end