% Session holds the state of the Labeler Apps
%
%   It is used to save and load the labeling session. It is also used to pass
%   data amongst other classes.

% Copyright 2017 The MathWorks, Inc.

classdef Session < handle
    properties
        % true when the session may need saving
        IsChanged               logical 
        
        % true when corresponding label matrix may need saving
        IsPixelLabelChanged logical
        
        FileName                    % filename of the stored session
        PixelLabelDataPath          % User-selected path to save pixel label data
        
        % definition of ROI labels
        ROILabelSet             vision.internal.labeler.ROILabelSet 
        % definition of frame labels
        FrameLabelSet           vision.internal.labeler.FrameLabelSet
        
        ROIAnnotations              % roi annotations on a per-frame basis
        FrameAnnotations            % frame annotations on a per-frame basis        
    end
    
    properties (Dependent, SetAccess = private)
        HasROILabels
        NumROILabels
        HasFrameLabels
        NumFrameLabels        
    end    
    
    properties (Abstract, Access = protected, Hidden)
        Version;
    end 
    
    %----------------------------------------------------------------------
    % Constructor
    %----------------------------------------------------------------------
    methods
        function this = Session()
            this.reset();
        end
    end
    
    %----------------------------------------------------------------------
    % Reset
    %----------------------------------------------------------------------       
    methods
        function reset(this)
            this.FileName       = [];
            this.ROILabelSet    = vision.internal.labeler.ROILabelSet;
            this.FrameLabelSet  = vision.internal.labeler.FrameLabelSet;

            this.ROIAnnotations   = vision.internal.labeler.ROIAnnotationSet(this.ROILabelSet);
            this.FrameAnnotations = vision.internal.labeler.FrameAnnotationSet(this.FrameLabelSet);
            
            this.IsChanged = false;
            
            this.IsPixelLabelChanged = false(0,1);
        end
    end
    
    %----------------------------------------------------------------------
    % Labels
    %----------------------------------------------------------------------    
    methods
        function [roiLabels,frameLabels] = getLabelDefinitions(this)
            %getLabelDefinitions returns a set of ROILabel and FrameLabel
            %objects corresponding to the label definitions loaded in the
            %Session.
            
            import vision.internal.labeler.*;
            
            numROILabels = this.ROILabelSet.NumLabels;
            roiLabels = repmat(ROILabel(labelType.empty,'',''), 1, numROILabels);
            for n = 1 : numROILabels
                roiLabels(n) = this.ROILabelSet.queryLabel(n);
            end
            
            numFrameLabels = this.FrameLabelSet.NumLabels;
            frameLabels = repmat(FrameLabel('',''), 1, numFrameLabels);
            for n = 1 : numFrameLabels
                frameLabels(n) = this.FrameLabelSet.queryLabel(n);
            end
        end

        function isValid = isValidName( this, labelName )
            currROILabelNames = {this.ROILabelSet.DefinitionStruct.Name};
            currFrameLabelNames = {this.FrameLabelSet.DefinitionStruct.Name};
            isValid = isempty(find(strcmp(currROILabelNames, labelName), 1)) && isempty(find(strcmp(currFrameLabelNames, labelName), 1));            
        end
        
        function addAlgorithmLabels(this, index, labelData)
            % add labels produced by the automation algorithm to the
            % Session.
            
            if isempty(labelData)
                return;
            end
            
            index = max(index,1);
            
            if istable(labelData)
                labelData = table2struct(labelData);
            end
            
            if iscategorical(labelData)
                
                try
                    filename = fullfile(this.TempDirectory,sprintf('Label_%d.png',index));
                    L = imread(filename);

                    % If we do read a label matrix make sure it's the same size
                    % as I.
                    lsz = size(L);
                    sz = size(labelData);
                    if ~isequal(lsz(1:2),sz(1:2))
                        error(message('vision:labeler:PixelLabelDataSizeMismatch'))                 
                    end
                catch 
                    L = zeros(size(labelData),'uint8');
                end 
                                
                % Convert each categorical label into the corresponding
                % PixelLabelID value
                appliedLabels = categories(labelData);
                
                for idx = 1:numel(appliedLabels)
                    roiLabel = queryLabel(this.ROILabelSet,appliedLabels{idx});
                    L(labelData == appliedLabels{idx}) = roiLabel.PixelLabelID;
                end
                
                TF = writeData(this,L,index);
                if ~TF
                    filename = '';
                end
                setPixelLabelAnnotation(this, index, filename);
            
            else
                isROILabel      = isROI([labelData.Type]);
                isSceneLabel    = isScene([labelData.Type]);
                
                autoROILabels   = labelData(isROILabel);
                autoSceneLabels = labelData(isSceneLabel);
                
                autoROILabelNames = {autoROILabels.Name};
                autoROIPositions  = {autoROILabels.Position};
                
                % We do not want to lose labels that were previously added.
                [oldROIPositions, oldROINames] = queryROILabelAnnotation(this, index);
                addROILabelAnnotations(this, index, [oldROINames,autoROILabelNames], [oldROIPositions,autoROIPositions]);
                
                autoSceneLabelNames = {autoSceneLabels.Name};
                oldFrameLabelNames = queryFrameLabelAnnotation(this, index);
                addFrameLabelAnnotation(this, index, [oldFrameLabelNames,autoSceneLabelNames]);
            end
            this.IsChanged = true;
        end
        
        %------------------------------------------------------------------
        % ROI Labels
        %------------------------------------------------------------------
        function addROILabelAnnotations(this, index, labelNames, positions)
            %
            % Inputs
            % ------
            %   index       - scalar double containing time vector index
            %   labelNames  - cell array of character vectors (cellstr)
            %   positions   - cell array of positions. for rectangles,
            %                 each element of the cell array will be a Nx4
            %                 matrix containing the position of N
            %                 rectangles for the corresponding label name
            %                 at that time stamp. for lines, each element
            %                 of the cell array will be a Nx1 cell array
            %                 containing positions of N lines.
            
            index = max(index,1);
            
            this.ROIAnnotations.addAnnotation(index, labelNames, positions);
            this.IsChanged = true;
        end
        
        %------------------------------------------------------------------
        % Pixel Labels
        %------------------------------------------------------------------
        function setPixelLabelAnnotation(this, index, labelPath)
            
            index = max(index,1);
            
            this.ROIAnnotations.setPixelLabelAnnotation(index, labelPath);
            this.IsChanged = true;
        end
        
        function [positions, names, colors, shapes] = queryROILabelAnnotation(this, index)
            
            index = max(index,1);
            
            [positions, names, colors, shapes] = this.ROIAnnotations.queryAnnotation(index);
        end
        
        function roiLabel = addROILabel(this, roiLabel)

            % Update label definition
            roiLabel = this.ROILabelSet.addLabel(roiLabel);    
            this.IsChanged = true;
        end
        
        function deleteROILabel(this, labelID)
            % Remove label definition
            this.ROILabelSet.removeLabel(labelID);
            this.IsChanged = true;
        end 
        
        function roiLabel = queryROILabelData(this, indexOrName)
            roiLabel = this.ROILabelSet.queryLabel(indexOrName);
        end
                
        %------------------------------------------------------------------
        function TF = hasPixelLabels(this)
            TF = hasPixelLabel(this.ROILabelSet);
        end
        
        %------------------------------------------------------------------
        function TF = hasRectangularLabels(this)
            TF = hasRectangularLabel(this.ROILabelSet);
        end
        
        %------------------------------------------------------------------
        function TF = hasSceneLabels(this)
            TF = hasSceneLabel(this.FrameLabelSet);
        end
        
        %------------------------------------------------------------------
        function N = getNumPixelLabels(this)
            N = this.ROILabelSet.getNumROIByType(labelType.PixelLabel);
        end
        
        %------------------------------------------------------------------
        function N = getPixelLabels(this)
            N = getNextPixelLabel(this.ROILabelSet);
        end
        
        %------------------------------------------------------------------
        function pixelDataPath = getPixelLabelDataPath(this)
            pixelDataPath = this.PixelLabelDataPath;
        end
        
        %------------------------------------------------------------------
        function setPixelLabelDataPath(this, pixelDataPath)
            this.PixelLabelDataPath = pixelDataPath;
        end
        
        %------------------------------------------------------------------
        % Frame Labels
        %------------------------------------------------------------------
        function addFrameLabelAnnotation(this, index, labelNames)
            %
            % Inputs
            % ------
            %   index       - scalar double containing time index or
            %                 2-element vector [tsStart tsEnd) containing
            %                 range of time indices.
            %   labelNames  - cell array of character vectors (cellstr).
            
            index = max(index,1);
            
            this.FrameAnnotations.addAnnotation(index, labelNames);
            this.IsChanged = true;
        end
        
        function deleteFrameLabelAnnotation(this, index, labelNames)
            %
            % Inputs
            % ------
            %   index       - scalar double containing time index or
            %                 2-element vector [tsStart tsEnd) containing
            %                 range of time indices.
            %   labelNames  - cell array of character vectors (cellstr).
            
            index = max(index,1);
            
            this.FrameAnnotations.removeAnnotation(index, labelNames);
            this.IsChanged = true;
        end
        
        function [names, colors, ids] = queryFrameLabelAnnotation(this, index)
            
            index = max(index,1);
            
            [names, colors, ids] = this.FrameAnnotations.queryAnnotation(index);
        end
        
        function frameLabel = addFrameLabel(this, name)
            
            % Update label definition
            frameLabel = this.FrameLabelSet.addLabel(name);
            this.IsChanged = true;
        end
        
        function deleteFrameLabel(this, labelID)
            % Remove label definition
            this.FrameLabelSet.removeLabel(labelID);
            this.IsChanged = true;
        end

        function frameLabel = queryFrameLabelData(this, indexOrName)
            frameLabel = this.FrameLabelSet.queryLabel(indexOrName);
        end   
    end
    
    %----------------------------------------------------------------------
    % Import/Export
    %----------------------------------------------------------------------
    methods

        function loadLabelDefinitions(this, definitions)
            numImages = getNumImages(this.ROIAnnotations);
            reset(this);

            if numImages > 0
                this.ROIAnnotations.addSourceInformation(numImages);
                this.FrameAnnotations.addSourceInformation(numImages);  
            end
            
            addDefinitions(this, definitions);
        end
        
        function loadLabelAnnotations(this, data)
            
            definitions = data.LabelDefinitions;
            loadLabelDefinitions(this, definitions)
           
            addData(this, data);
        end
        
        function definitions = exportLabelDefinitions(this)
            
            % Extract ROI Label Definitions
            roiDefinitionsTable = this.ROILabelSet.export2table;
            
            % Extract Frame Label Definitions
            frameDefinitionsTable = this.FrameLabelSet.export2table;
            
            if ~hasPixelLabel(this.ROILabelSet)
                % Strip out PixelLabelID field if there is no pixel label
                % type in the ROI label set
                roiDefinitionsTable.PixelLabelID = [];
                frameDefinitionsTable.PixelLabelID = [];
            end
            
            % Create label definitions tabke to encapsulate ROI and Frame
            % label definitions.
            definitions = vertcat(roiDefinitionsTable, frameDefinitionsTable);
        end
    end 
    
    %----------------------------------------------------------------------
    % Algorithm Workflow
    %----------------------------------------------------------------------
    methods
        function cacheAnnotations(this)
            cache(this.ROIAnnotations);
            cache(this.FrameAnnotations);
        end
                
        function uncacheAnnotations(this)
            uncache(this.ROIAnnotations);
            uncache(this.FrameAnnotations);
        end        
    end
    
    %----------------------------------------------------------------------
    % Getter Methods
    %----------------------------------------------------------------------
    methods
        function TF = get.HasROILabels(this)
            TF = this.ROILabelSet.NumLabels > 0;
        end
        
        function numLabels = get.NumROILabels(this)
            numLabels = this.ROILabelSet.NumLabels;
        end
        
        function TF = get.HasFrameLabels(this)
            TF = this.FrameLabelSet.NumLabels > 0;
        end
        
        function numLabels = get.NumFrameLabels(this)
            numLabels = this.FrameLabelSet.NumLabels;
        end
    end
    
    %----------------------------------------------------------------------
    % Helper Methods
    %----------------------------------------------------------------------
    methods(Sealed, Access = protected)

        function addDefinitions(this, definitions)
            
            definitions = table2struct(definitions);
            hasDescription = isfield(definitions,'Description');
            
            % Add ROI label definitions
            roiLabelDefs = definitions(isROI([definitions.Type]));
            for n = 1 : numel(roiLabelDefs)
                roi     = roiLabelDefs(n).Type;
                label   = roiLabelDefs(n).Name;
                if hasDescription
                    desc    = roiLabelDefs(n).Description;
                else
                    desc    = '';
                end

                if roiLabelDefs(n).Type == labelType.PixelLabel
                    % use the pixel label id from the definition table.
                    pixelLabelID = roiLabelDefs(n).PixelLabelID;
                    emptyAttrib = [];
                    roiLabel = vision.internal.labeler.ROILabel(roi, label, desc, emptyAttrib, pixelLabelID);
                else
                    roiLabel = vision.internal.labeler.ROILabel(roi, label, desc);
                end
                
                this.ROILabelSet.addLabel(roiLabel);
            end
            
            % Add Frame label definitions
            frameLabelDefs = definitions(isScene([definitions.Type]));
            for n = 1 : numel(frameLabelDefs)
                label   = frameLabelDefs(n).Name;
                if hasDescription
                    desc    = frameLabelDefs(n).Description;
                else
                    desc    = '';
                end
                frameLabel = vision.internal.labeler.FrameLabel(label, desc);
                this.FrameLabelSet.addLabel(frameLabel);
            end
            this.IsChanged = true;
        end        
    end
    
    methods(Abstract)
        exportLabelAnnotations(this)
    end
    
    methods(Abstract, Access=protected)
        addData(this)
    end
    
    methods(Abstract, Hidden)
        saveobj(this)
    end
    
    methods(Abstract, Static, Hidden)
        loadobj(this)
    end
    
end