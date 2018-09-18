classdef TrainerFilePanel < vision.internal.uitools.FilePanel
      properties(Access=protected)
        NewSessionToolTip  = 'vision:trainingtool:NewSessionToolTip';
        OpenSessionToolTip = 'vision:trainingtool:OpenSessionToolTip';
        SaveSessionToolTip = 'vision:trainingtool:SaveSessionToolTip';
        AddImagesToolTip   = 'vision:trainingtool:AddImagesToolTip';
        
        AddImagesIconFile = fullfile(toolboxdir('vision'),'vision',...
                '+vision','+internal','+cascadeTrainer','+tool','AddImage_24.png');
    end
    
    methods
        %------------------------------------------------------------------
        function this = TrainerFilePanel()
            this = this@vision.internal.uitools.FilePanel();
            addOpenSessionPopup(this)
        end
        
        %------------------------------------------------------------------
        function addOpenSessionCallbacks(this, buttonFun, popupFun)
            addOpenSessionCallback(this, buttonFun);
            this.addPopupCallback(this.OpenSessionButton, popupFun);
        end
        
        %------------------------------------------------------------------
        function disableAddImagesButton(this)
            this.AddImagesButton.Enabled = false;            
        end
        
        %------------------------------------------------------------------
        function enableAddImagesButton(this)
            this.AddImagesButton.Enabled = true;            
        end 
        
        %------------------------------------------------------------------
        function disableSaveButton(this)
            this.SaveSessionButton.Enabled = false;            
        end
        
        %------------------------------------------------------------------
        function enableSaveButton(this)
            this.SaveSessionButton.Enabled = true;            
        end
    end
    
    methods(Access=protected)
        %------------------------------------------------------------------
        function createOpenSessionButton(this, openSessionIcon, nameId)
             this.OpenSessionButton = this.createSplitButton(openSessionIcon, ...
                nameId, 'btnOpenSession', 'vertical');
        end

        %------------------------------------------------------------------
        function addOpenSessionPopup(this)
            style = 'icon_text';
            this.OpenSessionButton.Popup = toolpack.component.TSDropDownPopup(...
                this.getOpenOptions, style);
            this.OpenSessionButton.Popup.Name = 'OpenPopup';
        end
        
        %------------------------------------------------------------------
        function items = getOpenOptions(~)
            % defining the option entries appearing on the popup of the
            % Save Split Button.
            
            openIcon = com.mathworks.common.icons.CommonIcon.OPEN;
            addToCurrentIcon = toolpack.component.Icon.ADD_16;
            
            items(1) = struct(...
                'Title', getString(message('vision:trainingtool:OpenExistingSession')), ...
                'Description', '', ...
                'Icon', toolpack.component.Icon(openIcon.getIcon), ...
                'Help', [], ...
                'Header', false);
            items(2) = struct(...
                'Title', getString(message('vision:trainingtool:AddToCurrentSession')), ...
                'Description', '', ...
                'Icon', addToCurrentIcon, ...
                'Help', [], ...
                'Header', false);
        end
    end
end