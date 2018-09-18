classdef ROILabeler < handle & matlab.mixin.Heterogeneous
    properties(SetAccess = private, GetAccess = public)
        %UserIsDrawing A logical. Should be true when using is drawing and
        %              false otherwise. It should be toggled by
        %              onButtonDown().
        UserIsDrawing = false;
    end
    
    properties
        %SelectedLabel A vision.internal.labeler.ROILabel. Defines the
        %              selected ROI label type (name, color, etc).
        SelectedLabel
       
        %CopyCallbackFcn copy call back function.
        CopyCallbackFcn
        
        %CutCallbackFcn cut call back function. 
        CutCallbackFcn
    end
    
    properties(Access = protected)
        %ImageHandle Handle to the image handle the labeler should work
        %with.
        ImageHandle
        
        %AxesHandle Handle to the axes that the labeler should work with.
        %Should contain the ImageHandle.
        AxesHandle
        
        %Figure Handle to the figure that the labeler should work with.
        %Should contain the AxesHandle.
        Figure
        
        %ShowLabelName A boolean. Whether or not a label name should be
        %              displayed for the ROI. ROI types that do not have
        %              label names should ignore this property.
        ShowLabelName = true
    end
    
    events
        %LabelIsChanged Event issued when label data is changed and should
        %               be written into session.
        LabelIsChanged
        
        %ImageIsChanged Event for when the image needs to be redrawn.
        ImageIsChanged
        
        %UpdateUndoRedoQAB Event to send undo/redo state change message for
        % Quick Access Bar (QAB).
        UpdateUndoRedoQAB
        
    end
    
    methods
        %------------------------------------------------------------------
        function set.SelectedLabel(this, value)
            assert(isa(value,'vision.internal.labeler.ROILabel'))
            this.SelectedLabel = value;
        end
        
        %------------------------------------------------------------------
        function drawLabels(~, varargin)
            % empty on purpose.
        end
        
        %------------------------------------------------------------------
        function data = preprocessImageData(~, data)
            % A method for a labeler to pre-process the image data. 
        end
        
        %------------------------------------------------------------------
        % finalize(this) Perform any final actions to complete the labelers
        % work on the current image.
        %------------------------------------------------------------------
        function finalize(~, varargin)
            % empty on purpose. Implement this in concrete instances to
            % perform special operations.
        end
        
        %------------------------------------------------------------------
        function pasteSelectedROIs(~, ~)
            % pasteSelectedROIs(this, roisToPaste)
            % empty on purpose. Implement this in concrete instances to do
            % specific paste operations.
        end
        
        %------------------------------------------------------------------
        function selectAll(~)
            % selectAll(this)
            % empty on purpose. Implement this in concrete instances to do
            % select all.
        end
        
        %------------------------------------------------------------------
        function attachToImage(this, fig, ax, imageHandle)
            % Attach handles to this labeler.
            this.ImageHandle = imageHandle;
            this.AxesHandle = ax;
            this.Figure = fig;
        end
    end
    
    methods(Access = protected)
        
        %------------------------------------------------------------------
        % Called by clients when an ROI data changes. For instance,
        % different rectangle ROI is selected.
        %------------------------------------------------------------------
        function updateLabel(this,roiLabelData)
            
            assert(isa(roiLabelData, 'vision.internal.labeler.ROILabel'))
            
            this.SelectedLabel = roiLabelData;
           
        end
        
        %------------------------------------------------------------------
        function showLabelNames(thisArray)
            for i = 1:numel(thisArray)
                thisArray(i).ShowLabelName = true;
            end
        end
    end
    
    methods(Abstract, Access = protected)
        
        %------------------------------------------------------------------
        % Callback method attached to the ImageHandle ButtonDownFcn
        %------------------------------------------------------------------
        onButtonDown(this)
       
        %------------------------------------------------------------------
        % Return whether or not labeler has things to undo.
        %------------------------------------------------------------------
        canUndo(this)
        
        %------------------------------------------------------------------
        % Return whether or not labeler has things to redo.
        %------------------------------------------------------------------
        canRedo(this)
    end
    
    methods(Sealed)
        
        %------------------------------------------------------------------
        function activate(this, fig, ax, imageHandle)
            % start this labeler by providing an image handle.
            this.attachToImage(fig, ax, imageHandle);
            
            % activate button down function
            set(this.ImageHandle,'ButtonDownFcn', @this.onButtonDownWrapper);  
            
            % update QAB undo/redo
            data = vision.internal.labeler.tool.UndoRedoStateEvent(...
                this.canUndo(), this.canRedo());
            
            notify(this, 'UpdateUndoRedoQAB', data);
        end
        
        %------------------------------------------------------------------
        function deactivate(this)
            % stop this labeler.
            set(this.ImageHandle,'ButtonDownFcn', []);
            
            % update QAB undo/redo
            data = vision.internal.labeler.tool.UndoRedoStateEvent(...
                false, false);
            
            notify(this, 'UpdateUndoRedoQAB', data);
        end 
    end
    
    %----------------------------------------------------------------------
    methods(Access = private)
        function onButtonDownWrapper(this, varargin)
            this.UserIsDrawing = true;
            
            this.onButtonDown(varargin{:});
            
            this.UserIsDrawing = false;
        end
    end
    
end