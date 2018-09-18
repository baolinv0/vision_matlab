% This class is for internal use only and may change in the future.

classdef BoxEditTab < vision.internal.uitools.AbstractTab
    properties
        EditPanel
        ZoomPanel
        ClosePanel
    end
    
    %----------------------------------------------------------------------    
    
    %----------------------------------------------------------------------
    methods
        
        function this = BoxEditTab(tool)
            this = this@vision.internal.uitools.AbstractTab(tool, ...
                'BoxEditTab', ...
                vision.getMessage('vision:ocrTrainer:BoxEditTab'));
            this.createWidgets();
            this.installListeners();            
        end
        
        % -----------------------------------------------------------------
        function testers = getTesters(~)
            testers = [];
        end       
        
        % -----------------------------------------------------------------
        function disableMergeButton(this)
            this.EditPanel.MergeButton.Enabled = false;
        end
        
        % -----------------------------------------------------------------
        function enableMergeButton(this)
            this.EditPanel.MergeButton.Enabled = true;
        end
        
        % -----------------------------------------------------------------
        function selectAddButton(this)
            this.EditPanel.AddButton.Selected = true;
        end
        
        % -----------------------------------------------------------------
        function unselectAddButton(this)
            this.EditPanel.AddButton.Selected = false;
        end
        
        %------------------------------------------------------------------
        function tf = isROIMode(this)
            tf = this.EditPanel.AddButton.Selected;
        end
    end
    
    %----------------------------------------------------------------------
    methods(Access = private)
        
        function createWidgets(this)
            
            % Tool-strip sections
            %%%%%%%%%%%%%%%%%%%%%
            boxEditSection = this.createSection(...
                'vision:ocrTrainer:ModifySection', 'secModifyBoxes');
            
            zoomSection = this.createSection(...
                'vision:uitools:ZoomSection', 'secZoom');

            closeSection = this.createSection(...
                'vision:ocrTrainer:CloseBoxEditSection', 'secCloseBoxes');
                        
            % Creating Components for each section
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                        
            this.createBoxEditPanel();      
            this.createZoomPanel();
            this.createClosePanel();
                        
            % Tool-strip layout
            %%%%%%%%%%%%%%%%%%%                            
            this.addBoxEditSection(boxEditSection); 
            this.addZoomSection(zoomSection);
            this.addCloseSection(closeSection);
            
            % Place sections
            %%%%%%%%%%%%%%%%
            tab = this.getToolTab();
            add(tab,boxEditSection);  
            add(tab,zoomSection);
            add(tab,closeSection);
        end
        
        %------------------------------------------------------------------
        % Install listeners for each panel added to this tab.
        %------------------------------------------------------------------
        function installListeners(this)            
            this.installListenersBoxEditSection();  
            this.installListenersZoomSection();
            this.installListenersCloseSection();
        end               
    end
    
    %----------------------------------------------------------------------
    % Methods to create and configure panels added to this tab.
    %----------------------------------------------------------------------
    methods
              
        %------------------------------------------------------------------
        function createBoxEditPanel(this)
            this.EditPanel = vision.internal.ocr.tool.EditPanel();
        end
                        
        %------------------------------------------------------------------
        function createZoomPanel(this)
            this.ZoomPanel = vision.internal.calibration.tool.ZoomPanel();
        end
        
        %------------------------------------------------------------------
        function createClosePanel(this)
            this.ClosePanel = vision.internal.ocr.tool.ClosePanel(...
                'vision:ocrTrainer:ApplyButton',...
                'btnAcceptBoxEdit', ...
                'vision:ocrTrainer:CancelButton',...
                'btnCancelBoxEdit');
            
            % set tool tips
            this.ClosePanel.setApplyButtonToolTip(...
                'vision:ocrTrainer:BoxEditApplyButtonToolTip');
            
            this.ClosePanel.setCancelButtonToolTip(...
                'vision:ocrTrainer:BoxEditCancelButtonToolTip');
        end
    end
    
    %----------------------------------------------------------------------
    % Methods for adding sections to this tab.
    %----------------------------------------------------------------------
    methods
              
        %------------------------------------------------------------------
        function addBoxEditSection(this, section)
            add(section, this.EditPanel.Panel);
        end  
        
        %------------------------------------------------------------------
        function addZoomSection(this, section)
            add(section, this.ZoomPanel.Panel);
        end          
        
        %------------------------------------------------------------------
        function addCloseSection(this, section)
            add(section, this.ClosePanel.Panel);
        end         
      
    end
  
    %----------------------------------------------------------------------
    % Box editing section listeners
    %----------------------------------------------------------------------
    methods
        
        %------------------------------------------------------------------
        function installListenersBoxEditSection(this)
            this.EditPanel.addAddButtonCallback(...
                @(es,ed)doBoxEditAdd(getParent(this)));
            
            this.EditPanel.addMergeButtonCallback(...
                @(es,ed)doBoxEditMerge(getParent(this)));
            
        end
        
        %------------------------------------------------------------------
        function installListenersZoomSection(this)
            this.ZoomPanel.addListeners(...
                @(es,ed)doBoxEditZoom(getParent(this),es,ed));
        end
        
        %------------------------------------------------------------------
        function installListenersCloseSection(this)
            
            this.ClosePanel.addApplyButtonCallback(...
                @(es,ed)doBoxEditAccept(getParent(this)));
            
            this.ClosePanel.addCancelButtonCallback(...
                @(es,ed)doBoxEditClose(getParent(this)));
        end
    end
    
end
