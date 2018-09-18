classdef SemanticTab < vision.internal.uitools.NewAbstractTab
    
    % Copyright 2016 The MathWorks, Inc.
    
    properties (Access = private)
        % UI
        PolygonSection
        PaintBrushSection
        FloodFillSection
        ModeSection
        LabelOpacitySection
    end
    
    methods (Access = public)
        function this = SemanticTab(tool)
            
            tabName = getString( message('vision:labeler:SemanticTabTitle') );
            this@vision.internal.uitools.NewAbstractTab(tool,tabName);
            
            this.createWidgets();
            this.installListeners();
            
            % Initialize tab to have polygon button pressed
            resetDrawingTools(this)
        end
        
        function testers = getTesters(this)
            % TODO
        end
        
        function enableControls(this)
            this.PolygonSection.Section.enableAll();
            this.ModeSection.Section.enableAll();
            this.PaintBrushSection.Section.enableAll();
            this.FloodFillSection.Section.enableAll();
            this.LabelOpacitySection.Section.enableAll();
        end

        function disableControls(this)
            this.PolygonSection.Section.disableAll();
            this.ModeSection.Section.disableAll();
            this.PaintBrushSection.Section.disableAll();
            this.FloodFillSection.Section.disableAll();
            this.LabelOpacitySection.Section.disableAll();
        end
        
        function enableDrawingTools(this)
            this.PolygonSection.Section.enableAll();
            this.PaintBrushSection.Section.enableAll();
            this.FloodFillSection.Section.enableAll();
            this.LabelOpacitySection.Section.enableAll();
        end

        function disableDrawingTools(this)
            this.PolygonSection.Section.disableAll();
            this.PaintBrushSection.Section.disableAll();
            this.FloodFillSection.Section.disableAll();
            this.LabelOpacitySection.Section.disableAll();
        end
        
        function modeSelection = getModeSelection(this)
            
            if this.ModeSection.ROIButton.Value && this.ModeSection.ROIButton.Enabled
                modeSelection = 'ROI';
            elseif this.ModeSection.ZoomInButton.Value && this.ModeSection.ZoomInButton.Enabled
                modeSelection = 'ZoomIn';
            elseif this.ModeSection.ZoomOutButton.Value && this.ModeSection.ZoomOutButton.Enabled
                modeSelection = 'ZoomOut';
            elseif this.ModeSection.PanButton.Value && this.ModeSection.PanButton.Enabled
                modeSelection = 'Pan';
            else
                modeSelection = 'none';
            end
        end
        
        function enableROIButton(this, flag)
            this.ModeSection.ROIButton.Enabled = flag;
        end
        
        function resetDrawingTools(this)
            this.PolygonSection.PolygonButton.Value = true;
            this.PolygonSection.SmartPolygonButton.Value = false;
            this.PaintBrushSection.PaintBrushButton.Value = false;
            this.PaintBrushSection.EraseButton.Value = false;
            this.FloodFillSection.FloodFillButton.Value = false;
            this.LabelOpacitySection.OpacitySlider.Value = 50; % Reset slider to center position
            this.PaintBrushSection.MarkerSlider.Value = 50; % Reset slider to center position
        end
        
        function reactToModeChange(this, mode)
                        
            switch mode
                case 'ZoomIn'
                    this.ModeSection.ZoomInButton.Value = true;
                    disableDrawingTools(this);
                case 'ZoomOut'
                    this.ModeSection.ZoomOutButton.Value = true;
                    disableDrawingTools(this);
                case 'Pan'
                    this.ModeSection.PanButton.Value = true;
                    disableDrawingTools(this);
                case 'ROI'
                    this.ModeSection.ROIButton.Value = true;
                    enableDrawingTools(this);
                case 'none'
                    this.ModeSection.ZoomInButton.Value     = false;
                    this.ModeSection.ZoomOutButton.Value    = false;
                    this.ModeSection.PanButton.Value        = false;
                    this.ModeSection.ROIButton.Value        = false;
                    disableDrawingTools(this);
            end
        end    
        
        function setROIIcon(this,mode)
            setROIIcon(this.ModeSection,mode);
        end
        
    end
    
    methods (Access = private)
        % Layout
        function createWidgets(this)
            this.createModeSection();
            this.createPolygonSection();
            this.createPaintBrushSection();
            this.createFloodFillSection();
            this.createLabelOpacitySection();
        end
        
        function createModeSection(this)
            this.ModeSection = vision.internal.labeler.tool.sections.ModeSection;
            this.addSectionToTab(this.ModeSection);
        end
        
        function createPolygonSection(this)
            this.PolygonSection = vision.internal.labeler.tool.sections.PolygonSection;
            this.addSectionToTab(this.PolygonSection);
        end
        
        function createPaintBrushSection(this)
            this.PaintBrushSection = vision.internal.labeler.tool.sections.PaintBrushSection;
            this.addSectionToTab(this.PaintBrushSection);
        end
        
        function createFloodFillSection(this)
            this.FloodFillSection = vision.internal.labeler.tool.sections.FloodFillSection;
            this.addSectionToTab(this.FloodFillSection);
        end
        
        function createLabelOpacitySection(this)
            this.LabelOpacitySection = vision.internal.labeler.tool.sections.LabelOpacitySection;
            this.addSectionToTab(this.LabelOpacitySection);
        end
        
        function doPolygon(this)
            if this.PolygonSection.PolygonButton.Value
                this.PolygonSection.SmartPolygonButton.Value = false;
                this.PaintBrushSection.PaintBrushButton.Value = false;
                this.PaintBrushSection.EraseButton.Value = false;
                this.FloodFillSection.FloodFillButton.Value = false;
                setPixelLabelMode(getParent(this),'polygon');
            elseif ~this.isDrawStateValid()
                % Enforce that a drawing mode must be pressed at all times
                this.PolygonSection.PolygonButton.Value = true;
            end
        end
        
        function doSmartPolygon(this)
            if this.PolygonSection.SmartPolygonButton.Value
                this.PolygonSection.PolygonButton.Value = false;
                this.PaintBrushSection.PaintBrushButton.Value = false;
                this.PaintBrushSection.EraseButton.Value = false;
                this.FloodFillSection.FloodFillButton.Value = false;
                setPixelLabelMode(getParent(this),'smartpolygon');
            elseif ~this.isDrawStateValid()
                % Enforce that a drawing mode must be pressed at all times
                this.PolygonSection.SmartPolygonButton.Value = true;
            end
        end
        
        function doFloodFill(this)
            if this.FloodFillSection.FloodFillButton.Value
                this.PolygonSection.SmartPolygonButton.Value = false;
                this.PaintBrushSection.PaintBrushButton.Value = false;
                this.PaintBrushSection.EraseButton.Value = false;
                this.PolygonSection.PolygonButton.Value = false;
                setPixelLabelMode(getParent(this),'floodfill');
            elseif ~this.isDrawStateValid()
                % Enforce that a drawing mode must be pressed at all times
                this.FloodFillSection.FloodFillButton.Value = true;
            end
        end
        
        function doPaintBrush(this)
            if this.PaintBrushSection.PaintBrushButton.Value
                this.PolygonSection.SmartPolygonButton.Value = false;
                this.PolygonSection.PolygonButton.Value = false;
                this.PaintBrushSection.EraseButton.Value = false;
                this.FloodFillSection.FloodFillButton.Value = false;
                setPixelLabelMode(getParent(this),'draw');
            elseif ~this.isDrawStateValid()
                % Enforce that a drawing mode must be pressed at all times
                this.PaintBrushSection.PaintBrushButton.Value = true;
            end
        end
        
        function doErase(this)
            if this.PaintBrushSection.EraseButton.Value
                this.PolygonSection.SmartPolygonButton.Value = false;
                this.PolygonSection.PolygonButton.Value = false;
                this.PaintBrushSection.PaintBrushButton.Value = false;
                this.FloodFillSection.FloodFillButton.Value = false;
                setPixelLabelMode(getParent(this),'erase');
            elseif ~this.isDrawStateValid()
                % Enforce that a drawing mode must be pressed at all times
                this.PaintBrushSection.EraseButton.Value = true;
            end
        end
        
        function setMarkerSize(this)
            sz = this.PaintBrushSection.MarkerSlider.Value;
            setPixelLabelMarkerSize(getParent(this), sz);
        end
        
        function setAlpha(this)
            alpha = this.LabelOpacitySection.OpacitySlider.Value;
            setPixelLabelAlpha(getParent(this), alpha);
        end
        
        function TF = isDrawStateValid(this)
            % One button should be pressed at all times
            TF = any([this.PolygonSection.PolygonButton.Value,...
                this.PaintBrushSection.PaintBrushButton.Value,...
                this.PaintBrushSection.EraseButton.Value,...
                this.PolygonSection.SmartPolygonButton.Value,...
                this.FloodFillSection.FloodFillButton.Value]);
        end
        
        % Listeners
        function installListeners(this)
            this.installListenersModeSection();
            this.installListenersPolygonSection();
            this.installListenersPaintBrushSection();
            this.installListenersFloodFillSection();
            this.installListenersLabelOpacitySection();
        end
        
        function installListenersModeSection(this)
            this.ModeSection.ROIButton.ValueChangedFcn      = @(es,ed) roiMode(this);
            this.ModeSection.ZoomInButton.ValueChangedFcn   = @(es,ed) zoomInMode(this);
            this.ModeSection.ZoomOutButton.ValueChangedFcn  = @(es,ed) zoomOutMode(this);
            this.ModeSection.PanButton.ValueChangedFcn      = @(es,ed) panMode(this);
        end
        
        function installListenersPolygonSection(this)
            addlistener(this.PolygonSection.PolygonButton,'ValueChanged',@(~,~) this.doPolygon());
            addlistener(this.PolygonSection.SmartPolygonButton,'ValueChanged',@(~,~) this.doSmartPolygon());
        end
        
        function installListenersPaintBrushSection(this)
            addlistener(this.PaintBrushSection.PaintBrushButton,'ValueChanged',@(~,~) this.doPaintBrush());
            addlistener(this.PaintBrushSection.EraseButton,'ValueChanged',@(~,~) this.doErase());
            addlistener(this.PaintBrushSection.MarkerSlider,'ValueChanged',@(~,~) this.setMarkerSize());
        end  
        
        function installListenersFloodFillSection(this)
            addlistener(this.FloodFillSection.FloodFillButton,'ValueChanged',@(~,~) this.doFloodFill());
        end
        
        function installListenersLabelOpacitySection(this)
            addlistener(this.LabelOpacitySection.OpacitySlider,'ValueChanged',@(~,~) this.setAlpha());
        end
        
        function roiMode(this)
            if this.ModeSection.ROIButton.Value
                setMode(getParent(this), 'ROI');
            end
        end
        
        function zoomInMode(this)
            if this.ModeSection.ZoomInButton.Value
                setMode(getParent(this), 'ZoomIn');
            end
        end
        
        function zoomOutMode(this)
            if this.ModeSection.ZoomOutButton.Value
                setMode(getParent(this), 'ZoomOut');
            end
        end
        
        function panMode(this)
            if this.ModeSection.PanButton.Value
                setMode(getParent(this), 'Pan');
            end
        end           
    end    
end

