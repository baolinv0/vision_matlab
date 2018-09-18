
% This creates class with the parameters related to ROIs in a certain frame

% Copyright 2015-2016 The MathWorks, Inc.

classdef ROIUndoRedoParams < handle & vision.internal.labeler.tool.UndoRedo
    
    properties (SetAccess = private)
        TimeIndex
        LabelNames
        LabelPositions
        LabelColors
        LabelShapes
    end
    
    methods
        %------------------------------------------------------------------
        function this = ROIUndoRedoParams(timeIndex, labelNames, labelPositions,labelColors, labelShapes)
            this.TimeIndex = timeIndex;
            this.LabelNames = labelNames;
            this.LabelPositions = labelPositions;
            this.LabelColors = labelColors;
            this.LabelShapes = labelShapes;
        end
        
        %------------------------------------------------------------------
        function flag = isequal(obj1, obj2)
            flag = (isequal(obj1.TimeIndex,obj2.TimeIndex) && ...
                    isequal(obj1.LabelNames, obj2.LabelNames) && ...
                    isequal(obj1.LabelPositions, obj2.LabelPositions) && ...
                    isequal(obj1.LabelColors, obj2.LabelColors));
            
        end
        
        %------------------------------------------------------------------
        function execute(~)
        end
        
        %------------------------------------------------------------------
        function undo(~)
        end
    end
end