% CalibrationTab Defines key UI elements of the Camera Calibrator App
%
%    This class defines all key UI elements and sets up callbacks that
%    point to methods inside the CameraCalibrationTool class.

% Copyright 2012-2014 The MathWorks, Inc.

classdef CalibrationTab < vision.internal.uitools.AbstractTab    
    properties
        FilePanel;
        OptionsPanel;
        OptimizationOptionsPanel;
        ZoomPanel;
        CalibratePanel;
        LayoutPanel;
        ExportPanel;
        
        OptimizationOptions;
    end
    
    properties(Dependent)
        CameraModel;        
    end
    
    %----------------------------------------------------------------------
    % Public methods
    %----------------------------------------------------------------------
    methods
        %------------------------------------------------------------------
        % Gets the camera model options
        %------------------------------------------------------------------
        function cameraModel = get.CameraModel(this)
            cameraModel = this.OptionsPanel.CameraModel;
        end        
    end
    
    methods (Access=public)
        %------------------------------------------------------------------
        % Constructor
        %------------------------------------------------------------------
        function this = CalibrationTab(tool, isStereo)
            this = this@vision.internal.uitools.AbstractTab(tool, ...
                'CalibrationTab', ...
                vision.getMessage('vision:caltool:CalibrationTab'));
            this.createWidgets(isStereo);
            this.addFileSectionCallbacks(isStereo);
        end
        
        % -----------------------------------------------------------------
        function testers = getTesters(~)
            testers = [];
        end
        
        %------------------------------------------------------------------
        % This routine handles graying out of buttons
        %------------------------------------------------------------------
        function updateButtonStates(this, session)
            updateCalibrateButtonState(this, session);
            updateExportButtonState(this, session);            
        end
        
        %------------------------------------------------------------------
        % This routine handles enabling/disabling everything in calibration tab.
        %------------------------------------------------------------------
        function updateTabStatus(this, state)
            this.ExportPanel.IsButtonEnabled = state;
            this.FilePanel.setAllButtonsEnabled(state);            
            this.CalibratePanel.IsButtonEnabled = state;
            this.LayoutPanel.IsButtonEnabled = state;
            this.OptionsPanel.setAllButtonsEnabled(state);      
        end
        
        %------------------------------------------------------------------
        % Sets the camera model options
        %------------------------------------------------------------------
        function setCameraModelOptions(this, numRadialCoeffs, ...
                computeSkew, computeTangentialDist)

            cameraModel.NumDistortionCoefficients = numRadialCoeffs;
            cameraModel.ComputeSkew = computeSkew;
            cameraModel.ComputeTangentialDist = computeTangentialDist;
            this.OptionsPanel.CameraModel = cameraModel;
        end        

        %------------------------------------------------------------------
        function enableNumRadialCoefficients(this)
            this.OptionsPanel.enableNumRadialCoefficients();
        end
        
        %------------------------------------------------------------------
        function disableNumRadialCoefficients(this, numCoeffs)
            this.OptionsPanel.disableNumRadialCoefficients(numCoeffs);
        end
    end % end of public methods

    %----------------------------------------------------------------------
    % Private methods
    %----------------------------------------------------------------------    
    methods (Access=private)
        %------------------------------------------------------------------
        function updateCalibrateButtonState(this, session)
            this.CalibratePanel.IsButtonEnabled = ...
                session.HasEnoughBoards && ~session.CanExport;
            
            if this.CalibratePanel.IsButtonEnabled
                this.CalibratePanel.setToolTip(...
                    'vision:caltool:EnabledCalibrateToolTip');
            else
                if session.CanExport
                    this.CalibratePanel.setToolTip(...
                        'vision:caltool:DisabledCurrentCalibrationToolTip');
                else
                    this.CalibratePanel.setToolTip(...
                        'vision:caltool:DisabledCalibrateToolTip');
                end
            end
        end
        
        %------------------------------------------------------------------
        function updateExportButtonState(this, session)            
            this.ExportPanel.IsButtonEnabled = session.CanExport;
            
            if this.ExportPanel.IsButtonEnabled
                setToolTip(this.ExportPanel, ...
                    'vision:caltool:EnabledExportToolTip');
            else
                setToolTip(this.ExportPanel, ...
                    'vision:caltool:DisabledExportToolTip');
            end
        end            
        
        %------------------------------------------------------------------
        function createWidgets(this, isStereo)
            tab = this.getToolTab();
            add(tab, createFileSection(this, isStereo));            
            add(tab, createCalibrationOptionsSection(this));  
            add(tab, createOptimizationOptionsSection(this));
            add(tab, createCalibrateSection(this));
            add(tab, createZoomSection(this));
            add(tab, createLayoutSection(this));
            add(tab, createExportSection(this));
            add(tab, createResourceSection(this));           
        end      
        
        %------------------------------------------------------------------
        function fileSection = createFileSection(this, isStereo)
            if isStereo
                this.FilePanel = vision.internal.calibration.tool.CalibratorFilePanel();
            else
                this.FilePanel = ...
                    vision.internal.calibration.tool.FilePanelLiveCapture();
            end
            
            fileSection = this.createSection('vision:uitools:FileSection',...
                'secFile');
            add(fileSection, this.FilePanel.Panel);
        end
        
        %------------------------------------------------------------------
        function optionsSection = createCalibrationOptionsSection(this)
            import vision.internal.calibration.tool.*;
            fun = @(es,ed)cameraModelChanged(getParent(this));
            this.OptionsPanel = CalibrationOptionsPanel(fun);
            
            optionsSection = this.createSection(...
                'vision:caltool:OptionsSection', 'secOptions');
            add(optionsSection, this.OptionsPanel.Panel);
        end
        
        %------------------------------------------------------------------
        function section = createOptimizationOptionsSection(this)
            icon = toolpack.component.Icon.SETTINGS_24;
            nameId   = 'vision:caltool:OptimOptionsButton';
            tag = 'btnOptimOptions';
            toolTipId = 'vision:caltool:OptimOptionsToolTip';
            
            import vision.internal.calibration.tool.*;
            fun = @(es,ed)doOptimizationOptions(getParent(this));
            import vision.internal.uitools.*;
            panel = OneButtonPanel(icon, nameId, tag, toolTipId, fun);
                                    
            section = this.createSection(...
                'vision:caltool:OptimOptionsSection', 'secOptimOptions');
            add(section, panel.Panel);                        
        end
        
        %------------------------------------------------------------------
        function calibrateSection = createCalibrateSection(this)
            calibrateSection = this.createSection(...
                'vision:caltool:CalibrateSection', 'secCalibrate');

            caliIcon = toolpack.component.Icon.RUN_24;
            nameId   = 'vision:caltool:CalibrateButton';
            tag      = 'btnCalibrate';
            toolTipId = 'vision:caltool:DisabledCalibrateToolTip';
            fun      = @(es,ed)calibrate(getParent(this));
            
            import vision.internal.uitools.*;
            % Store the panel to be able to enable/disable the calibrate
            % button.
            this.CalibratePanel = OneButtonPanel(caliIcon, nameId, tag, ...
                toolTipId, fun);
            add(calibrateSection, this.CalibratePanel.Panel);
        end
        
        %------------------------------------------------------------------
        function zoomSection = createZoomSection(this)
            zoomSection = this.createSection('vision:uitools:ZoomSection', ...
                'secZoom');

            % The listeners for the ZoomPanel are controlled by the
            % CameraCalibrationTool class.
            this.ZoomPanel = vision.internal.calibration.tool.ZoomPanel;
            
            add(zoomSection, this.ZoomPanel.Panel);
        end
        
        %------------------------------------------------------------------
        function layoutSection = createLayoutSection(this)
            layoutSection = this.createSection(...
                'vision:uitools:LayoutSection', 'secLayout');

            layoutIcon = toolpack.component.Icon.LAYOUT_24;
            nameId = 'vision:uitools:LayoutButton';
            toolTipId = 'vision:caltool:LayoutToolTip';
            tag = 'btnLayout';
            fun = @(es,ed)layout(getParent(this));
            
            import vision.internal.uitools.*;
            this.LayoutPanel = OneButtonPanel(layoutIcon, nameId, tag, toolTipId, fun);
            add(layoutSection, this.LayoutPanel.Panel);
        end
            
        %------------------------------------------------------------------
        function resourcesSection = createResourceSection(this)
            resourcesSection = this.createSection(...
                'vision:uitools:ResourcesSection', 'secResources');
            helpFun = @(es,ed)help(getParent(this));
            toolTipId = 'vision:caltool:HelpToolTip';
            panel = vision.internal.uitools.HelpPanel(helpFun, toolTipId);
            add(resourcesSection, panel.Panel);
        end
        
        %------------------------------------------------------------------
        function exportSection = createExportSection(this)
            this.ExportPanel = vision.internal.uitools.OneSplitButtonPanel();
            
            exportIcon = toolpack.component.Icon.CONFIRM_24;
            nameId = 'vision:caltool:ExportButton';
            tag = 'btnExport';            
            this.ExportPanel.createTheButton(exportIcon, nameId, tag);
            
            toolTipId = 'vision:caltool:DisabledExportToolTip';
            this.ExportPanel.setToolTip(toolTipId);
            
            fun = @(es,ed)export(getParent(this));
            this.ExportPanel.addButtonCallback(fun);
            
            options = createExportOptions(this);
            this.ExportPanel.createPopup(options, 'ExportPopup', @this.doExport);
            
            exportSection = this.createSection(...
                'vision:uitools:ExportSection', 'secExport');
            add(exportSection, this.ExportPanel.Panel);
        end

        %------------------------------------------------------------------
        function options = createExportOptions(~)
            exportIcon = toolpack.component.Icon.CONFIRM_16;
            codegenIcon = toolpack.component.Icon(...
                fullfile(matlabroot,'toolbox','images','icons',...
                'GenerateMATLABScript_Icon_16px.png'));
            
            options(1) = struct(...
                'Title', getString(message('vision:caltool:ExportParametersPopup')), ...
                'Description', '', ...
                'Icon', exportIcon, 'Help', [], 'Header', false);
            
            options(2) = struct(...
                'Title', getString(message('vision:caltool:GenerateScriptPopup')), ...
                'Description', '', ...
                'Icon', codegenIcon, 'Help', [], 'Header', false);
        end

        % -----------------------------------------------------------------
        function addFileSectionCallbacks(this, isStereo)
            this.FilePanel.addNewSessionCallback(...
                @(es,ed)newSession(getParent(this)));

            this.FilePanel.addOpenSessionCallback(...
                @(es,ed)openSession(getParent(this)));            
            
            this.FilePanel.addSaveSessionCallbacks(...
                @(es,ed)saveSession(getParent(this)), @this.doSave);

            addImagesFun = @(es,ed)addImages(getParent(this));
            if isStereo
                this.FilePanel.addAddImagesCallback(addImagesFun);                    
            else
                this.FilePanel.addAddImagesCallback(addImagesFun, @this.doAddImages);
            end            
        end                
        
        %------------------------------------------------------------------
        % Handle the save button options
        %------------------------------------------------------------------
        function doSave(this, src, ~)
            
            % from save options popup
            if src.SelectedIndex == 1         % Save
                saveSession(getParent(this));
            elseif src.SelectedIndex == 2     % SaveAs
                saveSessionAs(getParent(this));
            end
        end
        
        %------------------------------------------------------------------
        % Handle the add images options
        %------------------------------------------------------------------
        function doAddImages(this, src, ~)
            
            % From add images options popup
            if src.SelectedIndex == 1         % Add images from file
                addImages(getParent(this));
            elseif src.SelectedIndex == 2     % Add images from camera
                addImagesFromCamera(getParent(this));
            end
        end      
        
        %------------------------------------------------------------------
        function doExport(this, src, ~)
            switch src.SelectedIndex
                case 1
                    export(getParent(this));
                case 2
                    generateCode(getParent(this));
            end
        end
        
    end % end of private methods
    
end % end of class definition
