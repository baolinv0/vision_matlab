%FrameAnnotationSet holds annotations for Frame Labels in the Video Labeler
%App.

% Copyright 2016-2017 The MathWorks, Inc.

classdef FrameAnnotationSet < handle
    
    properties (Access = private)
        %LabelSet
        %   Handle to FrameLabelSet object
        LabelSet
        
        %AnnotationStruct
        %   Struct array holding actual annotations
        %   Fields of the struct array for each time stamp are:
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
        
        %ValidFrameLabelNames
        %   Cellstr of valid frame labels for an algorithm session
        ValidFrameLabelNames
    end
    
    methods
        %------------------------------------------------------------------
        function this = FrameAnnotationSet(labelSet)
            
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
            addlistener(this.LabelSet, 'LabelChanged', @this.onLabelChanged);
        end
        
        %------------------------------------------------------------------
        function appendAnnotation(this, index, labelNames, positions)
            % append to struct. preserves existing annotations.           
            addAnnotation(this, index, labelNames, positions)
        end
        
        %------------------------------------------------------------------
        function addAnnotation(this, index, labelNames, labelVals)
            %addAnnotation adds annotation to annotation structure.
            %   addAnnotation(annSet, ts, names) adds annotations at time
            %   stamp ts to label specified by cell array names. ts can be
            %   a scalar, implying label specified for a single frame or a
            %   two-element vector, implying label specified for a range of
            %   frames.
            
            if ~isscalar(index)
                index = index(1) : index(2);
            end
            
            labelNames = cellstr(labelNames);
            
            % Initialize a structure (or struct-array) with empty fields.
            s = this.AnnotationStruct(index);

            % Fill struct with annotations
            if nargin==3
                for n = 1 : numel(labelNames)
                    [s.(labelNames{n})] = deal(true);
                end
            else
                for n = 1 : numel(labelNames)
                    [s.(labelNames{n})] = deal(labelVals{n});
                end
            end
            
            % Update the annotation struct
            this.AnnotationStruct(index) = s;
        end
        
        %------------------------------------------------------------------
        function removeAnnotation(this, index, labelNames)
            %removeAnnotation removes annotation from annotation structure.
            %   removeAnnotation(annSet, ts, name) removes annotation with
            %   label specified by name from time stamp ts. ts can be a
            %   scalar, implying label specified for a single frame or a
            %   two-element vector, implying label specified for a range of
            %   frames.
            
            if ~isscalar(index)
                index = index(1) : index(2);
            end
            
            labelNames = cellstr(labelNames);
            
            % Initialize a structure (or struct-array) with empty fields.
            s = this.AnnotationStruct(index);
            
            % Fill struct with absent annotations
            for n = 1 : numel(labelNames)
                [s.(labelNames{n})] = deal(false);
            end
            
            % Update the annotation struct
            this.AnnotationStruct(index) = s;
        end
        
        %------------------------------------------------------------------
        function removeAllAnnotations(this, indices)
            this.AnnotationStruct(indices) = [];
            this.NumImages = this.NumImages - numel(indices);
        end
        
        %------------------------------------------------------------------
        function [names, colors, ids] = queryAnnotation(this, index)
            %queryAnnotation queries stored annotations.
            %   [names, colors] = queryAnnotation(annSet, ts) returns label
            %   names (names) and colors stored for timestamp ts.
            
            assert(isscalar(index),'Expected time index to be a scalar');
            
            s = this.AnnotationStruct(index);
            
            allLabels = fieldnames(s);
            
            names   = {};
            colors  = {};
            ids     = [];
            
            if isempty(s)
                return;
            end
            
            for n = 1 : numel(allLabels)
                label = allLabels{n};
                if s.(label)
                    names{end+1} = label; %#ok<AGROW>
                    
                    labelID = this.LabelSet.labelNameToID(label);
                    colors{end+1} = this.LabelSet.queryLabelColor(labelID); %#ok<AGROW>
                    ids(end+1) = labelID; %#ok<AGROW>
                end
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
                numAnnotations.(label) = [this.AnnotationStruct(indices).(label)];
            end
        end
        
        %------------------------------------------------------------------
        function T = export2table(this, timeVector)
            %export2table exports annotations to a timetable.  Empty
            %timeVector means image collection w/o timestamps.
            
            assert(isempty(timeVector) || numel(timeVector)==this.NumImages, 'Expected timeVector and annotation set length to be consistent.')
            
			T = struct2table(this.AnnotationStruct, 'AsArray', true);
            
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
        function replace(this, indices, validFrameLabelNames)
            
            if nargin>2
                this.ValidFrameLabelNames = validFrameLabelNames;
            end
            
            % Construct an empty scalar struct with the same fields as the
            % annotation struct array.
            fieldNames = fieldnames(this.AnnotationStruct);
            fieldVals  = repmat({false}, size(fieldNames));
            annStruct  = cell2struct(fieldVals, fieldNames, 1);
            
            % Replace the annotation struct with this empty struct for all
            % time stamps in the specified interval.
            this.AnnotationStruct(indices) = repmat(annStruct, size(indices));
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
        function mergeWithCache(this, indices)
            
            % Save newly created annotations
            newAnnotationsInterval = this.AnnotationStruct(indices);
            
            % Uncache annotations
            uncache(this);
            
            % Merge newly created annotations with uncached annotations
            % only over frame labels that were valid for the algorithm
            % being run.
            validFieldNames = this.ValidFrameLabelNames;
            
            if isempty(validFieldNames)
                % Nothing to merge, there were no valid frame labels in the
                % algorithm
                return;
            end
            
            for idx = 1 : numel(indices)
                
                oldAnnotations = this.AnnotationStruct(indices(idx));
                newAnnotations = newAnnotationsInterval(idx);
                
                for n = 1 : numel(validFieldNames)
                    fName = validFieldNames{n};
                    oldAnnotations.(fName) = newAnnotations.(fName);
                end
                this.AnnotationStruct(idx) = oldAnnotations;
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
        function onLabelAdded(this, ~,data)
            
            added = this.LabelSet.queryLabel(data.Label);
            
            % Add a new field to the annotation struct with the name of the
            % added label, initialized to false.
            [this.AnnotationStruct(1:end).(added.Label)] = deal(false);
        end
        
        function onLabelRemoved(this,~,data)
            
            removed = this.LabelSet.queryLabel(data.Label);
            
            % Remove fields from annotation struct.
            this.AnnotationStruct = rmfield(this.AnnotationStruct, removed.Label);
        end
        
        function onLabelChanged(this,~,data)
            
            changed = this.LabelSet.queryLabel(data.Label);
            oldLabel = data.OldLabel;
            
            % Add a field with new label name.
            this.AnnotationStruct.(changed.Label) = this.AnnotationStruct.(oldLabel);
            
            % Remove field with old label name.
            this.AnnotationStruct = rmfield(this.AnnotationStruct, changed.Label);
        end
    end
    
    methods (Access = private)
        %------------------------------------------------------------------
        function initialize(this, labelSet, numImages)
            
            % Initialize Annotations object with FrameLabelSet object
            % containing Frame Label definitions.
            this.LabelSet = labelSet;
            
            % Add fields to struct for each label
            this.AnnotationStruct = struct();
            
            for n = 1 : labelSet.NumLabels
                labelName = labelSet.labelIDToName(n);
                this.AnnotationStruct(end).(labelName) = false;
            end
            
            if nargin>2
                this.NumImages  = numImages;
                this.AnnotationStruct = repmat(this.AnnotationStruct, numImages, 1);
            else
                this.NumImages  = 0;
            end
        end
        
    end
end