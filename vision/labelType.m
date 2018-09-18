classdef labelType < uint8
    %labelType Enumeration of supported label types
    %   labelType creates an enumeration specifying the type of label that
    %   can be used to define labels in the groundTruth object.
    %
    %   labelType enumerations:
    %   Rectangle   - Label marked as a rectangular region of interest (ROI)
    %   Line        - Label marked as a polyline region of interest (ROI)
    %   Scene       - Label marked on a frame or interval of frames
    %   Custom      - Custom label type
    %   PixelLabel  - Label marked as a pixel labeled region of interest(ROI)
    %
    %   labelType methods:
    %   isROI       - Determine if label type is an ROI label
    %   isScene     - Determine if label type is a Scene label
    %   isCustom    - Determine if label type is a Custom label
    %
    %
    %   Example - Create label definitions table
    %   ----------------------------------------
    %   % Define label names
    %   Name = {'Car'; 'LeftLaneMarker'; 'RightLaneMarker'; 'Sunny'};
    %
    %   % Define label types
    %   Type = labelType({'Rectangle'; 'Line'; 'Line'; 'Scene'});
    %
    %   % Create label definitions
    %   labelDefs = table(Name, Type)
    %
    %   % List ROI label names
    %   roiLabelIndices = isROI(labelDefs.Type);
    %   roiLabelNames = labelDefs.Name(roiLabelIndices)
    %
    %   % List Scene label names
    %   sceneLabelIndices = isScene(labelDefs.Type);
    %   sceneLabelNames = labelDefs.Name(sceneLabelIndices)
    %
    %
    % See also groundTruth.
    
    % Copyright 2016 The MathWorks, Inc.
    
    enumeration
        %Rectangle Rectangular region of interest label type
        %   Rectangle specifies a label marked as a rectangular region of
        %   interest (ROI).
        Rectangle   (0)
        
        %Line Polyline region of interest label type
        %   Line specifies a label marked as a polyline region of interest
        %   (ROI). A polyline is a continuous line composed of one or more
        %   line segments.
        Line        (1)
        
        %PixelLabel Pixel labeled region of interest
        %   PixelLabel specifies a label marked as a pixel labeled region
        %   of interest (ROI). Pixel labeled ROI provide labels for every
        %   pixel within the ROI and is typically used to label a group of
        %   neighboring pixels that share the same label category.
        PixelLabel  (4)
        
        %Scene Scene label type
        %   Scene specifies a label marked on a frame or interval of
        %   frames.
        Scene       (2)
        
        %Custom Custom label type
        %   Custom specifies a custom label type.
        Custom      (3)
    end
    
    methods
        %------------------------------------------------------------------
        function TF = isROI(this)
            %isROI Determine if label type is an ROI label type.
            %   tf = isROI(labelTypes) returns true if labelTypes is an ROI
            %   label type and false otherwise. An ROI label type is either
            %   Rectangle, Line, or PixelLabel.
            
            TF = (this==labelType.Rectangle) | (this==labelType.Line) ...
                | (this == labelType.PixelLabel);
        end
        
        %------------------------------------------------------------------
        function TF = isScene(this)
            %isScene Determine if label type is a Scene label type.
            %   tf = isScene(labelTypes) returns true if labelTypes is a
            %   Scene label type and false otherwise.
            
            TF = this==labelType.Scene;
        end
        
        %------------------------------------------------------------------
        function TF = isCustom(this)
            %isCustom Determine if label type is a Custom label type.
            %   tf = isCustom(labelTypes) returns true if labelTypes is a
            %   Custom label type and false otherwise.
            
            TF = this==labelType.Custom;
        end
        
    end

end