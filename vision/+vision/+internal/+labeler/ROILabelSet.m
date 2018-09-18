% ROILabelSet Stores all information about ROI labels that are labeled.
%
% Example
% -------
% Construct an ROILabelSet for a car, pedestrian and lane markers. Export
% it to a table.
% 
% import vision.internal.labeler.*;
%
% labelSet = ROILabelSet({'Car','Pedestrian','LaneMarker'},...
%   [labelType.Rectangle,labelType.Rectangle,labelType.Line]);
%
% export2table(labelSet)


% Copyright 2017 The MathWorks, Inc.

classdef ROILabelSet < vision.internal.labeler.LabelSet
    
        % Struct storing arrays of the following fields to represent a
        % definition set.
        %  * LabelName
        %  * LabelID
        %  * Type
        %  * Color
        %  * Attributes
        %  * Description
        % We use a struct here so as to easily return a table down the
        % line.
        % DefinitionStruct
        
    methods
        %------------------------------------------------------------------
        function this = ROILabelSet(varargin)
            %ROILabelSet Construct a ROILabel set
            %   roiSet = ROILabelSet() returns a ROILabelSet with no
            %   labels. Use the addLabel method to add labels to this set.
            %
            %   roiSet = ROILabelSet(labelNames, shapes) returns a
            %   ROILabelSet with labels specified by elements of
            %   labelNames, each having shapes specified by shapes.
            %   labelNames and shapes must be character arrays (for a
            %   single label) or cellstrs of the same length. shapes must
            %   be one of 'rect' or 'line'.
            
            this.initializeColorLookup('roi');
            this.pixelColorLookup = vision.internal.labeler.getColorMap('pixel');
            
            this.NumLabels = 0;
            this.PixelLabelID = 0;
            this.ColorCounter = 0;
            
            this.DefinitionStruct = struct(...
                'Name',{},...
                'LabelID',[],...
                'Type',labelType.empty,...
                'Color',[],...
                'Attributes',{},...
                'PixelLabelID',[],...
                'Description','');
            
            if nargin==2
                labelNames  = varargin{1};
                shapes      = varargin{2};
                
                if ~iscellstr(labelNames)
                    labelNames = cellstr(labelNames);
                end
                                
                for n = 1 : numel(labelNames)
                    roiLabel = vision.internal.labeler.ROILabel(shapes(n), labelNames{n}, '');
                    this.addLabel(roiLabel);
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
        function roiLabel = addLabel(this, roiLabel)
            %addLabel adds a label to the ROI label set
            
            labelName   = roiLabel.Label;
            shape       = roiLabel.ROI;
            attributes  = roiLabel.Attributes;
            description = roiLabel.Description;
            
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
            
            % If the ROI shape is not one of the accepted shapes, fail the
            % operation.
            goodRoiType = isa(shape,'labelType') && shape.isROI;
            
            assert(goodRoiType, 'Invalid ROI shape was specified')
            
            this.NumLabels = this.NumLabels + 1;
            
            if shape == labelType.PixelLabel                
                pixelID = roiLabel.PixelLabelID;
                assert(pixelID <= 255,'The maximum pixel label ID is 255.');
                assert(pixelID > 0, 'The minimum pixel label ID is 0.');
                colorVal = reshape(this.pixelColorLookup(:,pixelID,:),1,3);
            else
                pixelID = [];
                this.ColorCounter = this.ColorCounter + 1;
                % If the number of colors exceeds maxColors, we grow the table.
                if this.ColorCounter>this.maxColors
                    this.growColorLookup();
                end
                colorVal = reshape(this.colorLookup(:,this.ColorCounter,:),1,3);
            end
            
            roiLabel.Color = colorVal;
            roiLabel.PixelLabelID = pixelID;
            
            definitionStruct = struct('Name', labelName, ...
                'LabelID', this.NumLabels, 'Type', shape, ...
                'Color', colorVal, 'Attributes', cell(1), ...
                'PixelLabelID', pixelID, 'Description', description);
            this.DefinitionStruct = [this.DefinitionStruct; definitionStruct];
            
            if isempty(attributes)
                attributes = {};
            end
            
            attributes = cellstr(attributes);
            for n = 1 : numel(attributes)
                this.addAttributeToLabel(this, this.NumLabels, attributes{n});
            end
            
            labelID = this.NumLabels;
            evtData = this.createEventDataPacket(labelID);
            notify(this, 'LabelAdded', evtData);
        end
        
        %------------------------------------------------------------------
        function addAttributeToLabel(this, labelID, attribute)
            %addAttributeToLabel adds an attribute to a label
            %   addAttributeToLabel(roiSet, labelID, attribute) adds
            %   attribute specified by string attribute to label with ID
            %   labelID.
            
            % If the attribute name is not valid or is a duplicate, fail
            % the operation.
            goodAttributeName = this.isUniqueAttributeName(labelID,attribute);
            
            assert(goodAttributeName, 'Invalid or duplicate attribute name');
            
            attribute = {attribute};
            this.DefinitionStruct(labelID).Attributes = [this.DefinitionStruct(labelID).Attributes attribute];
            
            evtData = this.createEventDataPacket(labelID);
            notify(this, 'AttributeAdded', evtData);
        end
        
        %------------------------------------------------------------------
        function roiLabel = queryLabel(this, labelID)
            %queryLabel returns label data corresponding to a label ID
            %   roiLabel = queryLabel(labelID) returns ROILabel object
            %   representing data corresponding to label with ID labelID.
            %
            %   roiLabel = queryLabel(labelName) returns ROILabel object
            %   representing data corresponding to label with name
            %   labelName.
            
            labelID = this.labelNameToID(labelID);
            labelDataStruct = this.DefinitionStruct(labelID);
            
            shape = labelDataStruct.Type;
            name  = labelDataStruct.Name;
            descr = labelDataStruct.Description;
            attr  = labelDataStruct.Attributes;
            color = labelDataStruct.Color;
            id = labelDataStruct.PixelLabelID;
            
            roiLabel = vision.internal.labeler.ROILabel(shape, name, descr, attr);
            roiLabel.Color = color;
            roiLabel.PixelLabelID = id;
        end
        
        %------------------------------------------------------------------
        function color = queryLabelColor(this, labelID)
            %queryLabelColor returns color associated with label ID.

            color = this.DefinitionStruct(labelID).Color;
        end
        
        %------------------------------------------------------------------
        function shape = queryLabelShape(this, labelID)
            %queryLabelShape returns shape associated with label ID.

            shape = this.DefinitionStruct(labelID).Type;
        end        
        
        %------------------------------------------------------------------
        function oldDescr = updateLabelDescription(this, labelID, descr)
            %updateLabelDescription update the description associated with
            %label ID.
            oldDescr = this.DefinitionStruct(labelID).Description;
            this.DefinitionStruct(labelID).Description = descr;
        end    

    end
    
    methods (Access = private)
        %------------------------------------------------------------------
        function flag = isUniqueAttributeName(this, labelID, attribute)
            
            isValid = ischar(attribute) || (iscellstr(attribute) && isscalar(attribute)) ...
                && ~isempty(attribute);
            
            existingAttributes = this.DefinitionStruct(labelID).Attributes;
            isUnique = ~any( strcmpi(existingAttributes,attribute) );
            
            flag = isValid && isUnique;
        end
    end
end