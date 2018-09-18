% This class is for internal use only and may change in the future.

% This class defines the OCRTrainer training panel which houses the buttons
% to initiate ocr training.

% Copyright 2015 The MathWorks, Inc.

classdef EditPanel < vision.internal.uitools.ToolStripPanel
    
    properties
        AddButton       
        MergeButton
    end
    
    %----------------------------------------------------------------------
    methods
        function this = EditPanel()
            this.createPanel();
            this.layoutPanel();
        end
        
        %------------------------------------------------------------------        
        function createPanel(this)
                        
            % create panel with 1 columns and 1 rows.     
            col = 'f:p, 2dlu, f:p'; 
            row = 'f:p';
            this.Panel = toolpack.component.TSPanel(col,row);                            
            
        end
        
        %------------------------------------------------------------------
        function layoutPanel(this)
                                   
            this.addAddButton();
            this.addMergeButton();
                                  
            add(this.Panel, this.AddButton,   'xy(1,1)');
            add(this.Panel, this.MergeButton, 'xy(3,1)');                                  
        end                                
        
    end
    
    %----------------------------------------------------------------------
    % Add button methods
    %----------------------------------------------------------------------
    methods
        
        %------------------------------------------------------------------
        function addAddButton(this)            
            
            icon = toolpack.component.Icon(...
                fullfile(matlabroot,'toolbox','vision','vision',...
                '+vision','+internal','+cascadeTrainer','+tool','ROI_24.png'));
                        
            name = 'vision:ocrTrainer:AddButton';
            
            this.AddButton = this.createToggleButton(icon,...
                name, 'btnAddBox', 'vertical');
            
            this.setToolTipText(this.AddButton, ...
                'vision:ocrTrainer:AddButtonToolTip');
        end
                 
        %------------------------------------------------------------------
        function addAddButtonCallback(this, callback)
            addlistener(this.AddButton,'ItemStateChanged',...
                callback);
        end
        
        %------------------------------------------------------------------
        function disableAddButton(this)
            this.AddButton.Enabled = false;
        end
                
        %------------------------------------------------------------------
        function enableAddButton(this)
            this.AddButton.Enabled = true;
        end
    end
    
    %----------------------------------------------------------------------
    % Merge button methods
    %----------------------------------------------------------------------
    methods
       %------------------------------------------------------------------
        function addMergeButton(this)            
            
            icon = toolpack.component.Icon(...
                fullfile(matlabroot,'toolbox','vision','vision',...
                '+vision','+internal','+ocr','+tool','merge_24.png'));
                        
            name = 'vision:ocrTrainer:MergeButton';
            
            this.MergeButton = this.createButton(icon,...
                name, 'btnMerge', 'vertical');
            
            this.setToolTipText(this.MergeButton, ...
                'vision:ocrTrainer:MergeButtonToolTip');
        end
                 
        %------------------------------------------------------------------
        function addMergeButtonCallback(this, callback)
            addlistener(this.MergeButton,'ActionPerformed',...
                callback);
        end
        
        %------------------------------------------------------------------
        function disableMergeButton(this)
            this.MergeButton.Enabled = false;
        end
                
        %------------------------------------------------------------------
        function enableMergeButton(this)
            this.MergeButton.Enabled = true;
        end
    end
end

