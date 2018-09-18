% ocr training app settings dialog
classdef SettingsDialog < vision.internal.uitools.OkCancelDlg
    properties
        Font
        FontPopup
        FontList
    end
    
    %----------------------------------------------------------------------
    methods
        function this = SettingsDialog(groupName, font)
            dlgTitle = vision.getMessage('vision:ocrTrainer:SettingsDialogTitle');            
            this = this@vision.internal.uitools.OkCancelDlg(groupName, dlgTitle);

            this.DlgSize = [450 146];
            
            createDialog(this);
                                
            addOK(this);  
            
            this.Font = font;
            
            doLayout(this);
                                    
        end
        
        %------------------------------------------------------------------
        function list = get.FontList(~)
            list = listTrueTypeFonts;
        end
    end
    
    %----------------------------------------------------------------------
    methods(Access = protected)
        function onOK(this, ~, ~)
            selection = this.FontPopup.Value;
            this.Font = this.FontList{selection};          
            this.IsCanceled = false;
            close(this);  
        end       
    end
    
    %----------------------------------------------------------------------
    methods(Access = private)
        function doLayout(this, ~, ~)
            
            uicontrol('Parent', this.Dlg, 'Style', 'text',...
                'Units', 'pixel',...
                'Position', [15 105 400 15],...
                'HorizontalAlignment', 'left', ...
                'String', vision.getMessage('vision:ocrTrainer:SettingsDialogText'));
            
            uicontrol('Parent', this.Dlg, 'Style', 'text',...
                'Units', 'pixel',...
                'Position', [38 70 41 17],...
                'HorizontalAlignment', 'left', ...
                'String', vision.getMessage('vision:ocrTrainer:SettingsFont'));
           
            % Select the current app font by default.
            selection = find(strcmp(this.Font, this.FontList), 1);
            if isempty(selection)
                selection = 1;
            end
            
            this.FontPopup = uicontrol('Parent', this.Dlg, 'Style', 'popup',...
                'Units', 'pixels',...
                'Position', [86 70 270 22],...
                'String', this.FontList,...
                'Value', selection);
        end   
       
    end
    
end
