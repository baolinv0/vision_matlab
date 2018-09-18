% This class is for internal use only and may change in the future.

classdef TrainingTab < vision.internal.uitools.AbstractTab
    properties
        FilePanel      
        SettingsPanel
        TrainingPanel        
        BoxEditPanel
        ExportPanel
    end
    
    %----------------------------------------------------------------------
    
    
    %----------------------------------------------------------------------
    methods
        
        function this = TrainingTab(tool)
            
            this = this@vision.internal.uitools.AbstractTab(tool, ...
                'TrainingTab', ...
                vision.getMessage('vision:ocrTrainer:TrainingTab'));
            this.createWidgets();
            this.installListeners();            
        end
        
        % ------------------------------------------------------------------
        function testers = getTesters(~)
            testers = [];
        end
        
        %------------------------------------------------------------------
        function disableTrainingButton(this)
            this.TrainingPanel.TrainButton.Enabled = false;            
        end
        
        %------------------------------------------------------------------
        function enableTrainingButton(this)
            this.TrainingPanel.TrainButton.Enabled = true;            
        end
        
        %------------------------------------------------------------------
        function disableAddImagesButton(this)
            this.FilePanel.disableAddImagesButton();        
        end
        
        %------------------------------------------------------------------
        function enableAddImagesButton(this)
            this.FilePanel.enableAddImagesButton(); 
        end       
        
        %------------------------------------------------------------------
        function disableSaveButton(this)
            this.FilePanel.disableSaveButton();        
        end
        
        %------------------------------------------------------------------
        function enableSaveButton(this)
            this.FilePanel.enableSaveButton(); 
        end    
                 
        %------------------------------------------------------------------
        function disableEditBoxButton(this)
            this.BoxEditPanel.disableEditButton();        
        end
        
        %------------------------------------------------------------------
        function enableEditBoxButton(this)
            this.BoxEditPanel.enableEditButton(); 
        end    
        
        %------------------------------------------------------------------
        function disableEvaluateButton(this)
            this.ExportPanel.EvaluateButton.Enabled = false;
        end
        
        %------------------------------------------------------------------
        function enableEvaluateButton(this)
            this.ExportPanel.EvaluateButton.Enabled = true; 
        end 
        
         %------------------------------------------------------------------
        function disableSettingsButton(this)
            this.SettingsPanel.disableButton();
        end
        
        %------------------------------------------------------------------
        function enableSettingsButton(this)
            this.SettingsPanel.enableButton();
        end 
        
        %------------------------------------------------------------------
        function setTrainingButtonToolTip(this, id)
            this.setToolTipText(this.TrainingPanel.TrainButton, id);                
        end
    end
    
    %----------------------------------------------------------------------
    methods(Access = private)
        
        function createWidgets(this)
            
            % Tool-strip sections
            %%%%%%%%%%%%%%%%%%%%%
            fileSection = this.createSection(...
                'vision:uitools:FileSection', 'secFile');
            
            settingsSection = this.createSection(...
                'vision:ocrTrainer:SettingsSection', 'secSettings');
                       
            boxEditSection = this.createSection(...
                'vision:ocrTrainer:BoxEditSection', 'secBoxEdit');
            
            trainingSection = this.createSection(...
                'vision:ocrTrainer:TrainingSection', 'secTrain');
            
            exportSection = this.createSection(...
                'vision:ocrTrainer:ExportSection', 'secEval');
            
            % Creating Components for each section
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            
            this.createFilePanel();   
            this.createSettingsPanel();
            this.createBoxEditPanel();
            this.createTrainingPanel();   
            this.createExportPanel();
                        
            % Tool-strip layout
            %%%%%%%%%%%%%%%%%%%                
            this.addFileSection(fileSection);  
            this.addSettingsSection(settingsSection);
            this.addBoxEditSection(boxEditSection);
            this.addTrainingSection(trainingSection);           
            this.addExportSection(exportSection);
            
            % Place sections
            %%%%%%%%%%%%%%%%
            tab = this.getToolTab();
            add(tab,fileSection);   
            add(tab,settingsSection);
            add(tab,boxEditSection);
            add(tab,trainingSection); 
            add(tab,exportSection);
            
        end
        
        %------------------------------------------------------------------
        % Install listeners for each panel added to this tab.
        %------------------------------------------------------------------
        function installListeners(this)
            this.installListenersFileSection();    
            this.installListenersSettingsSection();
            this.installListenersBoxEditSection();
            this.installListenersTrainingSection();  
            this.installListenersExportSection();
        end               
    end
    
    %----------------------------------------------------------------------
    % Methods to create and configure panels added to this tab.
    %----------------------------------------------------------------------
    methods
        
        function createFilePanel(this)
            this.FilePanel = vision.internal.ocr.tool.TrainerFilePanel();            
        end 
        
        function createSettingsPanel(this)
            this.SettingsPanel = vision.internal.ocr.tool.SettingsPanel();            
        end
        
        %------------------------------------------------------------------
        function createBoxEditPanel(this)
            this.BoxEditPanel = vision.internal.ocr.tool.BoxEditPanel();
        end
        
        %------------------------------------------------------------------
        function createTrainingPanel(this)
            this.TrainingPanel = vision.internal.ocr.tool.TrainingPanel();
        end
               
        %------------------------------------------------------------------
        function createExportPanel(this)
            this.ExportPanel = vision.internal.ocr.tool.ExportPanel();
        end
    end
    
    %----------------------------------------------------------------------
    % Methods for adding sections to this tab.
    %----------------------------------------------------------------------
    methods
       
        %------------------------------------------------------------------
        function addFileSection(this, section)
            add(section, this.FilePanel.Panel);
        end
               
        %------------------------------------------------------------------
        function addSettingsSection(this, section)
            add(section, this.SettingsPanel.Panel);
        end
        
        %------------------------------------------------------------------
        function addBoxEditSection(this, section)
            add(section, this.BoxEditPanel.Panel);
        end
        
        %------------------------------------------------------------------
        function addTrainingSection(this, section)
            add(section, this.TrainingPanel.Panel);
        end
      
        %------------------------------------------------------------------
        function addExportSection(this, section)
            add(section, this.ExportPanel.Panel);
        end
    end
    
    %----------------------------------------------------------------------
    % File Panel listeners
    %----------------------------------------------------------------------
    methods       
        
        %------------------------------------------------------------------
        function installListenersFileSection(this)
            this.FilePanel.addNewSessionCallback(...
                @(es,ed)newSession(getParent(this)));
            
            this.FilePanel.addOpenSessionCallbacks(...
                @(es,ed)openSession(getParent(this)), @this.doOpen);
            
            this.FilePanel.addSaveSessionCallbacks(...
                @(es,ed)saveSession(getParent(this)), @this.doSave);
            
            this.FilePanel.addAddImagesCallback(...
                @(es,ed)addImages(getParent(this)));
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
        % Handle the open button options
        %------------------------------------------------------------------
        function doOpen(this, src, ~)
            
            % from save options popup
            if src.SelectedIndex == 1         % open
                openSession(getParent(this));
            elseif src.SelectedIndex == 2     % add to current
                addToCurrentSession(getParent(this));
            end
        end
    end    
    
    %----------------------------------------------------------------------
    % Settings listeners
    %----------------------------------------------------------------------
    methods
        function installListenersSettingsSection(this)
            this.SettingsPanel.addButtonCallback(...
                @(es,ed)doSettings(getParent(this)));
        end            
    end
    
    %----------------------------------------------------------------------
    % Training section listeners
    %----------------------------------------------------------------------
    methods
        
        function installListenersTrainingSection(this)
            this.TrainingPanel.addTrainButtonCallback(...
                @(es,ed)doTraining(getParent(this)));
        end
    end
        
    %----------------------------------------------------------------------
    % Box editing section listeners
    %----------------------------------------------------------------------
    methods
        
        function installListenersBoxEditSection(this)
            this.BoxEditPanel.addEditButtonCallback(...
                @(es,ed)doBoxEdit(getParent(this)));
        end
    end
    
    %----------------------------------------------------------------------
    % Export section listeners
    %----------------------------------------------------------------------
    methods
        
        function installListenersExportSection(this)
            this.ExportPanel.addExportButtonCallback(...
                @(es,ed)doEvaluateGenFunction(getParent(this)));
        end
    end
end