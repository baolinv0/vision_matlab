classdef AlgorithmLabelChecker < handle
    
    % Copyright 2016-2017 The MathWorks, Inc.
    
    properties
        % Algorithm                 An instance of an AutomationAlgorithm
        Algorithm
        
        % ROILabelDefinitions       A labelDef struct of all ROI label
        %                           definitions
        ROILabelDefinitions
        
        % FrameLabelDefinitions     A labelDef struct of all Frame label
        % definitions
        FrameLabelDefinitions
        
        % ValidROILabelNames        A cell array of valid ROI label names
        ValidROILabelNames
        
        % InvalidROILabelIndices    An array of indices to invalid ROI label
        %                           definitions
        InvalidROILabelIndices
        
        % ValidFrameLabelNames      A cell array of valid Frame label names
        ValidFrameLabelNames
        
        %InvalidFrameLabelIndices   An array of indices to invalid frame
        %                           label definitions
        InvalidFrameLabelIndices
        
        %ValidPixelLabelNames       A cell array of valid pixel label names
        ValidPixelLabelNames
        
        %InvalidPixelLabelNames     A cell array of invalid pixel label
        %                           names
        InvalidPixelLabelNames
    end
    
    methods
        %------------------------------------------------------------------
        % Instantiate an object for managing label validity checks. The
        % object computes valid label definitions for the algorithm at
        % construction.
        %------------------------------------------------------------------
        function this = AlgorithmLabelChecker(algorithm, roiDefs, frameDefs)
            
            this.Algorithm              = algorithm;
            this.ROILabelDefinitions    = toROILabelDefs(this, roiDefs);
            this.FrameLabelDefinitions  = toFrameLabelDefs(this, frameDefs);
            
            computeValidLabelDefinitions(this);
        end
        
        %------------------------------------------------------------------
        % Returns ROI labels consistent with algorithm label validity
        % criteria.
        %------------------------------------------------------------------
        function [validLabels,validIdx] = computeValidROIs(this, labels, currentTime)
            
            hasTemporalContext = nargin>2;
            
            validIdx = arrayfun(@(s)any(strcmpi(s.Label, this.ValidROILabelNames)), labels);
            
            labels = labels(validIdx);
            
            validLabels = repmat(struct('Type',[],'Name','','Position',[], 'Time', []), numel(labels), 1);
            for n = 1 : numel(validLabels)
                validLabels(n).Type      = labels(n).Shape;
                validLabels(n).Name      = labels(n).Label;
                validLabels(n).Position  = labels(n).Position;
                
                % Add time only if algorithm has temporal context
                if hasTemporalContext
                    validLabels(n).Time  = currentTime;
                end
            end
        end
        
        %------------------------------------------------------------------
        % Returns flag indicating whether selected algorithm is consistent
        % with label definitions provided.
        %------------------------------------------------------------------
        function TF = isAlgorithmSelectionConsistent(this)
            
            TF = ~(isempty(this.ValidROILabelNames) && isempty(this.ValidFrameLabelNames));
        end
        
        %------------------------------------------------------------------
        % Returns flag indicating whether selected algorithm has any valid
        % pixel labels.
        %------------------------------------------------------------------
        function TF = hasPixelLabels(this)
            
            types = [this.ROILabelDefinitions.Type];
            
            % Find all valid label types.
            validIdx = true(size(types));
            validIdx(this.InvalidROILabelIndices) = 0;
            validTypes = types(validIdx);
            
            % If any of them are pixel labels, return true.
            TF = any(validTypes==labelType.PixelLabel);
        end
        
        %------------------------------------------------------------------
        % Returns flag indicating whether a selected algorithm has only
        % pixel label definitions declared valid.
        %------------------------------------------------------------------
        function TF = onlyPixelLabels(this)
            
            types = [this.ROILabelDefinitions.Type];
            
            % Find all valid label types.
            validIdx = true(size(types));
            validIdx(this.InvalidROILabelIndices) = 0;
            validTypes = types(validIdx);
            
            TF = all(validTypes==labelType.PixelLabel);
        end
        
        %------------------------------------------------------------------
        % Open algorithm class in editor at opening line of
        % checkLabelDefinition
        %------------------------------------------------------------------
        function openCheckLabelDefinition(this)
            
            algClass = class(this.Algorithm);
            filePath = which(algClass);
            
            if isempty(filePath)
                % Try to open the file through class name.
                edit(algClass);
            else
                % Open the function
                matlab.desktop.editor.openAndGoToFunction(filePath, 'checkLabelDefinition');
            end
        end
        
        %------------------------------------------------------------------
        % Returns flag indicating whether a selected algorithm has all
        % available pixel label definitions declared valid.
        %------------------------------------------------------------------
        function TF = allPixelLabels(this)
            
            TF = isempty(this.InvalidPixelLabelNames);
        end
        
        %------------------------------------------------------------------
        function pixelLabelNames = get.ValidPixelLabelNames(this)
            allValidROINames = this.ValidROILabelNames;
            pixelLabelNames = allValidROINames([this.ROILabelDefinitions.Type] == labelType.PixelLabel);
        end
        
        %------------------------------------------------------------------
        function invalidPixelLabelNames = get.InvalidPixelLabelNames(this)
            
            allPixelLabelNames = {this.ROILabelDefinitions( [this.ROILabelDefinitions.Type] == labelType.PixelLabel ).Name};
            validROILabelNames = this.ValidROILabelNames;
            
            invalidPixelLabelNames = setdiff(allPixelLabelNames, validROILabelNames);
        end
    end
    
    methods (Access = private)
        %------------------------------------------------------------------
        function defs = toROILabelDefs(~, roiLabelList)
            % Convert ROILabel objects to label defs
            
            defs = repmat(struct('Type',[],'Name',[]), numel(roiLabelList), 1);
            for n = 1 : numel(roiLabelList)
                defs(n).Type = roiLabelList(n).ROI;
                defs(n).Name = roiLabelList(n).Label;
                
                % Add a field for pixel label ID if a valid pixel label is
                % part of the roilabelList.
                if defs(n).Type == labelType.PixelLabel && ~isempty(roiLabelList(n).PixelLabelID)
                    defs(n).PixelLabelID = roiLabelList(n).PixelLabelID;
                end
            end
        end
        
        %------------------------------------------------------------------
        function defs = toFrameLabelDefs(~, frameLabelList)
            % Convert FrameLabel objects to label defs
            
            labType = labelType.Scene;
            
            defs = repmat(struct('Type',[],'Name',[]), numel(frameLabelList), 1);
            for n = 1 : numel(frameLabelList)
                defs(n).Type = labType;
                defs(n).Name = frameLabelList(n).Label;
            end
        end
        
        %------------------------------------------------------------------
        function computeValidLabelDefinitions(this)
            % Find the list of labels that pass the algorithms label
            % validity test.
            
            algorithm = this.Algorithm;
            
            isValidROILabel = false(size(this.ROILabelDefinitions));
            for n = 1 : numel(this.ROILabelDefinitions)
                isValidROILabel(n) = checkLabelDefinition(algorithm, this.ROILabelDefinitions(n));
            end
            
            isValidFrameLabel = false(size(this.FrameLabelDefinitions));
            for n = 1 : numel(this.FrameLabelDefinitions)
               isValidFrameLabel(n) = checkLabelDefinition(algorithm, this.FrameLabelDefinitions(n));
            end
            
            this.ValidROILabelNames = {this.ROILabelDefinitions(isValidROILabel).Name};
            this.ValidFrameLabelNames = {this.FrameLabelDefinitions(isValidFrameLabel).Name};
            
            this.InvalidROILabelIndices = find(~isValidROILabel);
            this.InvalidFrameLabelIndices = find(~isValidFrameLabel);
        end
    end
    
end