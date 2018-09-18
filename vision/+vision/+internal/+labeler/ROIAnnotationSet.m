%ROIAnnotationSet holds annotations for ROI Labels in the Video Labeler App

% Copyright 2017 The MathWorks, Inc.

classdef ROIAnnotationSet < handle
    
    properties (Access = private)
        %LabelSet
        %   Handle to ROILabelSet object
        LabelSet
        
        %AnnotationStruct
        %   Struct array holding actual annotations
        %   Fields of the struct array are:
        %   * <Label_1>
        %   * <Label_2>
        %   * ...
        AnnotationStruct
        
        %NumImages
        %   Number of images
        NumImages
        
        %Cache
        %   Cache of annotation struct
        Cache
    end
    
    methods
        %------------------------------------------------------------------
        function this = ROIAnnotationSet(labelSet)
            
            initialize(this, labelSet);
            configure(this);
        end
        
        %------------------------------------------------------------------
        function addSourceInformation(this, numImages)
            initialize(this, this.LabelSet, numImages);
        end
        
        %------------------------------------------------------------------
        function appendSourceInformation(this,  numImages)
            if this.NumImages  == 0
                addSourceInformation(this, numImages);
            else
                numberToAppend = numImages - this.NumImages;
                this.NumImages = numImages;
                structToAppend = structfun(@(x) [], this.AnnotationStruct(end), 'UniformOutput', false);
                this.AnnotationStruct = [this.AnnotationStruct ; repmat(structToAppend, numberToAppend, 1)];
            end
        end
        
        %------------------------------------------------------------------
        function numImages = getNumImages(this)
            numImages = this.NumImages;
        end
        
        %------------------------------------------------------------------
        function configure(this)
            
            % Configure object to update annotation structure when LabelSet
            % is updated.
            addlistener(this.LabelSet, 'LabelAdded', @this.onLabelAdded);
            addlistener(this.LabelSet, 'LabelRemoved', @this.onLabelRemoved);
            addlistener(this.LabelSet, 'PixelLabelRemoved', @this.onPixelLabelRemoved);
            addlistener(this.LabelSet, 'LabelChanged', @this.onLabelChanged);
        end
        
        %------------------------------------------------------------------
        function addAnnotation(this, index, labelNames, positions, doAppend)
            
            if nargin == 4
                doAppend = false;
            end
            
            index = max(index,1);
            
            if ~iscell(positions)
                positions = {positions};
            end
            
            if ~isempty(positions) && (ischar(positions{1}) || isstring(positions{1}))
                % Case when position contains path to label matrix file
                if ~isfield(this.AnnotationStruct,'PixelLabelData')
                    % Add field for label matrix filename
                    this.AnnotationStruct(end).PixelLabelData = '';
                end
                
                s = this.AnnotationStruct(index);
                s.PixelLabelData = positions{1};
            else
                labelNames = cellstr(labelNames);
                
                % Initialize a structure with empty fields, except timestamp
                s = this.AnnotationStruct(index);
                
                if ~doAppend
                    % Clear struct for reset and add behavior.
                    s = structfun(@(x)[],s,'UniformOutput',false);
                end
                
                if isfield(this.AnnotationStruct,'PixelLabelData')
                    labelMatrixValue = this.AnnotationStruct(index).PixelLabelData;
                    s.PixelLabelData = labelMatrixValue;
                end
                
                
                % Fill struct with annotations
                for n = 1 : numel(labelNames)
                    roiPos = positions{n};
                    if ~isempty(roiPos)
                        labelID = this.LabelSet.labelNameToID(labelNames{n});
                        labelShape = this.LabelSet.queryLabelShape(labelID);
                        
                        switch labelShape
                            case labelType.Line
                                %Line is stored as a Mx1 cell array of Nx2 matrices
                                if iscell(roiPos)
                                    for m = 1 : numel(roiPos)
                                        s.(labelNames{n}){end+1, 1} = roiPos{m};
                                    end
                                else
                                    s.(labelNames{n}){end+1, 1} = roiPos;
                                end
                            case labelType.Rectangle
                                %Rect is stored as a Mx4 matrix
                                %This loop is necessary because Session may load
                                %all Mx4 ROIs in one go while VideoDisplay may load
                                %this one at a time incrementally
                                for inx=1:size(roiPos, 1)
                                    s.(labelNames{n})(end+1, :) = roiPos(inx, :);
                                end
                            case labelType.PixelLabel
                                % No-op
                            otherwise
                                error('Unhandled Case');
                        end
                    end
                end   
            end
            
            % Update the annotation struct
            this.AnnotationStruct(index) = s;
            
        end
        
        %------------------------------------------------------------------
        function appendAnnotation(this, index, labelNames, positions)
            doAppend = true;
            addAnnotation(this, index, labelNames, positions, doAppend)
        end
        
        %------------------------------------------------------------------
        function removeAnnotation(this, index, labelName, dataIndex)
            
            index = max(index,1);
            
            % Remove annotation
            annotations = this.AnnotationStruct(index).(labelName);
            annotations(dataIndex,:) = [];
            
            % Preserve size of empties
            if isempty(annotations)
                annotations = [];
            end
            this.AnnotationStruct(index).(labelName) = annotations;
        end
        
        %------------------------------------------------------------------
        function removeAllAnnotations(this, indices)
            this.AnnotationStruct(indices) = [];
            this.NumImages = this.NumImages - numel(indices);
        end
        
        %------------------------------------------------------------------
        function [allPositions, allNames, allColors, allShapes] = queryAnnotationsInInterval(this, indices)
            
            indices = max(indices, 1);
            
            allPositions   = repmat({{}},size(indices));
            allNames       = repmat({{}},size(indices));
            allColors      = repmat({{}},size(indices));
            allShapes      = repmat({labelType([])},size(indices));
            
            % Query struct containing annotations
            allS = this.AnnotationStruct(indices);
            
            % Get label names
            allLabelNames = fieldnames(allS);
            
            numLabels = numel(allLabelNames);
            labelIDs    = cellfun(@(lname)this.LabelSet.labelNameToID(lname), allLabelNames, 'UniformOutput', false);
            labelColors = cellfun(@(lid)this.LabelSet.queryLabelColor(lid), labelIDs, 'UniformOutput', false);
            labelShapes = cellfun(@(lid)this.LabelSet.queryLabelShape(lid), labelIDs, 'UniformOutput', false);
            for n = 1 : numel(indices)
                s = allS(n);
                
                if isempty(s)
                    continue;
                end
                
                positions   = allPositions{n};
                names       = allNames{n};
                colors      = allColors{n};
                shapes      = allShapes{n};
                
                for lInx = 1 : numLabels
                    label   = allLabelNames{lInx};
                    roiPos  = s.(label);
                    if ~isempty(roiPos)
                        positions{end+1}    = roiPos;           %#ok<AGROW>
                        names{end+1}        = label;            %#ok<AGROW>
                        colors{end+1}       = labelColors{lInx};%#ok<AGROW>
                        shapes{end+1}       = labelShapes{lInx};%#ok<AGROW>
                    end
                end
                
                allPositions{n} = positions;
                allNames{n}     = names;
                allColors{n}    = colors;
                allShapes{n}    = shapes;
            end
            
        end
        
        %------------------------------------------------------------------
        function [numAnnotations] = querySummary(this, labelNames, indices)
            indices = max(indices, 1);
            % Get label names
            numLabels = numel(labelNames);
            
            numAnnotations = struct();
            
            for n = 1:numLabels
                label = labelNames{n};
                numAnnotations.(label) = cellfun(@(x) size(x,1),{this.AnnotationStruct(indices).(label)});
            end
        end
        
        %------------------------------------------------------------------
        function [positions, names, colors, shapes] = queryAnnotation(this, index)
            
            index = max(index,1);
            
            positions   = {};
            names       = {};
            colors      = {};
            shapes      = labelType([]);
            
            % Query struct containing annotations
            s = this.AnnotationStruct(index);
            
            if isempty(s)
                return;
            end
            
            % Get label names
            allLabelNames = fieldnames(s);
            
            for lInx=1:numel(allLabelNames)
                label = allLabelNames{lInx};
                if ~strcmp(label,'PixelLabelData')
                    roiPos = s.(label);
                    if ~isempty(roiPos)
                        %Get Label Positions
                        positions{end+1} = roiPos; %#ok<AGROW>
                        names{end+1} = label; %#ok<AGROW>
                        %Get Label Colors
                        labelID = this.LabelSet.labelNameToID(label);
                        labelColor = this.LabelSet.queryLabelColor(labelID);
                        colors{end+1} = labelColor; %#ok<AGROW>
                        %Get Label Shape
                        labelShape = this.LabelSet.queryLabelShape(labelID);
                        shapes(end+1) = labelShape; %#ok<AGROW>
                    end
                end
            end
        end
        
        function labelMatrixValue = getPixelLabelAnnotation(this, index)
            
            if isfield(this.AnnotationStruct,'PixelLabelData')
                labelMatrixValue = this.AnnotationStruct(index).PixelLabelData;
            else
                labelMatrixValue = '';
            end
            
        end
        
        function setPixelLabelAnnotation(this, index, labelPath)
            
            if ~isfield(this.AnnotationStruct,'PixelLabelData')
                % Add field for label matrix filename
                this.AnnotationStruct(end).PixelLabelData = '';
            end
            
            s = this.AnnotationStruct(index);
            s.PixelLabelData = labelPath;
            this.AnnotationStruct(index) = s;
        end
        
        %------------------------------------------------------------------
        function T = export2table(this, timeVector)
            %export2table exports annotations to a timetable. Empty
            %timeVector means image collection w/o timestamps.
            
            assert(isempty(timeVector) || numel(timeVector)==this.NumImages, 'Expected timeVector and annotation set length to be consistent.')
            
            T = struct2table(this.AnnotationStruct, 'AsArray', true);
            
            % Ensure all non-char entries in PixelLabelData are ''
            if isfield(this.AnnotationStruct, 'PixelLabelData')
                notChar = cellfun(@(x)~ischar(x), T.PixelLabelData);
                T.PixelLabelData(notChar) = {''};
            end         
            
            if ~isempty(timeVector)
                % Construct nice-looking duration vector
                numTimes = this.NumImages;
                HoursMins = zeros(numTimes,2);
                HoursMinsSecs = horzcat(HoursMins,timeVector);
                
                maxTime = timeVector(end);
                
                displayFormat = vision.internal.labeler.getNiceDurationFormat(maxTime);
                durationVector = duration(HoursMinsSecs, 'Format', displayFormat);
                
                % Convert to time table
                T = table2timetable(T, 'RowTimes', durationVector);
            end
        end
        
        %------------------------------------------------------------------
        % Cache current state of annotations. This is needed to cache state
        % of annotations before entering algorithm mode.
        %------------------------------------------------------------------
        function cache(this)
            
            this.Cache.AnnotationStruct = this.AnnotationStruct;
        end
        
        %------------------------------------------------------------------
        % Replace annotations with empty annotations over the time interval
        % indices specified. This is expected to be invoked only after a
        % call to cache().
        %------------------------------------------------------------------
        function replace(this, indices, currentIndex, labelNames, positions)
            
            % Construct an empty scalar struct with the same fields as the
            % annotation struct array.
            fieldNames = fieldnames(this.AnnotationStruct);
            annStruct = cell2struct(cell(size(fieldNames)), fieldNames, 1);
            
            % Replace the annotation struct with this empty struct for all
            % time stamps in the specified interval.
            this.AnnotationStruct(indices) = repmat(annStruct, size(indices));
            
            if nargin>2
                if ~iscell(labelNames)
                    labelNames = {labelNames};
                end
                
                addAnnotation(this, currentIndex, labelNames, positions);
            end
        end
        
        %------------------------------------------------------------------
        % Reload annotations from provided cache of annotation struct. This
        % is used to reload previous state of annotations if algorithm
        % updates are not to be applied.
        %------------------------------------------------------------------
        function uncache(this)
            
            if isempty(this.Cache)
                initialize(this, this.LabelSet);
            else
                this.AnnotationStruct = this.Cache.AnnotationStruct;
            end
        end
        
        %------------------------------------------------------------------
        % Merge annotations with cached annotations
        %------------------------------------------------------------------
        function mergeWithCache(this, indices, unimportedROIs)
            
            % Save newly created annotations
            newAnnotationsInterval = this.AnnotationStruct(indices);
            
            % Uncache annotations
            uncache(this);
            
            % Handle the first frame of the interval differently. First add
            % all the ROIs that were not imported for the algorithm
            % workflow. These include ROIs belonging to invalid label
            % definitions as well as ROIs belongint to valid label
            % definitions that were not selected. Then add whatever new
            % annotations came from the algorithm.
            fieldNames = fieldnames(this.AnnotationStruct);
            
            if nargin<3
                
                % Merge newly created annotations with uncached annotations
                for idx = 1 : numel(indices)
                    
                    oldAnnotations = this.AnnotationStruct(indices(idx));
                    newAnnotations = newAnnotationsInterval(idx);
                    
                    for n = 1 : numel(fieldNames)
                        fName = fieldNames{n};
                        if ~strcmp(fName,'PixelLabelData')
                            oldAnnotations.(fName) = cat(1, oldAnnotations.(fName), newAnnotations.(fName));
                        end
                    end
                    this.AnnotationStruct(indices(idx)) = oldAnnotations;
                end
            else
                
                % First import all the ROIs that weren't imported into the
                % algorithm workflow.
                oldAnnotations = cell2struct( cell(size(fieldNames)), fieldNames );
                for n = 1 : numel(unimportedROIs)
                    labelName   = unimportedROIs(n).Label;
                    labelPos    = unimportedROIs(n).Position;
                    labelShape  = unimportedROIs(n).Shape;
                    
                    switch labelShape
                        case labelType.Rectangle
                            oldAnnotations.(labelName) = cat(1, oldAnnotations.(labelName), labelPos);
                        case labelType.Line
                            if ~iscell(labelPos)
                                labelPos = {labelPos};
                            end
                            oldAnnotations.(labelName) = cat(1, oldAnnotations.(labelName), labelPos);
                        otherwise
                            assert(false, 'Invalid label type.');
                    end
                end
                
                % Add the new annotaions that were added for the first frame
                % during the algorithm workflow.
                newAnnotations = newAnnotationsInterval(1);
                for n = 1 : numel(fieldNames)
                    fName = fieldNames{n};
                    if ~strcmp(fName,'PixelLabelData')
                        oldAnnotations.(fName) = cat(1, oldAnnotations.(fName), newAnnotations.(fName));
                    end
                end
                this.AnnotationStruct(indices(1)) = oldAnnotations;
                
                % Merge newly created annotations with uncached annotations
                for idx = 2 : numel(indices)
                    
                    oldAnnotations = this.AnnotationStruct(indices(idx));
                    newAnnotations = newAnnotationsInterval(idx);
                    
                    for n = 1 : numel(fieldNames)
                        fName = fieldNames{n};
                        if ~strcmp(fName,'PixelLabelData')
                            oldAnnotations.(fName) = cat(1, oldAnnotations.(fName), newAnnotations.(fName));
                        end
                    end
                    this.AnnotationStruct(indices(idx)) = oldAnnotations;
                end
                
            end
        end
    end
    
    methods (Hidden)
        %------------------------------------------------------------------
        function importAnnotationStruct(this, annStruct)
            this.AnnotationStruct = annStruct;
        end
    end
    
    %----------------------------------------------------------------------
    % Callbacks
    %----------------------------------------------------------------------
    methods (Access = protected)
        %------------------------------------------------------------------
        function onLabelAdded(this,~,data)
            
            added = this.LabelSet.queryLabel(data.Label);
            
            % Add a new field to the annotation struct with the name of the
            % added label.
            
            % Do not add field for pixel label types
            if added.ROI ~= labelType.PixelLabel
                this.AnnotationStruct(end).(added.Label) = [];
            end
        end
        
        %------------------------------------------------------------------
        function onLabelRemoved(this,~,data)
            
            removed = this.LabelSet.queryLabel(data.Label);
            
            % Remove field from annotation struct.
            this.AnnotationStruct = rmfield(this.AnnotationStruct, removed.Label);
        end
        
        %------------------------------------------------------------------
        function onLabelChanged(this,~,data)
            
            changed = this.LabelSet.queryLabel(data.Label);
            oldLabel = data.OldLabel;
            
            % Add field with new label name.
            this.AnnotationStruct.(changed.Label) = this.AnnotationStruct.(oldLabel);
            
            % Remove field with old label name.
            this.AnnotationStruct = rmfield(this.AnnotationStruct, changed.Label);
        end
        
        %------------------------------------------------------------------
        function onPixelLabelRemoved(this,varargin)
            % If PixelLabelData field exists, remove it.
            if isfield(this.AnnotationStruct,'PixelLabelData')
                this.AnnotationStruct = rmfield(this.AnnotationStruct, 'PixelLabelData');
            end
        end
    end
    
    %----------------------------------------------------------------------
    % Helpers
    %----------------------------------------------------------------------
    methods (Access = protected)
        %------------------------------------------------------------------
        function initialize(this, labelSet, numImages)
            
            % Initialize Annotations object with ROILabelSet object
            % containing ROI Label definitions.
            this.LabelSet = labelSet;
            
            % Add fields to struct for each label
            this.AnnotationStruct = struct();
            
            for n = 1 : labelSet.NumLabels
                if labelSet.DefinitionStruct(n).Type ~= labelType.PixelLabel
                    labelName = labelSet.labelIDToName(n);
                    this.AnnotationStruct(end).(labelName) = [];
                end
            end
            
            if nargin > 2
                this.NumImages  = numImages;
                this.AnnotationStruct = repmat(this.AnnotationStruct, numImages, 1);
            else
                this.NumImages  = 0;
            end
        end
        
    end
end