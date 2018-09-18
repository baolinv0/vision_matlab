% A dialog for providing a box label.

classdef BoxLabelDialog < vision.internal.uitools.AbstractDlg
    properties
        OkButton;
        CancelButton;
        IsCanceled = true;
        Label;
        EditBox;
        EditBoxFont;
    end
    
    properties(Access=private)
        ButtonSize = [80, 20];
        ButtonHalfSpace = 10;
    end
    
    methods
        function this = BoxLabelDialog(groupName, font)
            this = this@vision.internal.uitools.AbstractDlg(...
                groupName, ...
                vision.getMessage('vision:ocrTrainer:BoxEditLabelDialogTitle'));
            this.DlgSize = [300 172];
            this.EditBoxFont = font;
            createDialog(this);
            
            % give focus to the edit box by default.
            uicontrol(this.EditBox);
        end
        
        %------------------------------------------------------------------
        function createDialog(this)
            createDialog@vision.internal.uitools.AbstractDlg(this);
            addOK(this);
            addLabelAsUnknown(this);            
            addEditBox(this);
        end
    end
       
    methods(Access=protected)                    
        
        %------------------------------------------------------------------
        function addEditBox(this)
            
            uicontrol('Parent', this.Dlg, 'Style', 'text',...
                'Position', [18 107 256 37],...
                'String', vision.getMessage('vision:ocrTrainer:BoxEditLabelMessage'),...
                'HorizontalAlignment', 'left');
            
            uicontrol('Parent', this.Dlg, 'Style', 'text',...
                'Position', [26 69 52 13],...
                'String', vision.getMessage('vision:ocrTrainer:BoxEditLabelPrompt'),...
                'HorizontalAlignment', 'left');
            
            this.EditBox = uicontrol('Parent', this.Dlg, 'Style', 'edit',...
                'Position', [86 63 117 23],...
                'FontName', this.EditBoxFont,...
                'Callback', @(varargin)onOK(this));
            
        end
        %------------------------------------------------------------------
        function addOK(this)
            x = this.DlgSize(1) / 2 - this.ButtonSize(1) - this.ButtonHalfSpace;
            this.OkButton = uicontrol('Parent', this.Dlg, 'Callback', @this.onOK,...
                'Position', [x, 10, this.ButtonSize], ...
                'FontUnits', 'normalized', 'FontSize', 0.6,'String',...
                getString(message('MATLAB:uistring:popupdialogs:OK')));
        end
        
        %------------------------------------------------------------------
        function addLabelAsUnknown(this)
            x = this.DlgSize(1) / 2 + this.ButtonHalfSpace;
            this.CancelButton = uicontrol('Parent', this.Dlg, ...
                'Callback', @this.onCancel,...
                'Position',[x, 10, this.ButtonSize], ...
                'FontUnits', 'normalized', 'FontSize', 0.6, ...
                'String', vision.getMessage('vision:ocrTrainer:UnknownString'));
        end
        
        %------------------------------------------------------------------
        function onOK(this, ~, ~)
            
            isValid = validateLabel(this.EditBox.String);
            
            if isValid
                this.IsCanceled = false;
                this.Label = deblank(this.EditBox.String);
                close(this);
            end
            
            %----------------------------------
            function isValid = validateLabel(str)
                % Label must be a single char
                
                str = deblank(str);
                
                % check length of string if ascii. unicode strings can have
                % more than one char.
                isAscii = ~isempty(str) && str(1) <= 127;
                
                if isempty(str) || (numel(str) ~= 1 && isAscii) || any(isspace(str))
                    msg   = vision.getMessage('vision:ocrTrainer:BoxLabelError');
                    title = vision.getMessage('vision:ocrTrainer:BoxLabelErrorTitle');
                    errordlg(msg,title,'modal');
                    isValid = false;
                else
                    isValid = true;
                end
            end
        end
        
        %------------------------------------------------------------------
        function onCancel(this, ~, ~)  
            this.IsCanceled = true;
            close(this);
        end
        
        %------------------------------------------------------------------
        function onKeyPress(this, ~, evd)
            switch(evd.Key)
                case {'return','space'}
                    onOK(this);
                case {'escape'}
                    onCancel(this);
            end
        end
        
    end
end
