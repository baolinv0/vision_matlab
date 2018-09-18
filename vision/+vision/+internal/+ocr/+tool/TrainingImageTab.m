% This class is for internal use only and may change in the future.

classdef TrainingImageTab < vision.internal.uitools.AbstractTab
    properties        
        ZoomPanel
        FilterPanel
        ClosePanel
    end
    
    %----------------------------------------------------------------------    
    
    %----------------------------------------------------------------------
    methods
        
        function this = TrainingImageTab(tool)
            this = this@vision.internal.uitools.AbstractTab(tool, ...
                'TrainingImageTab', ...
                vision.getMessage('vision:ocrTrainer:TrainingImageTab'));
            this.createWidgets();
            this.installListeners();            
        end
        
        % -----------------------------------------------------------------
        function testers = getTesters(~)
            testers = [];
        end       
        
        %------------------------------------------------------------------
        function values = getRegionFilterValues(this)
            values.MinArea = this.FilterPanel.AreaThreshold.Value;
            values.MinAspectRatio = this.FilterPanel.MinAspectRatio.Value;
            values.MaxAspectRatio = this.FilterPanel.MaxAspectRatio.Value;
        end
        
        %------------------------------------------------------------------
        function setRegionFilterValues(this, values)
            this.FilterPanel.AreaThreshold.Value  = values.MinArea;
            this.FilterPanel.MinAspectRatio.Value = values.MinAspectRatio;
            this.FilterPanel.MaxAspectRatio.Value = values.MaxAspectRatio;                       
        end
        
        %------------------------------------------------------------------
        function disableRegionFilterListener(this)
            this.FilterPanel.disableListener();
        end
        
        %------------------------------------------------------------------
        function enableRegionFilterListener(this)
             this.FilterPanel.enableListener();
        end
        
        %------------------------------------------------------------------
        function clipFilterValues(this)
            this.FilterPanel.AreaThreshold.Value  = max(0,this.FilterPanel.AreaThreshold.Value);
            this.FilterPanel.MinAspectRatio.Value = max(0,this.FilterPanel.MinAspectRatio.Value);            
            this.FilterPanel.MaxAspectRatio.Value = max(0,this.FilterPanel.MaxAspectRatio.Value);
        end
        
        %------------------------------------------------------------------
        function tf = applyRegionFiltersToAllImages(~)
            % In v1, region filters apply to all images. 
            tf = true;
        end
       
    end
    
    %----------------------------------------------------------------------
    methods(Access = private)
        
        function createWidgets(this)
            
            % Tool-strip sections
            %%%%%%%%%%%%%%%%%%%%%          
            zoomSection = this.createSection(...
                'vision:uitools:ZoomSection', 'secZoom');

            filterSection = this.createSection(...
                'vision:ocrTrainer:TextSegSection', 'secFilter');

            closeSection = this.createSection(...
                'vision:ocrTrainer:CloseBoxEditSection', 'secCloseBoxes');
                        
            % Creating Components for each section
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                                   
            this.createZoomPanel();
            this.createFilterPanel();
            this.createClosePanel();
                        
                        
            % Tool-strip layout
            %%%%%%%%%%%%%%%%%%%                            
            this.addZoomSection(zoomSection);
            this.addFilterSection(filterSection);
            this.addCloseSection(closeSection);
            
            % Place sections
            %%%%%%%%%%%%%%%%
            tab = this.getToolTab();
            add(tab,zoomSection);
            add(tab,filterSection);
            add(tab,closeSection);
        end
        
        %------------------------------------------------------------------
        % Install listeners for each panel added to this tab.
        %------------------------------------------------------------------
        function installListeners(this)                      
            this.installListenersZoomSection();
            this.installListenersCloseSection();
            this.installListenersFilterSection();
        end               
    end
    
    %----------------------------------------------------------------------
    % Methods to create and configure panels added to this tab.
    %----------------------------------------------------------------------
    methods
                                            
        %------------------------------------------------------------------
        function createZoomPanel(this)
            this.ZoomPanel = vision.internal.calibration.tool.ZoomPanel();           
        end
        %------------------------------------------------------------------
        function createFilterPanel(this)
            this.FilterPanel = vision.internal.ocr.tool.FilterPanel();
        end
        
        %------------------------------------------------------------------
        function createClosePanel(this)
            this.ClosePanel = ...
                vision.internal.ocr.tool.ClosePanel(...
                'vision:ocrTrainer:TrainingImageApplyButton', ...
                'btnApplyTrainingImage', ...
                'vision:ocrTrainer:CancelButton', ...
                'btnCancelTrainingImage');
            
            % set tool tips
            this.ClosePanel.setApplyButtonToolTip(...
                'vision:ocrTrainer:TrainingImageApplyButtonToolTip');
            
            this.ClosePanel.setCancelButtonToolTip(...
                'vision:ocrTrainer:TrainingImageCancelButtonToolTip');
        end
    end
    
    %----------------------------------------------------------------------
    % Methods for adding sections to this tab.
    %----------------------------------------------------------------------
    methods                      
        
        %------------------------------------------------------------------
        function addZoomSection(this, section)
            add(section, this.ZoomPanel.Panel);
        end          
        
        %------------------------------------------------------------------
        function addCloseSection(this, section)
            add(section, this.ClosePanel.Panel);
        end   
      
        %------------------------------------------------------------------
        function addFilterSection(this, section)
            add(section, this.FilterPanel.Panel);
    end
  
    end
  
    %----------------------------------------------------------------------
    % Box editing section listeners
    %----------------------------------------------------------------------
    methods      
        
        %------------------------------------------------------------------
        function installListenersZoomSection(this)
            this.ZoomPanel.addListeners(...
                @(es,ed)doTrainingImageZoom(getParent(this),es,ed));
        end
        
        %------------------------------------------------------------------
        function installListenersCloseSection(this)
            
            this.ClosePanel.addApplyButtonCallback(...
                @(es,ed)doTrainingImageAccept(getParent(this)));
            
            this.ClosePanel.addCancelButtonCallback(...
                @(es,ed)doTrainingImageClose(getParent(this)));
        end
        
        %------------------------------------------------------------------
        function installListenersFilterSection(this)            
            this.FilterPanel.addListener(...
                @(es,ed)doTrainingImageRegionFilter(getParent(this)));
        end
    end
    
end
