% This class is for internal use only and may change in the future.

% This class defines the OCRTrainer training panel which houses the buttons
% to initiate ocr training.

% Copyright 2015 The MathWorks, Inc.

classdef BoxEditPanel < vision.internal.uitools.ToolStripPanel
    
    properties
        EditButton        
    end
    
    %----------------------------------------------------------------------
    methods
        function this = BoxEditPanel()
            this.createPanel();
            this.layoutPanel();
        end
        
        %------------------------------------------------------------------        
        function createPanel(this)
                        
            % create panel with 1 columns and 1 rows.     
            col = 'f:p'; 
            row = 'f:p';
            this.Panel = toolpack.component.TSPanel(col,row);                            
            
        end
        
        %------------------------------------------------------------------
        function layoutPanel(this)
                                   
            this.addEditButton();
                                  
            add(this.Panel, this.EditButton, 'xy(1,1)');
                                  
        end                        
        
        %------------------------------------------------------------------
        function addEditButton(this)            
            
            icon = toolpack.component.Icon(...
                fullfile(matlabroot,'toolbox','vision','vision',...
                '+vision','+internal','+cascadeTrainer','+tool','ROI_24.png'));
                        
            name = 'vision:ocrTrainer:EditButton';
            
            this.EditButton = this.createButton(icon,...
                name, 'btnEditBox', 'vertical');
            
            this.setToolTipText(this.EditButton, ...
                'vision:ocrTrainer:EditButtonToolTip');
        end
            
        %------------------------------------------------------------------
        function addEditButtonCallback(this, callback)
            addlistener(this.EditButton,'ActionPerformed',...
                callback);
        end
        
        %------------------------------------------------------------------
        function disableEditButton(this)
            this.EditButton.Enabled = false;
        end
        
        
        %------------------------------------------------------------------
        function enableEditButton(this)
            this.EditButton.Enabled = true;
        end
        
    end
end

