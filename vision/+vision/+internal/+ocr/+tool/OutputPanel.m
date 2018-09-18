% This class is for internal use only and may change in the future.

% This class defines the OCRTrainer output panel.

% Copyright 2015 The MathWorks, Inc.

classdef OutputPanel < vision.internal.uitools.ToolStripPanel
    
    properties        
        LanguageEditBox
        LanguageLabel
        OutputDirectoryEditBox
        OutputDirectoryLabel
        OutputDirectoryButton
    end
    
    %----------------------------------------------------------------------
    methods
        function this = OutputPanel()
            this.createPanel();
            this.layoutPanel();  
        end
        
        %------------------------------------------------------------------        
        function createPanel(this)
                        
            % create panel with 5 columns and 3 rows.     
            col = 'f:p,2dlu,f:p,1dlu,f:p'; 
            row = 'f:p,2dlu,f:p';
            this.Panel = toolpack.component.TSPanel(col,row);                            
            
        end
        
        %------------------------------------------------------------------
        function layoutPanel(this)
                       
            this.addLangaugeLabel()
            this.addLanguageEditBox();
            
            this.addOutputDirectoryLabel();
            this.addOutputDirectoryEditBox();
            this.addOutputDirectoryButton();
                                    
            add(this.Panel, this.LanguageLabel, 'rchw(1,1,1,1)');            
            add(this.Panel, this.LanguageEditBox,'rchw(1,3,1,1)');  
            
            add(this.Panel, this.OutputDirectoryLabel, 'rchw(3,1,1,1)');
            add(this.Panel, this.OutputDirectoryEditBox,'rchw(3,3,1,1)');   
            add(this.Panel, this.OutputDirectoryButton, 'rchw(3,5,1,1)');            
        end            
        
        %------------------------------------------------------------------
        function addLanguageEditBox(this)            
            this.LanguageEditBox = toolpack.component.TSTextField('myLanguage', 8);  
            this.setToolTipText(this.LanguageEditBox, ...
                'vision:ocrTrainer:LanguageToolTip');
        end
        
        %------------------------------------------------------------------
        function addLangaugeLabel(this)
            this.LanguageLabel = toolpack.component.TSLabel('Language:');
        end
        
        %------------------------------------------------------------------
        function addOutputDirectoryEditBox(this)
            this.OutputDirectoryEditBox = toolpack.component.TSTextField('', 8);                         
        end
        
        %------------------------------------------------------------------
        function addOutputDirectoryLabel(this)
            this.OutputDirectoryLabel = toolpack.component.TSLabel('Output Folder:');            
        end
        
        %------------------------------------------------------------------
        function addOutputDirectoryButton(this)
            icon =  toolpack.component.Icon.OPEN;
            name = '';
            
            this.OutputDirectoryButton = toolpack.component.TSButton(name, icon);
            this.OutputDirectoryButton.Name = 'btnOutputDirectory';
            
            this.setToolTipText(this.OutputDirectoryButton, ...
                'vision:ocrTrainer:OutputDirectoryButtonToolTip');
        
        end
        
        %------------------------------------------------------------------
        function addChooseOutputDirectoryCallback(this, callback)
             addlistener(this.OutputDirectoryButton, 'ActionPerformed',...
                callback);
        end
        
        %------------------------------------------------------------------
        function addOutputDirectoryCallback(this, callback)
            
            addlistener(this.OutputDirectoryEditBox,'TextEdited',...
                callback);
            
            addlistener(this.OutputDirectoryEditBox,'FocusLost',...
                callback);
        end
        
        %------------------------------------------------------------------
        function addModifyLanguageCallback(this, callback)
            addlistener(this.LanguageEditBox,'TextEdited',...
                callback);
            
            addlistener(this.LanguageEditBox,'FocusLost',...
                callback);
        end
    end
end

